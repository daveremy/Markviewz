import SwiftUI
import UniformTypeIdentifiers

// MARK: - Reload notification

extension Notification.Name {
    /// Posted by AppDelegate when a file that's already open is re-opened
    /// (e.g. via `markviewz file.md` or `open -a Markviewz file.md`).
    /// userInfo["url"] carries the canonical URL to reload.
    static let markviewzReloadFile = Notification.Name("MarkviewzReloadFile")
}

// MARK: - File watcher

/// Monitors a file for changes using a GCD dispatch source. Publishes a
/// change counter that SwiftUI views can observe via `.onChange(of:)`.
///
/// Handles atomic saves (write-to-temp + rename) by watching for `.delete`,
/// `.rename`, and `.revoke` events and re-establishing the watch on the new
/// inode with retries.
final class FileWatcher: ObservableObject {
    private let url: URL
    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1

    /// Incremented each time a file change is detected.
    @Published private(set) var changeCount: Int = 0

    init(url: URL) {
        self.url = url
        startWatching()
    }

    deinit { stop() }

    func stop() {
        source?.cancel() // cancel handler closes fd
        source = nil
        fileDescriptor = -1
    }

    /// Open the file and attach a dispatch source. Returns true on success.
    @discardableResult
    private func startWatching() -> Bool {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return false }
        fileDescriptor = fd

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .revoke],
            queue: .main
        )
        src.setEventHandler { [weak self] in
            guard let self = self else { return }
            let flags = src.data
            if flags.contains(.delete) || flags.contains(.rename) || flags.contains(.revoke) {
                // Atomic save — file was replaced. Restart watcher on the
                // new inode, then signal change after successful re-open.
                self.restartWatching()
                return
            }
            // Normal in-place write.
            self.changeCount += 1
        }
        src.setCancelHandler { close(fd) }
        self.source = src
        src.resume()
        return true
    }

    /// Re-establish the watch after an atomic save (delete + rename).
    /// Retries up to 5 times with increasing delay to handle editors that
    /// take a moment to move the new file into place.
    private func restartWatching(attempt: Int = 0) {
        source?.cancel()
        source = nil
        fileDescriptor = -1

        let maxAttempts = 5
        let delay = 0.1 * Double(attempt + 1) // 100ms, 200ms, ... 500ms

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            if self.startWatching() {
                // Signal change AFTER successfully re-establishing the watch,
                // so the view reloads the new file content.
                self.changeCount += 1
            } else if attempt < maxAttempts - 1 {
                self.restartWatching(attempt: attempt + 1)
            }
            // After all retries, stop watching. Content stays as-is.
        }
    }
}

// MARK: - Document model

/// Immutable snapshot of what's currently rendered. A single state field
/// holding the document avoids multiple SwiftUI rebuilds when loading a
/// new file (previously each of html / baseURL / windowTitle was its
/// own @State, causing the WebView to reload 2–3 times per open).
struct MarkdownDocument {
    let html: String
    let baseURL: URL?
    let title: String
}

struct ContentView: View {
    /// URL passed in at window creation. Each window binds to one file.
    let documentURL: URL

    @State private var document: MarkdownDocument
    @StateObject private var watcher: FileWatcher

    init(documentURL: URL) {
        self.documentURL = documentURL
        // Preload synchronously so first render isn't empty.
        _document = State(initialValue: Self.load(from: documentURL))
        _watcher = StateObject(wrappedValue: FileWatcher(url: documentURL))
    }

    var body: some View {
        MarkdownWebView(html: document.html, baseURL: document.baseURL)
            .frame(minWidth: 600, minHeight: 400)
            .navigationTitle(document.title)
            .onChange(of: watcher.changeCount) {
                reload()
            }
            .onReceive(NotificationCenter.default.publisher(for: .markviewzReloadFile)) { notification in
                if let url = notification.userInfo?["url"] as? URL, url == documentURL {
                    reload()
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    NSApp.keyWindow?.miniwindowTitle = documentURL.lastPathComponent
                }
            }
    }

    private func reload() {
        document = Self.load(from: documentURL)
    }

    private static func load(from url: URL) -> MarkdownDocument {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let html = renderMarkdown(markdown)
            return MarkdownDocument(
                html: wrapHTMLPage(body: html),
                baseURL: url.deletingLastPathComponent(),
                title: shortenedPath(url.path)
            )
        } catch {
            return MarkdownDocument(
                html: wrapHTMLPage(body: "<p style='color:red'>Error reading file: \(error.localizedDescription)</p>"),
                baseURL: nil,
                title: "Markviewz"
            )
        }
    }
}

/// Shown when the app is launched without a file argument.
struct WelcomeView: View {
    let onOpen: (URL) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Markviewz")
                .font(.system(size: 48, weight: .light))
            Text("Open a Markdown file to get started")
                .font(.title3)
                .foregroundStyle(.secondary)
            Button("Open…") {
                let panel = NSOpenPanel()
                panel.allowedContentTypes = [
                    UTType(filenameExtension: "md") ?? .plainText,
                    UTType(filenameExtension: "markdown") ?? .plainText,
                    .plainText,
                ]
                panel.allowsMultipleSelection = false
                if panel.runModal() == .OK, let url = panel.url {
                    onOpen(url)
                }
            }
            .keyboardShortcut("o", modifiers: .command)
            Text("or drag a .md file here")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        onOpen(url)
                    }
                }
            }
            return true
        }
    }
}

private func shortenedPath(_ path: String) -> String {
    var display = path
    let home = FileManager.default.homeDirectoryForCurrentUser.path
    let homePrefix = home.hasSuffix("/") ? home : home + "/"
    if display.hasPrefix(homePrefix) {
        display = "~/" + display.dropFirst(homePrefix.count)
    } else if display == home {
        display = "~"
    }

    let maxLength = 60
    guard display.count > maxLength else { return display }

    let components = display.components(separatedBy: "/").filter { !$0.isEmpty }
    guard components.count > 3 else { return display }

    let prefix = components[0] == "~" ? "~" : "/" + components[0]
    let suffix = components.suffix(2).joined(separator: "/")
    return prefix + "/\u{2026}/" + suffix
}
