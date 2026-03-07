import Foundation

let markdownCSS = """
:root {
    color-scheme: light dark;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
    font-size: 16px;
    line-height: 1.6;
    color: #24292f;
    background-color: #ffffff;
    max-width: 860px;
    margin: 0 auto;
    padding: 32px 24px;
    word-wrap: break-word;
}

@media (prefers-color-scheme: dark) {
    body {
        color: #e6edf3;
        background-color: #0d1117;
    }
    a { color: #58a6ff; }
    code {
        background-color: rgba(110,118,129,0.4) !important;
    }
    pre {
        background-color: #161b22 !important;
        border-color: #30363d !important;
    }
    blockquote {
        border-left-color: #3b434b !important;
        color: #9198a1 !important;
    }
    table th, table td {
        border-color: #30363d !important;
    }
    table tr:nth-child(2n) {
        background-color: #161b22 !important;
    }
    hr {
        border-color: #21262d !important;
    }
    h1, h2 {
        border-bottom-color: #21262d !important;
    }
}

h1, h2, h3, h4, h5, h6 {
    margin-top: 24px;
    margin-bottom: 16px;
    font-weight: 600;
    line-height: 1.25;
}

h1 { font-size: 2em; padding-bottom: 0.3em; border-bottom: 1px solid #d1d9e0; }
h2 { font-size: 1.5em; padding-bottom: 0.3em; border-bottom: 1px solid #d1d9e0; }
h3 { font-size: 1.25em; }

p { margin-top: 0; margin-bottom: 16px; }

a { color: #0969da; text-decoration: none; }
a:hover { text-decoration: underline; }

code {
    padding: 0.2em 0.4em;
    margin: 0;
    font-size: 85%;
    background-color: rgba(175,184,193,0.2);
    border-radius: 6px;
    font-family: "SF Mono", SFMono-Regular, Consolas, "Liberation Mono", Menlo, monospace;
}

pre {
    padding: 16px;
    overflow: auto;
    font-size: 85%;
    line-height: 1.45;
    background-color: #f6f8fa;
    border-radius: 6px;
    border: 1px solid #d1d9e0;
    margin-bottom: 16px;
}

pre code {
    padding: 0;
    background-color: transparent;
    border-radius: 0;
    font-size: 100%;
}

blockquote {
    margin: 0 0 16px 0;
    padding: 0 1em;
    color: #59636e;
    border-left: 0.25em solid #d1d9e0;
}

ul, ol {
    margin-top: 0;
    margin-bottom: 16px;
    padding-left: 2em;
}

li + li { margin-top: 0.25em; }

table {
    border-spacing: 0;
    border-collapse: collapse;
    margin-bottom: 16px;
    display: block;
    width: max-content;
    max-width: 100%;
    overflow: auto;
}

table th, table td {
    padding: 6px 13px;
    border: 1px solid #d1d9e0;
}

table th { font-weight: 600; }

table tr:nth-child(2n) {
    background-color: #f6f8fa;
}

hr {
    height: 0.25em;
    padding: 0;
    margin: 24px 0;
    background-color: #d1d9e0;
    border: 0;
}

img {
    max-width: 100%;
    box-sizing: border-box;
}

strong { font-weight: 600; }

/* Collapsible frontmatter */
details.frontmatter {
    margin-bottom: 0;
    font-size: 13px;
    opacity: 0.6;
}
details.frontmatter summary {
    cursor: pointer;
    font-size: 12px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: #656d76;
    user-select: none;
}
details.frontmatter pre {
    margin-top: 8px;
    font-size: 12px;
    padding: 12px;
}
details.frontmatter + hr {
    margin-top: 12px;
}

/* Simple syntax highlighting */
.keyword { color: #cf222e; }
.string { color: #0a3069; }
.comment { color: #6e7781; }

@media (prefers-color-scheme: dark) {
    .keyword { color: #ff7b72; }
    .string { color: #a5d6ff; }
    .comment { color: #8b949e; }
}
"""

func wrapHTMLPage(body: String) -> String {
    return """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
    \(markdownCSS)
    </style>
    </head>
    <body>
    \(body)
    </body>
    </html>
    """
}
