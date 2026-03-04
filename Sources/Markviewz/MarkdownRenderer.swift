import Foundation
import cmark_gfm
import cmark_gfm_extensions

func renderMarkdown(_ markdown: String) -> String {
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
    cmark_parser_feed(parser, markdown, markdown.utf8.count)
    guard let doc = cmark_parser_finish(parser) else {
        return "<p>Error: could not parse markdown</p>"
    }
    defer { cmark_node_free(doc) }

    // Render to HTML
    guard let htmlCString = cmark_render_html(doc, options, cmark_parser_get_syntax_extensions(parser)) else {
        return "<p>Error: could not render HTML</p>"
    }

    return String(cString: htmlCString)
}
