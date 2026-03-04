# Markviewz

A simple, native macOS markdown viewer. No editing, no bloat — just clean, readable markdown.

Built with SwiftUI and WKWebView. Renders GitHub-flavored markdown with automatic dark mode support.

## Why?

MacDown is deprecated. Most markdown apps are editors. Sometimes you just want to *read* a `.md` file with nice formatting.

## Install

Requires macOS 14+ and Swift 5.9+.

```bash
git clone https://github.com/YOUR_USERNAME/Markviewz.git
cd Markviewz
swift build -c release
cp .build/release/Markviewz /usr/local/bin/markviewz
```

## Usage

```bash
# Open a file directly
markviewz README.md

# Or launch and use File > Open (Cmd+O)
markviewz
```

You can also drag and drop `.md` files onto the window.

## Features

- GitHub-flavored markdown (tables, task lists, strikethrough, autolinks)
- GitHub-style CSS typography
- Dark mode (follows system automatically)
- Open files via CLI argument, Cmd+O, or drag-and-drop
- Lightweight — no Electron, no web server, just a native Mac app

## Building from source

```bash
swift build          # debug build
swift build -c release   # optimized build
swift run README.md  # build and open a file
```

## License

MIT
