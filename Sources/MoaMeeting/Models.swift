import Foundation

struct Segment: Codable, Identifiable {
    var id: String
    var start: Double
    var end: Double
    var speaker: String
    var text: String
}
struct ActionItem: Codable, Identifiable {
    var id: String { task + evidence }
    var task: String
    var owner: String
    var due: String
    var evidence: String
}
struct Minutes: Codable {
    var title: String
    var overview: String
    var keyPoints: [String]
    var decisions: [String]
    var actionItems: [ActionItem]
}
struct ChatMessage: Codable, Identifiable {
    var id = UUID().uuidString
    var role: String
    var text: String
}
struct Meeting: Codable, Identifiable {
    var id = UUID().uuidString
    var title: String
    var createdAt = Date()
    var audioFile: String
    var duration: Double = 0
    var segments: [Segment] = []
    var speakers: [String: String] = [:]
    var minutes: Minutes? = nil
    var messages: [ChatMessage] = []
    var interrupted: Bool = false
}
struct Transcription: Codable {
    var segments: [Segment]
    var speakers: [String: String]
    var duration: Double
}
struct JobStatus: Codable { var message: String; var progress: Double }
struct JobFailure: Codable { var message: String }
struct ChatAnswer: Codable { var answer: String }
func timecode(_ seconds: Double) -> String {
    let s = max(0, Int(seconds))
    return s >= 3600 ? String(format: "%02d:%02d:%02d", s / 3600, s / 60 % 60, s % 60) : String(format: "%02d:%02d", s / 60, s % 60)
}
