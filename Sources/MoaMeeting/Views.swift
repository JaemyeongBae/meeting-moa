import SwiftUI
import AppKit

let ink = Color(red: 0.16, green: 0.18, blue: 0.17)
let paper = Color(red: 0.97, green: 0.965, blue: 0.946)
let accent = Color(red: 0.83, green: 0.32, blue: 0.18)
let muted = Color(red: 0.46, green: 0.48, blue: 0.44)
let rule = Color.black.opacity(0.08)

struct RootView: View {
    @EnvironmentObject var store: MeetingStore
    @State private var search = ""
    @State private var settings = false
    var body: some View {
        HStack(spacing: 0) {
            sidebar.frame(width: 246)
            Rectangle().fill(rule).frame(width: 1)
            VStack(spacing: 0) {
                if store.recording { recordingBar }
                if store.busy { progressBar }
                if let id = store.selection, store.meeting(id) != nil {
                    MeetingDetail(id: id).id(id)
                } else { emptyState }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(paper).foregroundStyle(ink).preferredColorScheme(.light)
        .tint(accent)
        .alert("확인이 필요해요", isPresented: Binding(get: { store.error != nil }, set: { if !$0 { store.error = nil } })) {
            Button("확인") { store.error = nil }
        } message: { Text(store.error ?? "") }
        .sheet(isPresented: $settings) { SettingsView() }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "waveform.path").font(.system(size: 26, weight: .medium)).foregroundStyle(accent)
                Text("미팅모아").font(.system(size: 22, weight: .bold, design: .rounded))
                Spacer()
                Text(store.isDemo ? "DEMO" : "PREVIEW").font(.system(size: 8, weight: .bold, design: .monospaced)).tracking(1.1).foregroundStyle(muted)
            }.padding(.top, 40).padding(.bottom, 28)
            Button { Task { await store.startRecording() } } label: {
                Label("새 회의 녹음", systemImage: "plus").font(.system(size: 13, weight: .semibold)).frame(maxWidth: .infinity).padding(.vertical, 11)
            }.buttonStyle(.plain).foregroundStyle(.white).background(ink, in: RoundedRectangle(cornerRadius: 9)).disabled(store.recording || store.busy)
            Button { store.importAudio() } label: {
                Label("음성 파일 가져오기", systemImage: "arrow.down.to.line").font(.system(size: 12)).frame(maxWidth: .infinity).padding(.vertical, 12)
            }.buttonStyle(.plain).foregroundStyle(muted).disabled(store.recording)
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                TextField("회의 검색", text: $search).textFieldStyle(.plain)
            }.font(.system(size: 12)).foregroundStyle(muted).padding(9).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 7)).padding(.top, 10)
            HStack {
                Text("내 회의").font(.system(size: 10, weight: .semibold))
                Spacer(); Text("\(store.meetings.count)").font(.system(size: 10, design: .monospaced))
            }.foregroundStyle(muted).padding(.top, 28).padding(.bottom, 12)
            ScrollView {
                VStack(spacing: 5) {
                    ForEach(store.meetings.filter { search.isEmpty || $0.title.localizedCaseInsensitiveContains(search) }) { m in
                        Button { store.selection = m.id } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(m.title).font(.system(size: 13, weight: store.selection == m.id ? .semibold : .regular)).lineLimit(2).multilineTextAlignment(.leading)
                                HStack {
                                    Text(m.createdAt.formatted(.dateTime.month().day()))
                                    Spacer()
                                    if m.minutes != nil { Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green.opacity(0.7)) }
                                    Text(timecode(m.duration)).monospacedDigit()
                                }.font(.system(size: 10)).foregroundStyle(muted)
                            }.padding(12).frame(maxWidth: .infinity, alignment: .leading)
                                .background(store.selection == m.id ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                        }.buttonStyle(.plain)
                    }
                }
            }
            Spacer(minLength: 12)
            Button { settings = true } label: {
                HStack(spacing: 9) {
                    Circle().fill(store.aiReady ? Color.green.opacity(0.7) : .orange).frame(width: 7, height: 7)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(store.aiReady ? "내 \(store.providerName) 연결됨" : "\(store.providerName) 연결 확인").font(.system(size: 11, weight: .medium))
                        Text(store.aiProvider == "claude" ? "\(store.claudeAuthLabel) · 로컬 음성 분석" : "개인 구독 · 로컬 음성 분석").font(.system(size: 9)).foregroundStyle(muted)
                    }
                    Spacer(); Image(systemName: "gearshape").foregroundStyle(muted)
                }.padding(.vertical, 14)
            }.buttonStyle(.plain)
        }.padding(.horizontal, 18).background(Color(red:0.935, green:0.935, blue:0.915))
    }
    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("YOUR MEETING, REMEMBERED.").font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(2).foregroundStyle(muted)
                Spacer(); Text("LOCAL FIRST").font(.system(size: 9, design: .monospaced)).foregroundStyle(muted)
            }.padding(.bottom, 52)
            Image(systemName: "waveform").font(.system(size: 42, weight: .ultraLight)).foregroundStyle(accent).padding(.bottom, 25)
            Text("대화에 집중하세요.\n기록은 미팅모아가 할게요.").font(.system(size: 38, weight: .semibold)).tracking(-1.8).lineSpacing(8)
            Text("녹음부터 발화자 구분, 요약과 다음 할 일까지.\n회의가 끝나면 흩어진 이야기를 한곳에 모읍니다.")
                .font(.system(size: 14)).foregroundStyle(muted).lineSpacing(7).padding(.top, 22)
            HStack(spacing: 12) {
                Button { Task { await store.startRecording() } } label: {
                    Label("첫 회의 녹음하기", systemImage: "mic.fill").font(.system(size: 13, weight: .semibold)).padding(.horizontal, 22).padding(.vertical, 13)
                }.buttonStyle(.plain).foregroundStyle(.white).background(accent, in: Capsule()).disabled(store.busy)
                Button("파일로 시작하기") { store.importAudio() }.buttonStyle(.plain).font(.system(size: 13)).padding(.horizontal, 18)
            }.padding(.top, 32)
            Rectangle().fill(rule).frame(height: 1).padding(.top, 58).padding(.bottom, 24)
            HStack(alignment: .top, spacing: 34) {
                introStep("01", "녹음", "마이크 또는 음성 파일")
                introStep("02", "대화록", "화자별 기록과 원문 재생")
                introStep("03", "회의록", "결정 사항과 할 일 정리")
            }
            Text("음성은 이 Mac에서 분석합니다. 요약·채팅 시 대화록을 선택한 AI로 전송합니다.")
                .font(.system(size: 10)).foregroundStyle(muted).padding(.top, 34)
        }.padding(55).frame(maxWidth: 900, maxHeight: .infinity, alignment: .center)
    }
    private func introStep(_ number: String, _ title: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(number).font(.system(size: 10, design: .monospaced)).foregroundStyle(accent)
            Text(title).font(.system(size: 14, weight: .semibold))
            Text(caption).font(.system(size: 11)).foregroundStyle(muted)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    private var recordingBar: some View {
        HStack(spacing: 14) {
            Circle().fill(accent).frame(width: 8, height: 8)
            Text("마이크 녹음 중").font(.system(size: 12, weight: .semibold))
            Text(timecode(store.recordSeconds)).font(.system(size: 14, design: .monospaced))
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<18) { i in
                    Capsule().fill(accent.opacity(Double(i)/18 < Double(store.level) ? 1 : 0.15)).frame(width: 3, height: CGFloat(8 + (i % 5) * 3))
                }
            }
            Spacer()
            Button("녹음 종료 · 분석") { store.stopRecording() }.buttonStyle(.borderedProminent).font(.system(size: 12))
        }.padding(.horizontal, 28).padding(.vertical, 16).background(accent.opacity(0.07))
    }
    private var progressBar: some View {
        HStack(spacing: 14) {
            ProgressView().controlSize(.small)
            VStack(alignment: .leading, spacing: 6) {
                Text(store.jobMessage).font(.system(size: 12, weight: .medium))
                ProgressView(value: store.jobProgress).frame(width: 210)
            }
            Spacer()
            Button("중지") { store.cancelJob() }.buttonStyle(.bordered).font(.system(size: 11))
        }.padding(.horizontal, 28).padding(.vertical, 13).background(.white.opacity(0.8))
    }
}

struct MeetingDetail: View {
    @EnvironmentObject var store: MeetingStore
    let id: String
    @State private var tab = "대화록"
    @State private var question = ""
    @State private var renameKey: String?
    @State private var renameValue = ""
    @State private var editing: Segment?
    @State private var editTitle = false
    @State private var titleValue = ""
    @State private var transcriptSearch = ""
    private var meeting: Meeting { store.meeting(id)! }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Picker("AI", selection: $store.aiProvider) {
                    Text("Codex").tag("codex")
                    Text("Claude").tag("claude")
                }.labelsHidden().frame(width:115).disabled(store.busy)
                Text("MEETING NOTES").font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(2).foregroundStyle(muted)
                Spacer()
                Button { store.export(id) } label: { Label("내보내기", systemImage:"square.and.arrow.up").font(.system(size:11)) }.buttonStyle(.plain)
                    .disabled(meeting.segments.isEmpty)
            }.padding(.top, 36)
            HStack(alignment: .top) {
                Text(meeting.title).font(.system(size: 28, weight: .semibold)).tracking(-0.8).lineLimit(2)
                Button { titleValue = meeting.title; editTitle = true } label: { Image(systemName:"pencil").font(.system(size:12)).foregroundStyle(muted) }.buttonStyle(.plain).padding(.top, 8)
                Spacer()
            }.padding(.top, 18)
            HStack(spacing: 16) {
                Label(meeting.createdAt.formatted(.dateTime.year().month().day().hour().minute()), systemImage:"calendar")
                Label(timecode(meeting.duration), systemImage:"clock")
                if !meeting.speakers.isEmpty { Label("\(meeting.speakers.keys.filter { $0 != "unknown" }.count)명의 화자", systemImage:"person.2") }
            }.font(.system(size:11)).foregroundStyle(muted).padding(.top, 12)
            if meeting.interrupted && !store.recording {
                Text("중단된 녹음입니다. 원본을 재생해 확인한 뒤 분석해주세요.").font(.system(size:11)).foregroundStyle(accent).padding(.top, 12)
            }
            playbackBar.padding(.top, 24).padding(.bottom, 23)
            HStack(spacing: 26) {
                ForEach(["대화록", "회의록", "AI에게 질문"], id: \.self) { name in
                    Button { tab = name } label: {
                        VStack(spacing: 11) {
                            Text(name).font(.system(size:13, weight: tab == name ? .semibold : .regular)).foregroundStyle(tab == name ? ink : muted)
                            Rectangle().fill(tab == name ? accent : .clear).frame(height: 2)
                        }
                    }.buttonStyle(.plain).fixedSize(horizontal: true, vertical: false)
                }
                Spacer()
                if !meeting.segments.isEmpty && tab == "회의록" {
                    Button(meeting.minutes == nil ? "회의록 만들기" : "다시 정리") { store.summarize(id) }.font(.system(size:11)).disabled(store.busy || !store.aiReady)
                }
            }
            Rectangle().fill(rule).frame(height: 1)
            if meeting.segments.isEmpty { pendingTranscript }
            else if tab == "대화록" { transcript }
            else if tab == "회의록" { minutesView }
            else { chatView }
        }.padding(.horizontal, 36)
        .alert("화자 이름 변경", isPresented: Binding(get: { renameKey != nil }, set: { if !$0 { renameKey = nil } })) {
            TextField("이름", text: $renameValue)
            Button("취소", role: .cancel) { renameKey = nil }
            Button("저장") { if let key = renameKey { store.renameSpeaker(id, key: key, name: renameValue) }; renameKey = nil }
        } message: { Text("대화록 전체에 적용됩니다. 기존 요약과 채팅은 초기화됩니다.") }
        .alert("회의 이름 변경", isPresented: $editTitle) {
            TextField("회의 이름", text: $titleValue)
            Button("취소", role:.cancel) {}
            Button("저장") { if !titleValue.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty { store.update(id) { $0.title = titleValue } } }
        }
        .sheet(item: $editing) { value in SegmentEditor(meetingID: id, segment: value) }
    }
    private var playbackBar: some View {
        HStack(spacing: 14) {
            Button {
                if store.playingMeetingID == id && store.isPlaying { store.pausePlayback() } else { store.play(id) }
            } label: {
                Image(systemName: store.playingMeetingID == id && store.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 12)).frame(width: 33, height: 33).background(ink, in: Circle()).foregroundStyle(.white)
            }.buttonStyle(.plain).disabled(store.recording)
            Text(timecode(store.playingMeetingID == id ? store.playbackTime : 0)).font(.system(size:11, design:.monospaced))
            Slider(value: Binding(get: { store.playingMeetingID == id ? min(store.playbackTime,max(1,meeting.duration)) : 0 }, set: {
                if store.playingMeetingID != id { store.play(id, at: $0); store.pausePlayback() } else { store.seek($0) }
            }), in: 0...max(1,meeting.duration)).disabled(store.recording)
            Text(timecode(meeting.duration)).font(.system(size:11, design:.monospaced)).foregroundStyle(muted)
        }.padding(14).background(.white.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
    }
    private var pendingTranscript: some View {
        VStack(spacing: 17) {
            Image(systemName: store.recording ? "waveform" : "text.bubble").font(.system(size:32, weight:.ultraLight)).foregroundStyle(accent)
            Text(store.recording ? "좋은 대화는, 듣는 데서 시작하니까." : "녹음을 대화록으로 바꿔보세요.").font(.system(size:18, weight:.medium))
            Text(store.recording ? "이 Mac의 마이크로 녹음하고 있습니다. 종료하면 분석을 시작합니다." : "음성 인식과 발화자 구분은 이 Mac에서 처리합니다.")
                .font(.system(size:12)).foregroundStyle(muted)
            if !store.recording {
                HStack {
                    Picker("언어", selection: $store.language) { Text("한국어").tag("ko"); Text("자동 감지").tag("auto"); Text("영어").tag("en") }.frame(width:155)
                    Picker("화자", selection: $store.speakerCount) { Text("자동").tag(-1); ForEach(1...8,id:\.self) { Text("\($0)명").tag($0) } }.frame(width:130)
                }.font(.system(size:12)).disabled(store.busy)
                Button("대화록 분석 시작") { store.analyze(id) }.buttonStyle(.borderedProminent).disabled(store.busy)
            }
        }.frame(maxWidth:.infinity,maxHeight:.infinity)
    }
    private var transcript: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                // 화자가 많아도 창 너비를 밀어내지 않도록 가로 스크롤로 둔다.
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(meeting.speakers.keys.sorted(),id:\.self) { key in
                            Button { renameKey = key; renameValue = meeting.speakers[key] ?? "" } label: {
                                HStack(spacing: 5) { Circle().fill(speakerColor(key)).frame(width:6,height:6); Text(meeting.speakers[key] ?? key); Image(systemName:"pencil").font(.system(size:8)) }
                                    .font(.system(size:10)).padding(.horizontal,10).padding(.vertical,7).background(.white, in:Capsule())
                            }.buttonStyle(.plain).disabled(store.busy)
                        }
                    }
                }
                TextField("대화록 검색", text:$transcriptSearch).textFieldStyle(.roundedBorder).frame(width:145).font(.system(size:11))
            }.padding(.vertical, 18)
            ScrollView {
                LazyVStack(alignment:.leading, spacing: 0) {
                    ForEach(meeting.segments.filter { transcriptSearch.isEmpty || $0.text.localizedCaseInsensitiveContains(transcriptSearch) }) { s in
                        HStack(alignment:.top, spacing:16) {
                            Button { store.play(id, at:s.start) } label: { Text(timecode(s.start)).font(.system(size:10,design:.monospaced)).foregroundStyle(muted).frame(width:52,alignment:.leading) }.buttonStyle(.plain).padding(.top,3)
                            VStack(alignment:.leading,spacing:8) {
                                Text(meeting.speakers[s.speaker] ?? s.speaker).font(.system(size:11,weight:.semibold)).foregroundStyle(speakerColor(s.speaker))
                                Text(s.text).font(.system(size:14)).lineSpacing(6).textSelection(.enabled).frame(maxWidth:.infinity,alignment:.leading)
                            }
                            Button { editing = s } label: { Image(systemName:"pencil").font(.system(size:10)).foregroundStyle(muted.opacity(0.6)) }.buttonStyle(.plain).disabled(store.busy)
                        }.padding(.vertical,17)
                        Rectangle().fill(rule.opacity(0.55)).frame(height:1)
                    }
                }.padding(.bottom,24)
            }
            HStack {
                Text("시각을 누르면 원문을 재생합니다 · 발화자 구분은 수정할 수 있어요").font(.system(size:9)).foregroundStyle(muted)
                Spacer()
                Picker("화자", selection: $store.speakerCount) { Text("화자 자동").tag(-1); ForEach(1...8,id:\.self) { Text("화자 \($0)명").tag($0) } }
                    .labelsHidden().frame(width:100).font(.system(size:10)).disabled(store.busy || store.recording)
                Button("다시 분석") { store.analyze(id) }.font(.system(size:10)).buttonStyle(.plain).foregroundStyle(muted).disabled(store.busy || store.recording)
            }.padding(.vertical,12)
        }
    }
    private var minutesView: some View {
        ScrollView {
            if let m = meeting.minutes {
                VStack(alignment:.leading,spacing:24) {
                    VStack(alignment:.leading,spacing:13) {
                        Label("한눈에 보는 회의", systemImage:"sparkles").font(.system(size:11,weight:.semibold)).foregroundStyle(accent)
                        Text(m.overview).font(.system(size:16,weight:.medium)).lineSpacing(7).textSelection(.enabled)
                    }.frame(maxWidth:.infinity,alignment:.leading).padding(23).background(Color.white,in:RoundedRectangle(cornerRadius:12))
                    section("주요 논의", items:m.keyPoints)
                    section("결정 사항", items:m.decisions)
                    VStack(alignment:.leading,spacing:13) {
                        Text("다음 할 일").font(.system(size:16,weight:.semibold))
                        if m.actionItems.isEmpty { Text("명시된 할 일이 없습니다.").font(.system(size:12)).foregroundStyle(muted) }
                        ForEach(Array(m.actionItems.enumerated()),id:\.offset) { _, a in
                            HStack(alignment:.top,spacing:12) {
                                Image(systemName:"square").foregroundStyle(muted).padding(.top,2)
                                VStack(alignment:.leading,spacing:6) {
                                    Text(a.task).font(.system(size:13)).textSelection(.enabled)
                                    Text("\(a.owner) · \(a.due)  \(a.evidence)").font(.system(size:10)).foregroundStyle(muted)
                                }
                                Spacer()
                            }.padding(15).background(.white.opacity(0.7),in:RoundedRectangle(cornerRadius:8))
                        }
                    }
                    Text("AI가 정리한 내용입니다. 중요한 결정과 담당자는 원문에서 확인해주세요.").font(.system(size:10)).foregroundStyle(muted)
                }.padding(.vertical,24)
            } else {
                VStack(spacing:14) {
                    Image(systemName:"sparkles").font(.system(size:30,weight:.ultraLight)).foregroundStyle(accent)
                    Text("대화를 다음 행동으로.").font(.system(size:20,weight:.medium))
                    Text("내 \(store.providerName) 구독으로 핵심 논의, 결정 사항, 할 일을 정리합니다.").font(.system(size:12)).foregroundStyle(muted)
                    Button("회의록 만들기") { store.summarize(id) }.buttonStyle(.borderedProminent).disabled(store.busy || !store.aiReady)
                }.frame(maxWidth:.infinity).padding(.top,90)
            }
        }
    }
    private func section(_ title: String, items: [String]) -> some View {
        VStack(alignment:.leading,spacing:13) {
            Text(title).font(.system(size:16,weight:.semibold))
            if items.isEmpty { Text("명시된 내용이 없습니다.").font(.system(size:12)).foregroundStyle(muted) }
            ForEach(Array(items.enumerated()),id:\.offset) { _, item in
                HStack(alignment:.top,spacing:10) { Text("•").foregroundStyle(accent); Text(item).lineSpacing(5).textSelection(.enabled) }.font(.system(size:13))
            }
        }
    }
    private var chatView: some View {
        VStack(spacing:0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment:.leading,spacing:20) {
                        if meeting.messages.isEmpty {
                            Text("회의에 대해 궁금한 것을 물어보세요.").font(.system(size:19,weight:.medium)).padding(.top,22)
                            Text("답변에 원문 시각을 함께 표시합니다.").font(.system(size:12)).foregroundStyle(muted)
                            ForEach(["이번 회의에서 결정된 내용은?", "담당자별 할 일을 정리해줘", "아직 해결되지 않은 쟁점은?"],id:\.self) { q in
                                Button(q) { question = q }.buttonStyle(.bordered).font(.system(size:12))
                            }
                        }
                        ForEach(meeting.messages) { m in
                            VStack(alignment:.leading,spacing:9) {
                                Text(m.role == "user" ? "나" : "미팅모아").font(.system(size:10,weight:.semibold)).foregroundStyle(m.role == "user" ? muted : accent)
                                Text(m.text).font(.system(size:13)).lineSpacing(6).textSelection(.enabled)
                            }.frame(maxWidth:.infinity,alignment:.leading).padding(18).background(m.role == "user" ? Color.clear : Color.white,in:RoundedRectangle(cornerRadius:12)).id(m.id)
                        }
                    }.frame(maxWidth:.infinity,alignment:.leading).padding(.vertical,20)
                }.onChange(of: meeting.messages.count) { _, _ in if let last = meeting.messages.last { proxy.scrollTo(last.id,anchor:.bottom) } }
            }
            HStack(alignment:.bottom,spacing:12) {
                TextField("이 회의에 대해 질문하기…",text:$question,axis:.vertical).textFieldStyle(.plain).lineLimit(1...4).font(.system(size:13)).onSubmit { send() }
                Button { send() } label: { Image(systemName:"arrow.up").font(.system(size:13,weight:.semibold)).frame(width:30,height:30).foregroundStyle(.white).background(ink,in:Circle()) }.buttonStyle(.plain).disabled(store.busy || !store.aiReady || question.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)
            }.padding(14).background(.white,in:RoundedRectangle(cornerRadius:12))
            Text("대화록을 선택한 AI로 전송합니다. 해당 계정의 한도·요금이 적용됩니다.").font(.system(size:9)).foregroundStyle(muted).padding(.vertical,12)
        }
    }
    private func send() {
        let q=question.trimmingCharacters(in:.whitespacesAndNewlines)
        guard !q.isEmpty, !store.busy, store.aiReady else { return }
        store.ask(id,question:q);question=""
    }
    private func speakerColor(_ key: String) -> Color {
        let colors: [Color] = [accent,Color(red:0.24,green:0.43,blue:0.39),Color(red:0.40,green:0.39,blue:0.62),Color(red:0.60,green:0.45,blue:0.21)]
        return colors[(meeting.speakers.keys.sorted().firstIndex(of:key) ?? 0) % colors.count]
    }
}

struct SegmentEditor: View {
    @EnvironmentObject var store: MeetingStore
    @Environment(\.dismiss) var dismiss
    let meetingID: String
    @State var segment: Segment
    var body: some View {
        VStack(alignment:.leading,spacing:18) {
            Text("대화 수정 · \(timecode(segment.start))").font(.title3.bold())
            Picker("발화자",selection:$segment.speaker) {
                ForEach((store.meeting(meetingID)?.speakers ?? [:]).keys.sorted(),id:\.self) { key in Text(store.meeting(meetingID)?.speakers[key] ?? key).tag(key) }
            }
            TextEditor(text:$segment.text).font(.system(size:14)).frame(height:150).border(rule)
            Text("수정 후 기존 회의록과 채팅이 초기화됩니다. 회의록을 다시 생성해주세요.").font(.caption).foregroundStyle(.secondary)
            HStack { Spacer(); Button("취소") { dismiss() }; Button("저장") { store.editSegment(meetingID,segment:segment); dismiss() }.buttonStyle(.borderedProminent).disabled(segment.text.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty) }
        }.padding(25).frame(width:510)
    }
}
struct SettingsView: View {
    @EnvironmentObject var store: MeetingStore
    @Environment(\.dismiss) var dismiss
    var body: some View {
        VStack(alignment:.leading,spacing:22) {
            HStack { Text("미팅모아 설정").font(.title2.bold()); Spacer(); Button("완료") { dismiss() } }
            Picker("요약·질문에 사용할 AI", selection: $store.aiProvider) {
                Text("Codex · ChatGPT 구독").tag("codex")
                Text("Claude Code").tag("claude")
            }.pickerStyle(.segmented).disabled(store.busy)
            GroupBox {
                VStack(alignment:.leading,spacing:12) {
                    Label(store.codexReady ? "ChatGPT 구독 연결됨" : "ChatGPT 로그인 필요", systemImage:store.codexReady ? "checkmark.circle.fill" : "circle").foregroundStyle(store.codexReady ? .green : .secondary)
                    Label(store.claudeReady ? (store.claudeAuthLabel == "개인 구독" ? "Claude 구독 연결됨" : "Claude API / 외부 제공자 연결됨") : "Claude 로그인 필요", systemImage:store.claudeReady ? "checkmark.circle.fill" : "circle").foregroundStyle(store.claudeReady ? .green : .secondary)
                    Text("이 Mac에 로그인된 Codex 또는 Claude Code를 사용합니다. 선택한 CLI의 인증 설정으로 처리합니다. Claude Code에 API 키를 설정했다면 API 요금이 적용됩니다.").font(.system(size:12)).fixedSize(horizontal:false,vertical:true)
                    Text("로그인: codex login / claude auth login").font(.system(size:11)).foregroundStyle(.secondary).textSelection(.enabled)
                    Button(store.checkingConnections ? "확인 중…" : "연결 새로고침") { store.checkConnections() }.disabled(store.checkingConnections)
                }.frame(maxWidth:.infinity,alignment:.leading).padding(10)
            }
            Toggle("대화록 분석 후 회의록 자동 생성",isOn:$store.autoSummarize)
            Text("켜두면 녹음 종료 후 대화록이 선택한 AI로 전송됩니다. 음성 파일과 발화자 분석은 Mac에 보관됩니다.").font(.system(size:11)).foregroundStyle(.secondary)
            HStack {
                Label(store.modelsReady ? "음성 모델 준비됨" : "음성 모델 설치 필요",systemImage:"waveform").font(.system(size:12))
                Spacer()
                Button("저장 폴더 열기") { NSWorkspace.shared.open(store.root) }
            }
            Divider()
            Text("미팅모아 0.2 · Mac 미리보기\n마이크 녹음과 음성 파일 가져오기를 지원합니다. 온라인 회의의 시스템 소리 직접 녹음은 아직 포함되지 않았습니다.")
                .font(.system(size:11)).foregroundStyle(.secondary).lineSpacing(5)
        }.padding(30).frame(width:520).background(paper)
    }
}
