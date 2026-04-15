import SwiftUI
import UniformTypeIdentifiers

/// Immutable snapshot of what's currently rendered. A single state field
/// holding the document avoids multiple SwiftUI rebuilds when opening a
/// new file (previously each of html / baseURL / windowTitle was its
/// own @State, causing the WebView to reload 2–3 times per open).
struct MarkdownDocument {
    let html: String
    let baseURL: URL?
    let title: String

    static let welcome = MarkdownDocument(
        html: wrapHTMLPage(body: welcomeHTML),
        baseURL: nil,
        title: "Markviewz"
    )
}

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var document: MarkdownDocument = .welcome
    @State private var showFileImporter = false

    var body: some View {
        MarkdownWebView(html: document.html, baseURL: document.baseURL)
            .frame(minWidth: 600, minHeight: 400)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                guard let provider = providers.first else { return false }
                _ = provider.loadObject(ofClass: URL.self) { url, _ in
                    if let url = url {
                        DispatchQueue.main.async {
                            openFile(url)
                        }
                    }
                }
                return true
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [
                    UTType(filenameExtension: "md") ?? .plainText,
                    UTType(filenameExtension: "markdown") ?? .plainText,
                    .plainText,
                ],
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    openFile(url)
                }
            }
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button("Open...") {
                        showFileImporter = true
                    }
                    .keyboardShortcut("o", modifiers: .command)
                }
            }
            .navigationTitle(document.title)
            .onReceive(appDelegate.$fileToOpen.compactMap { $0 }) { url in
                openFile(url)
                // Reset AFTER consuming. compactMap above filters the nil
                // we set here, so onReceive doesn't fire again.
                appDelegate.fileToOpen = nil
            }
    }

    private func openFile(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        let newDocument: MarkdownDocument
        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let html = renderMarkdown(markdown)
            newDocument = MarkdownDocument(
                html: wrapHTMLPage(body: html),
                baseURL: url.deletingLastPathComponent(),
                title: shortenedPath(url.path)
            )
        } catch {
            newDocument = MarkdownDocument(
                html: wrapHTMLPage(body: "<p style='color:red'>Error reading file: \(error.localizedDescription)</p>"),
                baseURL: nil,
                title: "Markviewz"
            )
        }

        // Single atomic state write — SwiftUI rebuilds the view once,
        // MarkdownWebView.updateNSView loads the content once.
        document = newDocument

        // Dock tooltip shows just the filename
        DispatchQueue.main.async {
            NSApp.windows.first?.miniwindowTitle = url.lastPathComponent
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

    // Keep first component and last two path components, join with ellipsis
    let components = display.components(separatedBy: "/").filter { !$0.isEmpty }
    guard components.count > 3 else { return display }

    let prefix = components[0] == "~" ? "~" : "/" + components[0]
    let suffix = components.suffix(2).joined(separator: "/")
    return prefix + "/\u{2026}/" + suffix
}

private let welcomeHTML = """
<div style="text-align: center; margin-top: 100px; opacity: 0.5;">
    <h1>Markviewz</h1>
    <p>Open a Markdown file to get started</p>
    <p style="font-size: 14px;">File → Open (⌘O) or drag a .md file here</p>
</div>
"""
