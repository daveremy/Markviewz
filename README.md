# Markviewz

A lightweight, native macOS markdown viewer built for the AI-assisted development workflow.

## The Problem

CLI-based AI assistants (Claude Code, Codex, Aider, etc.) generate and work with `.md` files constantly — README files, documentation, changelogs, specs, reports. But reading raw markdown in the terminal is painful, and most markdown apps are heavyweight editors when all you need is a *viewer*.

## The Solution

Markviewz is a read-only markdown viewer that stays out of your way. Open a file from the terminal, read it with proper formatting, get back to work.

```bash
markviewz README.md
```

That's it. No editing, no bloat, no Electron. Just a native Mac app that renders your markdown beautifully.

## Features

- **GitHub-flavored markdown** — tables, task lists, strikethrough, autolinks
- **YAML frontmatter** — collapsed by default, click to expand
- **Dark mode** — follows system automatically
- **Local images** — relative image paths just work
- **Print support** — Cmd+P to print or export to PDF
- **Multiple open methods** — CLI, Cmd+O, drag-and-drop, Finder, `open -a`
- **Single instance** — opening a new file reuses the running app and brings it to front
- **GitHub-style typography** — clean, readable CSS

## Install

### Claude Code Plugin (recommended)

If you use [Claude Code](https://claude.com/claude-code), install Markviewz as a plugin to get the `/markviewz` skill:

```
/plugin marketplace add daveremy/claude-plugins
/plugin install markviewz@daveremy-plugins
```

Or install directly from this repo's marketplace:

```
/plugin marketplace add daveremy/Markviewz
/plugin install markviewz@markviewz
```

Then ask Claude to "show me the README" or use `/markviewz README.md`. If the binary isn't installed yet, Claude will guide you through the install.

### Gemini CLI Extension

If you use [Gemini CLI](https://github.com/google-gemini/gemini-cli), install the extension:

```
gemini extensions install https://github.com/daveremy/Markviewz.git
```

### Codex CLI Skill

If you use [Codex CLI](https://github.com/openai/codex), ask Codex to install the skill:

```
install the markviewz skill from daveremy/Markviewz at path codex/markviewz
```

### npm

Requires macOS 14+ and Swift 5.9+.

```bash
npx -y markviewz
```

This clones the repo, builds a release binary, creates `Markviewz.app` in `/Applications`, and installs a `markviewz` CLI wrapper.

### Manual Install

```bash
git clone https://github.com/daveremy/Markviewz.git
cd Markviewz
./install.sh
```

## Usage

```bash
# From Claude Code
/markviewz README.md

# From the terminal (reuses running instance)
markviewz notes.md

# Or use macOS open command
open -a Markviewz spec.md

# Launch and use Cmd+O to browse
markviewz
```

You can also drag and drop `.md` files onto the window.

## Building from Source

```bash
swift build              # debug build
swift build -c release   # optimized release build
swift test               # run tests (when available)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute, our git workflow, and coding standards.

## License

[MIT](LICENSE)
