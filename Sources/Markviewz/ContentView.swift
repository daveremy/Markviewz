import SwiftUI
import UniformTypeIdentifiers

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

    init(documentURL: URL) {
        self.documentURL = documentURL
        // Preload synchronously so first render isn't empty.
        _document = State(initialValue: Self.load(from: documentURL))
    }

    var body: some View {
        MarkdownWebView(html: document.html, baseURL: document.baseURL)
            .frame(minWidth: 600, minHeight: 400)
            .navigationTitle(document.title)
            .onAppear {
                DispatchQueue.main.async {
                    NSApp.keyWindow?.miniwindowTitle = documentURL.lastPathComponent
                }
            }
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
