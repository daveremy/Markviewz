import Foundation
import cmark_gfm
import cmark_gfm_extensions

func renderMarkdown(_ markdown: String) -> String {
    // Extract YAML frontmatter if present, render body only
    let (frontmatter, body) = extractFrontmatter(markdown)

    // Use cmark-gfm to convert markdown to HTML
    let options = CMARK_OPT_SMART | CMARK_OPT_UNSAFE

    // Register GFM extensions
    cmark_gfm_core_extensions_ensure_registered()

    guard let parser = cmark_parser_new(options) else {
        return "<p>Error: could not create parser</p>"
    }
    defer { cmark_parser_free(parser) }

    // Attach GFM extensions: tables, strikethrough, autolink, tagfilter, tasklist
    let extensionNames = ["table", "strikethrough", "autolink", "tagfilter", "tasklist"]
    for name in extensionNames {
        if let ext = cmark_find_syntax_extension(name) {
            cmark_parser_attach_syntax_extension(parser, ext)
        }
    }

    // Parse
    cmark_parser_feed(parser, body, body.utf8.count)
    guard let doc = cmark_parser_finish(parser) else {
        return "<p>Error: could not parse markdown</p>"
    }
    defer { cmark_node_free(doc) }

    // Render to HTML
    guard let htmlCString = cmark_render_html(doc, options, cmark_parser_get_syntax_extensions(parser)) else {
        return "<p>Error: could not render HTML</p>"
    }

    var html = ""

    // Add collapsible frontmatter if present
    if let fm = frontmatter {
        let escaped = fm
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        html += """
        <details class="frontmatter">
        <summary>frontmatter</summary>
        <pre><code>\(escaped)</code></pre>
        </details>
        <hr>
        """
    }

    html += String(cString: htmlCString)
    return html
}

/// Extract YAML frontmatter (between --- delimiters at start of file)
private func extractFrontmatter(_ markdown: String) -> (frontmatter: String?, body: String) {
    let lines = markdown.components(separatedBy: "\n")
    guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
        return (nil, markdown)
    }

    var closingIndex: Int?
    for i in 1..<lines.count {
        if lines[i].trimmingCharacters(in: .whitespaces) == "---" {
            closingIndex = i
            break
        }
    }

    guard let endIndex = closingIndex else {
        return (nil, markdown)
    }

    let frontmatter = lines[1..<endIndex].joined(separator: "\n")
    let body = lines[(endIndex + 1)...].joined(separator: "\n")
    return (frontmatter, body)
}
