import SwiftUI
import AppKit

@main
struct MarkviewzApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Hidden Settings scene — present only to host menu bar commands.
        // All real windows are managed by AppDelegate via AppKit so we can
        // implement "reuse window if already showing this file, otherwise
        // spawn a new one" (SwiftUI's Scene system doesn't compose well
        // with that dedup-by-value + create-new-for-fresh-value pattern).
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .newItem) {
                Button("Open…") {
                    NSApp.sendAction(#selector(AppDelegate.openFileDialog(_:)), to: nil, from: nil)
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Print…") {
                    printDocument()
                }
                .keyboardShortcut("p", modifiers: .command)
            }
        }
    }

    private func printDocument() {
        guard let webView = WebViewStore.shared.webView,
              let window = webView.window else { return }

        webView.setValue(true, forKey: "drawsBackground")
        webView.display()

        let printInfo = NSPrintInfo.shared.copy() as! NSPrintInfo
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
        printOp.runModal(for: window, delegate: nil, didRun: nil, contextInfo: nil)

        webView.setValue(false, forKey: "drawsBackground")
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    /// Windows keyed by canonical file URL. One window per unique file.
    /// Opening a file that's already visible just brings its window forward.
    private var windowsByURL: [URL: NSWindow] = [:]

    /// Welcome/no-file window, shown when app launches with no arguments
    /// and there's no other window visible.
    private var welcomeWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Close the default Settings window Apple opens automatically.
        // We don't use it; we manage windows ourselves.
        DispatchQueue.main.async {
            NSApp.windows
                .filter { $0.className.contains("SettingsWindow") || $0.title == "Markviewz Settings" }
                .forEach { $0.close() }
        }

        // CLI invocation: `markviewz` binary directly with file arg.
        // (When invoked via `open -a Markviewz file.md`, file URLs arrive
        // through application(_:open:) instead.)
        let args = CommandLine.arguments
        if args.count > 1 {
            let path = (args[1] as NSString).standardizingPath
            openFile(URL(fileURLWithPath: path))
        } else {
            // No file given and nothing else is opening — show welcome.
            DispatchQueue.main.async { [weak self] in
                if let self = self, self.windowsByURL.isEmpty {
                    self.showWelcome()
                }
            }
        }
    }

    /// Called by macOS when the app receives file URLs via
    /// `open -a Markviewz file.md` or Finder double-click.
    func application(_ application: NSApplication, open urls: [URL]) {
        urls.forEach { openFile($0) }
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Re-open behavior: when user clicks the dock icon with no windows,
    /// show welcome rather than doing nothing.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag && windowsByURL.isEmpty {
            showWelcome()
        }
        return true
    }

    /// Don't quit when the last window closes — user may re-open via Dock.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // MARK: - File opening

    fileprivate func openFile(_ url: URL) {
        let canonical = canonicalize(url)

        // Already open — bring forward.
        if let existing = windowsByURL[canonical] {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        // Not open — spawn a new window.
        let host = NSHostingController(rootView: ContentView(documentURL: canonical))
        let window = NSWindow(contentViewController: host)
        window.title = canonical.lastPathComponent
        window.setContentSize(NSSize(width: 900, height: 720))
        window.styleMask.insert(.resizable)
        window.center()
        window.makeKeyAndOrderFront(nil)

        windowsByURL[canonical] = window

        // Clean up registry when the user closes the window.
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.windowsByURL.removeValue(forKey: canonical)
        }

        // Close the welcome window once a real doc is open.
        welcomeWindow?.close()
        welcomeWindow = nil
    }

    // MARK: - Welcome window

    private func showWelcome() {
        if let existing = welcomeWindow {
            existing.makeKeyAndOrderFront(nil)
            return
        }
        let host = NSHostingController(rootView: WelcomeView(onOpen: { [weak self] url in
            self?.openFile(url)
        }))
        let window = NSWindow(contentViewController: host)
        window.title = "Markviewz"
        window.setContentSize(NSSize(width: 600, height: 400))
        window.styleMask.insert(.resizable)
        window.center()
        window.makeKeyAndOrderFront(nil)
        welcomeWindow = window

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.welcomeWindow = nil
        }
    }

    // MARK: - Menu command

    @objc func openFileDialog(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "md") ?? .plainText,
                                     .init(filenameExtension: "markdown") ?? .plainText,
                                     .plainText]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            openFile(url)
        }
    }

    // MARK: - Helpers

    /// Canonicalize a URL so the same file under different paths (symlinks,
    /// relative paths, tilde-expansion) resolves to the same registry key.
    private func canonicalize(_ url: URL) -> URL {
        url.resolvingSymlinksInPath().standardizedFileURL
    }
}
