# Markviewz

A simple, native macOS markdown viewer. No editing, no bloat — just clean, readable markdown.

Built with SwiftUI and WKWebView. Renders GitHub-flavored markdown with automatic dark mode support.

## Why?

MacDown is deprecated. Most markdown apps are editors. Sometimes you just want to *read* a `.md` file with nice formatting.

## Install

Requires macOS 14+ and Swift 5.9+.

```bash
git clone https://github.com/daveremy/Markviewz.git
cd Markviewz
./install.sh
```

This builds a release binary, creates `Markviewz.app` in `/Applications`, and installs a `markviewz` CLI command.

## Usage

```bash
# Open a file from the command line
open -a Markviewz README.md

# Or use the CLI shortcut
markviewz README.md

# Launch without a file, then use Cmd+O
open -a Markviewz
```

You can also drag and drop `.md` files onto the window.

## Features

- GitHub-flavored markdown (tables, task lists, strikethrough, autolinks)
- GitHub-style CSS typography
- Dark mode (follows system automatically)
- Open files via CLI, Cmd+O, drag-and-drop, or Finder
- Lightweight — no Electron, no web server, just a native Mac app

## Building from source

```bash
swift build              # debug build
swift build -c release   # optimized release build
```

## License

MIT
