import SwiftUI
import WebKit
import AppKit

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
        webView.navigationDelegate = context.coordinator
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

    /// Intercepts navigation so external links open in the user's default
    /// browser instead of taking over the Markviewz window. Also opens
    /// other local markdown files in Markviewz itself (navigation within
    /// the viewer) by routing through the app delegate.
    class Coordinator: NSObject, WKNavigationDelegate {
        var lastLoadKey: String?

        func webView(_ webView: WKWebView,
                     decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }

            // Initial load of the rendered markdown file — allow.
            // We identify it by the .markviewz-preview.html filename.
            let isInitialLoad = navigationAction.navigationType == .other
                && url.isFileURL
                && url.lastPathComponent == ".markviewz-preview.html"
            if isInitialLoad {
                decisionHandler(.allow)
                return
            }

            // Local markdown files → route to Markviewz's own open handler
            // (will reuse-or-spawn window per AppDelegate policy).
            if url.isFileURL {
                let ext = url.pathExtension.lowercased()
                if ext == "md" || ext == "markdown" {
                    NSWorkspace.shared.open(
                        [url],
                        withApplicationAt: Bundle.main.bundleURL,
                        configuration: NSWorkspace.OpenConfiguration()
                    ) { _, _ in }
                    decisionHandler(.cancel)
                    return
                }
                // Non-markdown local file (e.g. image). Open in default app.
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }

            // Anything else (http, https, mailto, custom schemes) →
            // hand off to the default browser/mail client.
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        }
    }
}
