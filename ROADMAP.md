# Markviewz Roadmap

## v0.1 — MVP (current)
- [x] Render markdown files with GitHub-style CSS
- [x] GitHub-flavored markdown (tables, task lists, strikethrough, autolinks)
- [x] Open files via CLI argument (`markviewz file.md`)
- [x] Open files via Cmd+O file picker
- [x] Drag-and-drop support
- [x] Dark mode (auto-follows system)
- [x] Window title shows filename

## v0.2 — Polish
- [ ] Syntax highlighting for code blocks (highlight.js)
- [ ] Remember window size and position
- [ ] Scroll position preservation on window resize
- [ ] File > Recent Files menu
- [ ] Proper .app bundle (for Finder association and Dock icon)

## v0.3 — File watching
- [ ] Auto-reload when file changes on disk
- [ ] Preserve scroll position on reload
- [ ] Visual indicator when file is reloaded

## v0.4 — Navigation
- [ ] Table of contents sidebar (generated from headings)
- [ ] Cmd+F find in document
- [ ] Back/forward navigation between opened files
- [ ] Follow relative links to other `.md` files

## v0.5 — Multi-window
- [ ] Open multiple files in separate windows
- [ ] Tabs support
- [ ] Open a directory and browse `.md` files in sidebar

## Future ideas
- Homebrew formula for easy installation
- Print / export to PDF
- Custom CSS themes
- Mermaid diagram rendering
- LaTeX/math rendering (KaTeX)
- Keyboard-driven navigation (vim-style scrolling)
