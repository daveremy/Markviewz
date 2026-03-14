---
name: markviewz
description: Open and view markdown files with Markviewz, a native macOS markdown viewer. Use when the user asks to view, show, preview, or open a .md or markdown file.
---

Open a markdown file in Markviewz for viewing.

Run: `markviewz $ARGUMENTS`

If the command fails because markviewz is not installed, tell the user to install it:

```bash
npx -y markviewz
```

If no file was specified, ask the user which markdown file they want to view.
