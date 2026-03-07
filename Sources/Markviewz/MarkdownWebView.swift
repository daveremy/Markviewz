import SwiftUI
import WebKit

/// Shared reference to the current WKWebView for printing.
class WebViewStore: ObservableObject {
    static let shared = WebViewStore()
    weak var webView: WKWebView?
}

struct MarkdownWebView: NSViewRepresentable {
    let html: String
    var baseURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        WebViewStore.shared.webView = webView
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let loadKey = html + (baseURL?.absoluteString ?? "")
        guard loadKey != context.coordinator.lastLoadKey else { return }
        context.coordinator.lastLoadKey = loadKey

        if let baseURL = baseURL {
            // Write HTML to a dotfile alongside the markdown so WKWebView
            // can access local images via relative paths.
            let tempFile = baseURL.appendingPathComponent(".markviewz-preview.html")
            do {
                try html.write(to: tempFile, atomically: true, encoding: .utf8)
                webView.loadFileURL(tempFile, allowingReadAccessTo: baseURL)
            } catch {
                webView.loadHTMLString(html, baseURL: baseURL)
            }
        } else {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    class Coordinator {
        var lastLoadKey: String?
    }
}
