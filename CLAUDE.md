# Markviewz — Project Guide

## What is this?

A native macOS markdown viewer app. SwiftUI + WKWebView. Read-only — no editing.

## Build & Test

```bash
swift build              # debug
swift build -c release   # release
./install.sh             # build, install .app to /Applications, install CLI wrapper
```

No test suite yet. Manual testing: open a .md file, check rendering in light/dark mode.

## Architecture

- **MarkviewzApp.swift** — App entry point, AppDelegate for file-open handling, print support
- **ContentView.swift** — Main view, file opening logic, drag-and-drop, file importer
- **MarkdownRenderer.swift** — cmark-gfm wrapper, frontmatter extraction, markdown-to-HTML
- **MarkdownWebView.swift** — NSViewRepresentable wrapping WKWebView, local file loading
- **Styles.swift** — CSS for GitHub-style markdown rendering, dark mode, frontmatter

## Key Conventions

- Keep it lightweight — no unnecessary dependencies
- CSS lives in Styles.swift as Swift string constants
- Markdown rendering uses cmark-gfm C library via Swift Package Manager
- The CLI `markviewz` is a bash wrapper using `open -a Markviewz` (not a symlink) to reuse the running instance
- YAML frontmatter is extracted before rendering and shown in a collapsible `<details>` block

## Git Workflow

- **Never commit directly to main** — use feature/bugfix branches off develop
- Every change needs a GitHub issue and a PR
- Branch naming: `feature/*`, `bugfix/*`, `release/*`, `hotfix/*`
- PRs target `develop`, releases merge to `main`

## Quality Process

Before finalizing changes:
1. Run `/simplify` and loop until no substantial improvements remain
2. Ensure `swift build` passes cleanly
