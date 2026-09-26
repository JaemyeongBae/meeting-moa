import SwiftUI
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var store: MeetingStore?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular); NSApp.activate(ignoringOtherApps: true)
    }
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls { store?.importURL(url) }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if let store, store.recording || store.busy {
            let alert = NSAlert(); alert.messageText = "진행 중인 작업을 멈추고 종료할까요?"
            alert.informativeText = "녹음 파일은 보관됩니다. 분석은 다시 실행할 수 있습니다."
            alert.addButton(withTitle: "계속 사용"); alert.addButton(withTitle: "종료")
            if alert.runModal() != .alertSecondButtonReturn { return .terminateCancel }
        }
        store?.shutdown(); return .terminateNow
    }
}
@main
struct MoaMeetingApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var store = MeetingStore()
    var body: some Scene {
        WindowGroup("미팅모아 · 회의를 모으다") {
            RootView().environmentObject(store)
                .frame(minWidth: 1080, minHeight: 720)
                .onAppear {
                    delegate.store = store
                    let args = ProcessInfo.processInfo.arguments
                    if let index = args.firstIndex(of: "--import"), args.count > index+1, store.meetings.isEmpty {
                        store.importURL(URL(fileURLWithPath: args[index+1]))
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1220, height: 820)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("음성 파일 가져오기") { store.importAudio() }.keyboardShortcut("o")
                Button(store.recording ? "녹음 종료" : "새 녹음") {
                    if store.recording { store.stopRecording() } else { Task { await store.startRecording() } }
                }.keyboardShortcut("r", modifiers: [.command, .shift]).disabled(store.busy)
            }
        }
    }
}
