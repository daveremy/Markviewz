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
            CommandGroup(after: .newItem) {
                Button("Print…") {
                    printDocument()
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }

    private func printDocument() {
        guard let webView = WebViewStore.shared.webView else { return }
        let printInfo = NSPrintInfo.shared
        printInfo.horizontalPagination = .fit
        printInfo.verticalPagination = .automatic
        printInfo.isHorizontallyCentered = true
        printInfo.isVerticallyCentered = false
        printInfo.topMargin = 36
        printInfo.bottomMargin = 36
        printInfo.leftMargin = 36
        printInfo.rightMargin = 36

        let printOp = webView.printOperation(with: printInfo)
        printOp.showsPrintPanel = true
        printOp.showsProgressPanel = true
        printOp.run()
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
        // Bring window to front when opening a new file
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
