import SwiftUI
import AppKit
import AVFoundation
import UniformTypeIdentifiers

@MainActor
final class MeetingStore: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var meetings: [Meeting] = []
    @Published var selection: String?
    @Published var error: String?
    @Published var busy = false
    @Published var jobMessage = ""
    @Published var jobProgress = 0.0
    @Published var jobMeetingID: String?
    @Published var recording = false
    @Published var recordSeconds = 0.0
    @Published var level: Float = 0
    @Published var isPlaying = false
    @Published var playbackTime = 0.0
    @Published var playingMeetingID: String?
    @Published var codexReady = false
    @Published var claudeReady = false
    @Published var claudeAuthLabel = "연결 필요"
    @Published var checkingConnections = false
    @Published var aiProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "codex" {
        didSet { UserDefaults.standard.set(aiProvider, forKey: "aiProvider") }
    }
    var providerName: String { aiProvider == "claude" ? "Claude" : "Codex" }
    var aiReady: Bool { aiProvider == "claude" ? claudeReady : codexReady }
    @Published var autoSummarize = UserDefaults.standard.object(forKey: "autoSummarize") as? Bool ?? true {
        didSet { UserDefaults.standard.set(autoSummarize, forKey: "autoSummarize") }
    }
    @Published var language = "ko"
    @Published var speakerCount = -1
    let isDemo = ProcessInfo.processInfo.arguments.contains("--demo")
    let root = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(
        ProcessInfo.processInfo.arguments.contains("--demo") ? "Library/Application Support/MoaMeetingDemo" : "Library/Application Support/MoaMeeting")
    private var recorder: AVAudioRecorder?
    private var recorderID: String?
    private var player: AVAudioPlayer?
    private var clock: Timer?
    private var jobTimer: Timer?
    private var jobProcess: Process?
    private var jobCancelled = false
    private var recordingTimer: Timer?
    private var jobFolder: URL?
    var modelsReady: Bool {
        ["ggml-large-v3-turbo-q5_0.bin", "segmentation.onnx", "embedding.onnx"].allSatisfy { FileManager.default.fileExists(atPath: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/MoaMeeting/models/\($0)").path) }
    }
    override init() {
        super.init()
        try? FileManager.default.createDirectory(at: root.appendingPathComponent("meetings"), withIntermediateDirectories: true)
        loadMeetings()
        clock = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.playbackTime = self.player?.currentTime ?? 0
                self.isPlaying = self.player?.isPlaying ?? false
            }
        }
        checkConnections()
    }
    func folder(_ id: String) -> URL { root.appendingPathComponent("meetings/\(id)") }
    func audio(_ meeting: Meeting) -> URL { folder(meeting.id).appendingPathComponent(meeting.audioFile) }
    func meeting(_ id: String) -> Meeting? { meetings.first { $0.id == id } }
    func loadMeetings() {
        do {
            let dirs = try FileManager.default.contentsOfDirectory(at: root.appendingPathComponent("meetings"), includingPropertiesForKeys: nil)
            var loaded: [Meeting] = []
            for dir in dirs {
                let path = dir.appendingPathComponent("meeting.json")
                guard FileManager.default.fileExists(atPath: path.path) else { continue }
                do { loaded.append(try JSONDecoder().decode(Meeting.self, from: Data(contentsOf: path))) }
                catch { self.error = "일부 회의 기록을 읽지 못했습니다. 원본 파일은 보관되어 있습니다.\n\(dir.lastPathComponent)" }
            }
            meetings = loaded.sorted { $0.createdAt > $1.createdAt }
            selection = ProcessInfo.processInfo.arguments.contains("--demo-home") ? nil : meetings.first?.id
        } catch { self.error = error.localizedDescription }
    }
    func persist(_ meeting: Meeting) throws {
        let dir = folder(meeting.id)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(meeting).write(to: dir.appendingPathComponent("meeting.json"), options: .atomic)
    }
    func update(_ id: String, _ transform: (inout Meeting) -> Void) {
        guard let index = meetings.firstIndex(where: { $0.id == id }) else { return }
        var copy = meetings[index]; transform(&copy)
        do { try persist(copy); meetings[index] = copy }
        catch { self.error = "저장하지 못했습니다: \(error.localizedDescription)" }
    }
    func checkConnections() {
        guard !checkingConnections else { return }
        checkingConnections = true
        Task {
            let result = await Task.detached { () -> (Bool, Bool, String) in
                func status(_ args: [String]) -> String {
                    let p = Process(); let pipe = Pipe()
                    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                    p.arguments = args; p.environment = Self.processEnvironment()
                    p.standardOutput = pipe; p.standardError = pipe
                    do {
                        try p.run()
                        let text = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                        p.waitUntilExit()
                        return p.terminationStatus == 0 ? text : ""
                    } catch { return "" }
                }
                let codex = status(["codex", "login", "status"]).contains("ChatGPT")
                let raw = status(["claude", "auth", "status"])
                let auth = raw.data(using: .utf8).flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
                let claude = auth?["loggedIn"] as? Bool == true
                let method = auth?["authMethod"] as? String ?? ""
                let label = method == "claude.ai" ? "개인 구독" : (claude ? "API / 외부 제공자" : "연결 필요")
                return (codex, claude, label)
            }.value
            codexReady = result.0; claudeReady = result.1; claudeAuthLabel = result.2; checkingConnections = false
        }
    }
    nonisolated static func processEnvironment() -> [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["PATH"] = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".local/bin").path + ":/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:" + (env["PATH"] ?? "")
        env["PYTHONUNBUFFERED"] = "1"
        return env
    }
    func importAudio() {
        guard !recording else { return }
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .movie]
        panel.allowsMultipleSelection = false
        panel.prompt = "회의 가져오기"
        guard panel.runModal() == .OK, let source = panel.url else { return }
        importURL(source)
    }
    func importURL(_ source: URL) {
        guard !recording else { return }
        let m = Meeting(title: source.deletingPathExtension().lastPathComponent, audioFile: "original.\(source.pathExtension.isEmpty ? "m4a" : source.pathExtension)")
        do {
            try FileManager.default.createDirectory(at: folder(m.id), withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: audio(m))
            var copy = m
            if let p = try? AVAudioPlayer(contentsOf: audio(m)) { copy.duration = p.duration }
            try persist(copy)
            meetings.insert(copy, at: 0); selection = copy.id
        } catch { self.error = "파일을 가져오지 못했습니다: \(error.localizedDescription)" }
    }
    func startRecording() async {
        guard !recording, !busy else { return }
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        guard granted else {
            error = "마이크 권한이 필요합니다. 시스템 설정 → 개인정보 보호 및 보안 → 마이크에서 미팅모아를 허용해주세요."
            return
        }
        pausePlayback()
        let formatter = DateFormatter(); formatter.dateFormat = "M월 d일 HH:mm 회의"
        let m = Meeting(title: formatter.string(from: Date()), audioFile: "recording.wav", interrupted: true)
        do {
            try persist(m)
            let r = try AVAudioRecorder(url: audio(m), settings: [
                AVFormatIDKey: Int(kAudioFormatLinearPCM), AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false])
            r.delegate = self; r.isMeteringEnabled = true
            guard r.record() else { throw NSError(domain: "Moa", code: 1, userInfo: [NSLocalizedDescriptionKey: "마이크 녹음을 시작하지 못했습니다."]) }
            recorder = r; recorderID = m.id; recording = true; recordSeconds = 0
            meetings.insert(m, at: 0); selection = m.id
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let r = self.recorder else { return }
                    r.updateMeters(); self.level = max(0, min(1, (r.averagePower(forChannel: 0)+55)/55))
                    self.recordSeconds = r.currentTime
                }
            }
        } catch { self.error = error.localizedDescription }
    }
    func stopRecording() {
        guard recording, let id = recorderID else { return }
        let duration = recorder?.currentTime ?? recordSeconds
        recorder?.stop(); recorder = nil; recordingTimer?.invalidate(); recordingTimer = nil
        recording = false; recorderID = nil; level = 0
        update(id) { $0.duration = duration; $0.interrupted = false }
        if duration >= 1 { analyze(id) }
    }
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            self.recordingTimer?.invalidate(); self.recording = false; self.recorder = nil
            self.error = "녹음 중 오류가 발생했습니다. 저장된 녹음을 확인해주세요. \(error?.localizedDescription ?? "")"
        }
    }
    func analyze(_ id: String) {
        guard !busy, !recording, let m = meeting(id) else { return }
        guard modelsReady else { error = "음성 모델 설치가 필요합니다. 프로젝트의 scripts/setup.sh를 실행해주세요."; return }
        runJob(mode: "transcribe", id: id, extra: ["audio": audio(m).path, "language": language, "speakerCount": speakerCount]) { [weak self] data in
            guard let self else { return }
            do {
                let value = try JSONDecoder().decode(Transcription.self, from: data)
                self.update(id) { $0.segments = value.segments; $0.speakers = value.speakers; $0.duration = value.duration; $0.minutes = nil; $0.messages = [] }
                if self.autoSummarize && self.aiReady { self.summarize(id) }
            } catch { self.error = error.localizedDescription }
        }
    }
    func summarize(_ id: String) {
        guard !busy, let m = meeting(id), !m.segments.isEmpty else { return }
        guard aiReady else { error = "선택한 AI 구독에 로그인한 후 연결을 새로고침해주세요."; return }
        runJob(mode: "summarize", id: id, extra: payload(m)) { [weak self] data in
            do {
                let minutes = try JSONDecoder().decode(Minutes.self, from: data)
                self?.update(id) { $0.minutes = minutes }
            } catch { self?.error = error.localizedDescription }
        }
    }
    func ask(_ id: String, question: String) {
        guard !busy, aiReady, let m = meeting(id), !m.segments.isEmpty, !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        var data = payload(m); data["question"] = question
        data["history"] = m.messages.map { ["role": $0.role, "text": $0.text] }
        update(id) { $0.messages.append(ChatMessage(role: "user", text: question)) }
        runJob(mode: "chat", id: id, extra: data) { [weak self] data in
            do {
                let answer = try JSONDecoder().decode(ChatAnswer.self, from: data)
                self?.update(id) { $0.messages.append(ChatMessage(role: "assistant", text: answer.answer)) }
            } catch { self?.error = error.localizedDescription }
        }
    }
    func payload(_ m: Meeting) -> [String: Any] {
        ["segments": (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(m.segments))) ?? [], "speakers": m.speakers]
    }
    func runJob(mode: String, id: String, extra: [String: Any], completion: @escaping (Data) -> Void) {
        guard !busy else { return }
        let job = root.appendingPathComponent("jobs/\(UUID().uuidString)")
        do {
            try FileManager.default.createDirectory(at: job, withIntermediateDirectories: true)
            var request = extra; request["mode"] = mode; request["provider"] = aiProvider
            try JSONSerialization.data(withJSONObject: request).write(to: job.appendingPathComponent("request.json"), options: .atomic)
            guard let resources = Bundle.main.resourceURL else { throw NSError(domain:"Moa", code:1) }
            let config = try JSONSerialization.jsonObject(with: Data(contentsOf: resources.appendingPathComponent("runtime.json"))) as? [String: String]
            guard let python = config?["python"], FileManager.default.isExecutableFile(atPath: python) else {
                throw NSError(domain:"Moa", code:2, userInfo:[NSLocalizedDescriptionKey:"음성 처리 환경이 없습니다. scripts/setup.sh를 실행해주세요."])
            }
            let p = Process(); p.executableURL = URL(fileURLWithPath: python)
            p.arguments = [resources.appendingPathComponent("engine.py").path, job.appendingPathComponent("request.json").path]
            p.environment = Self.processEnvironment()
            let log = job.appendingPathComponent("engine.log")
            FileManager.default.createFile(atPath: log.path, contents: nil)
            let handle = try FileHandle(forWritingTo: log)
            p.standardOutput = handle; p.standardError = handle
            p.terminationHandler = { [weak self] process in
                try? handle.close()
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.jobTimer?.invalidate(); self.jobTimer = nil
                    self.busy = false; self.jobProcess = nil; self.jobMeetingID = nil; self.jobFolder = nil
                    if self.jobCancelled { self.jobCancelled = false; try? FileManager.default.removeItem(at: job); return }
                    if process.terminationStatus == 0, let result = try? Data(contentsOf: job.appendingPathComponent("result.json")) {
                        completion(result)
                    } else {
                        let failure = (try? Data(contentsOf: job.appendingPathComponent("error.json"))).flatMap { try? JSONDecoder().decode(JobFailure.self, from: $0) }
                        self.error = failure?.message ?? "처리 중 오류가 발생했습니다. 원본 녹음은 보관되어 있습니다."
                    }
                    try? FileManager.default.removeItem(at: job)
                }
            }
            try p.run()
            busy = true; jobProcess = p; jobMeetingID = id; jobCancelled = false; jobFolder = job
            jobMessage = "분석 준비 중"; jobProgress = 0.01
            jobTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, let data = try? Data(contentsOf: job.appendingPathComponent("status.json")), let status = try? JSONDecoder().decode(JobStatus.self, from: data) else { return }
                    self.jobMessage = status.message; self.jobProgress = status.progress
                }
            }
        } catch { self.error = error.localizedDescription; try? FileManager.default.removeItem(at: job) }
    }
    func cancelJob() { jobCancelled = true; jobMessage = "분석 중지 중"; jobProcess?.terminate() }
    func play(_ id: String, at time: Double? = nil) {
        guard !recording, let m = meeting(id) else { return }
        do {
            if playingMeetingID != id || player == nil { player = try AVAudioPlayer(contentsOf: audio(m)); playingMeetingID = id }
            if let time { player?.currentTime = time }
            player?.play(); isPlaying = true
        } catch { self.error = error.localizedDescription }
    }
    func pausePlayback() { player?.pause(); isPlaying = false }
    func seek(_ value: Double) { player?.currentTime = value; playbackTime = value }
    func renameSpeaker(_ id: String, key: String, name: String) {
        guard !busy else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        update(id) { $0.speakers[key] = trimmed; $0.minutes = nil; $0.messages = [] }
    }
    func editSegment(_ id: String, segment: Segment) {
        guard !busy else { return }
        update(id) { m in
            if let i = m.segments.firstIndex(where: { $0.id == segment.id }) { m.segments[i] = segment; m.minutes = nil; m.messages = [] }
        }
    }
    func export(_ id: String) {
        guard let m = meeting(id) else { return }
        let panel = NSSavePanel(); panel.nameFieldStringValue = m.title + ".md"; panel.allowedContentTypes = [UTType(filenameExtension:"md") ?? .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do { try markdown(m).write(to: url, atomically: true, encoding: .utf8) }
        catch { self.error = error.localizedDescription }
    }
    func markdown(_ m: Meeting) -> String {
        var s = "# \(m.title)\n\n\(m.createdAt.formatted()) · \(timecode(m.duration))\n"
        if let v = m.minutes {
            s += "\n## 요약\n\n\(v.overview)\n\n## 주요 논의\n\n" + v.keyPoints.map { "- \($0)" }.joined(separator:"\n")
            s += "\n\n## 결정 사항\n\n" + v.decisions.map { "- \($0)" }.joined(separator:"\n")
            s += "\n\n## 할 일\n\n" + v.actionItems.map { "- [ ] \($0.task) — \($0.owner) / \($0.due) \($0.evidence)" }.joined(separator:"\n")
        }
        s += "\n\n## 대화록\n\n" + m.segments.map { "[\(timecode($0.start))] **\(m.speakers[$0.speaker] ?? $0.speaker)**: \($0.text)" }.joined(separator:"\n\n")
        return s + "\n"
    }
    func shutdown() {
        if recording { recorder?.stop(); recordingTimer?.invalidate() }
        jobProcess?.terminate()
        player?.stop()
    }
}
