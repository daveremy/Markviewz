import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var appDelegate: AppDelegate

    @State private var htmlContent: String = wrapHTMLPage(body: welcomeHTML)
    @State private var showFileImporter = false
    @State private var windowTitle = "Markviewz"

    var body: some View {
        MarkdownWebView(html: htmlContent)
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
            windowTitle = url.lastPathComponent
        } catch {
            htmlContent = wrapHTMLPage(body: "<p style='color:red'>Error reading file: \(error.localizedDescription)</p>")
            windowTitle = "Markviewz"
        }
    }
}

private let welcomeHTML = """
<div style="text-align: center; margin-top: 100px; opacity: 0.5;">
    <h1>Markviewz</h1>
    <p>Open a Markdown file to get started</p>
    <p style="font-size: 14px;">File → Open (⌘O) or drag a .md file here</p>
</div>
"""
