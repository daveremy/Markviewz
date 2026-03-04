import SwiftUI
import AppKit

@main
struct MarkviewzApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate)
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    @Published var fileToOpen: URL?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Handle CLI arguments (when running binary directly)
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = (args[1] as NSString).standardizingPath
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                fileToOpen = url
            }
        }
    }

    // Handle files opened via `open -a Markviewz file.md` or Finder double-click
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            fileToOpen = url
        }
    }
}
