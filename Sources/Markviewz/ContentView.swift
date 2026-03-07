import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var htmlContent: String = wrapHTMLPage(body: welcomeHTML)
    @State private var baseURL: URL?
    @State private var showFileImporter = false
    @State private var windowTitle = "Markviewz"

    var body: some View {
        MarkdownWebView(html: htmlContent, baseURL: baseURL)
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
            .navigationTitle(windowTitle)
            .onReceive(appDelegate.$fileToOpen) { url in
                if let url = url {
                    openFile(url)
                    appDelegate.fileToOpen = nil
                }
            }
    }

    private func openFile(_ url: URL) {
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing { url.stopAccessingSecurityScopedResource() }
        }

        do {
            let markdown = try String(contentsOf: url, encoding: .utf8)
            let html = renderMarkdown(markdown)
            htmlContent = wrapHTMLPage(body: html)
            baseURL = url.deletingLastPathComponent()
            windowTitle = shortenedPath(url.path)
        } catch {
            htmlContent = wrapHTMLPage(body: "<p style='color:red'>Error reading file: \(error.localizedDescription)</p>")
            windowTitle = "Markviewz"
        }

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
