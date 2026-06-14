# Overview

## What MarkViewer does

MarkViewer opens one Markdown file from the command line and shows it in a focused reading window:

```bash
make run FILE=README.md
# or
FONTCONFIG_FILE=build/markviewer-fonts.conf ./build/markviewer ~/notes/example.md
```

The app is built for a simple workflow: read, preprocess, parse, render natively, scroll.

## What MarkViewer does not do

- **No WebView** — no Chromium, WebKitGTK, or similar engines.
- **No HTML page** — the app never builds a `<html>` document or loads JavaScript assets.
- **No math typesetting** — LaTeX is shown as monospace source, not rendered formulas.
- **No editor** — it is a viewer only; files are not modified.
- **No vault or file browser** — you pass a path on the command line.

## Technology stack

| Layer | Technology |
|-------|------------|
| Language | Vala |
| UI toolkit | GTK 4 + Libadwaita |
| Markdown parser | cmark-gfm (Meson subproject via wrap) |
| Fonts | Bundled Shabnam via fontconfig (`markviewer-fonts.conf`) |
| Build system | Meson + Ninja |
| Convenience | Makefile wrappers |

## Supported Markdown features

Through cmark-gfm and its GFM extensions:

- Headings, paragraphs, emphasis, strikethrough
- Links and autolinks
- Bullet and ordered lists, including task lists
- Blockquotes
- Fenced code blocks
- Tables
- Thematic breaks (horizontal rules)
- LaTeX math delimiters (displayed as source, not typeset)

Features not rendered as rich UI today:

- Images (alt text is shown as `[alt]` in italics)
- Raw HTML blocks (shown as plain text)
- Footnotes
- Typeset math (KaTeX, MathJax, etc.)

## High-level data flow

```text
.md file
   → read as UTF-8 text
   → preprocess (math placeholders, Persian digits, blockquote lists)
   → cmark-gfm parser + GFM extensions
   → AST (parse tree)
   → walk tree, create GTK widgets
   → show in scrollable Libadwaita window
```

The next document, [Rendering pipeline](rendering-pipeline.md), walks through each step in detail.