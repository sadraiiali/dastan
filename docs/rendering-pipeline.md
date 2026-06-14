# Rendering pipeline

This document explains how MarkViewer turns a Markdown file into something you see on screen.

## End-to-end flow

```text
┌─────────────────────────────────────────────────────────────────┐
│ 0. Startup                                                      │
│    FontConfig.setup_bundled_fonts() → FONTCONFIG_FILE           │
│    src/main.vala, src/font_config.vala                          │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. CLI                                                          │
│    markviewer test/test-showcase.md                             │
│    src/application.vala → opens MarkViewer.Window               │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Read file                                                    │
│    FileUtils.get_contents(path) → string                        │
│    src/window.vala → open_file()                                │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Preprocess                                                   │
│    protect math → normalize blockquote lists → list digits      │
│    MarkdownPreprocessor.preprocess()                            │
│    src/markdown_preprocessor.vala, src/math_registry.vala      │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Parse                                                        │
│    cmark-gfm → AST (tree of nodes)                              │
│    GFM extensions: table, strikethrough, autolink,            │
│    tagfilter, tasklist                                          │
│    src/markdown_renderer.vala                                   │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 5. Render widgets                                               │
│    Walk AST → Gtk.Label, Gtk.TextView, Gtk.Grid, Gtk.Box, …     │
│    Math placeholders → Gtk.Label (monospace LaTeX source)     │
│    src/markdown_renderer.vala, src/math_widget.vala             │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 6. Layout in window                                             │
│    Adw.Clamp → Gtk.ScrolledWindow → Adw.ToolbarView             │
│    src/window.vala                                              │
└────────────────────────────┬────────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│ 7. Draw                                                         │
│    GTK + Libadwaita paint widgets using the system theme        │
└─────────────────────────────────────────────────────────────────┘
```

## Step 0: Font setup

Before GTK initializes, `main.vala` calls `FontConfig.setup_bundled_fonts()`. If `FONTCONFIG_FILE` is not already set in the environment, it points fontconfig at the generated `build/markviewer-fonts.conf`, which adds `assets/fonts/` (bundled Shabnam) to the font search path.

`make run` and `make debug` set `FONTCONFIG_FILE` explicitly so fonts work even if startup order differs.

## Step 1: Application startup

`src/main.vala` creates `MarkViewer.Application`. When you pass a file path:

1. `application.vala` parses command-line arguments.
2. It creates `MarkViewer.Window`.
3. It calls `window.open_file(path)`.
4. It calls `window.present()` to show the window.

If no file is given, the window opens with a short usage hint.

## Step 2: Reading the file

`window.vala` resolves the path (absolute or relative to the current working directory), checks that the file exists, and reads the full contents into memory as a string.

## Step 3: Preprocessing

Before parsing, `MarkdownPreprocessor` runs three stages in order:

1. **Math protection** — LaTeX spans are replaced with opaque placeholders and stored in `MathRegistry`. Fenced code blocks are skipped so `` `$x$` `` inside code stays literal.
2. **Blockquote list normalization** — `> --` becomes `> -`.
3. **List digit normalization** — Persian/Arabic digits in ordered-list markers become ASCII.

See [Preprocessing](preprocessing.md).

## Step 4: Parsing

`MarkdownRenderer.render()` creates a cmark-gfm parser and attaches GFM syntax extensions. Without this step, tables and other GFM features would appear as plain paragraphs (for example `|Platform|Status|Notes|` as literal text).

The parser returns a root `document` node. That node and its children form the **parse tree** (AST). See [Parse tree (AST)](parse-tree.md).

Math placeholders survive parsing as plain text nodes inside paragraphs or as standalone paragraph blocks.

## Step 5: Widget creation

The renderer walks the tree recursively:

- For each **block** node (heading, paragraph, list, table, …), it creates a GTK widget.
- For **inline** nodes inside paragraphs (bold, links, code), it builds a Pango markup string on a single `Gtk.Label`.
- For **math placeholders**, it calls `MathWidget` to create monospace labels showing the LaTeX source.

See [Widget mapping](widget-mapping.md) for the full table.

The result is one root `Gtk.Box` with CSS class `markdown-body`, containing all block widgets stacked vertically.

### Math display

`MathWidget` does not typeset formulas. Block math is a centered `Gtk.Label` with class `md-math-source`. Inline math inside a paragraph is rendered with `<tt>` spans in Pango markup on a single label.

## Step 6: Window layout

`window.vala` wraps the rendered content:

```text
Adw.ApplicationWindow
└── Adw.ToolbarView
    ├── Adw.HeaderBar          (filename, settings, zoom)
    └── Gtk.ScrolledWindow     (vertical scroll)
        └── Adw.Clamp          (max width ~31.25 rem, centered)
            └── Gtk.Box        (markdown-body — all content)
```

`Adw.Clamp` keeps the reading column narrow and centered on wide screens. On narrow windows it shrinks with the window.

Relevant code in `window.vala`:

```vala
_scrolled.child = wrap_content (MarkViewer.MarkdownRenderer.render (contents, _font_scale));
```

Zoom changes re-render the document with an updated `--md-scale` CSS variable.

## Step 7: Painting

GTK calculates sizes, wraps text in labels, and draws widgets. Libadwaita applies your system light/dark theme. `assets/markviewer.css` adds typography and spacing via GTK’s CSS engine (not browser CSS).

## Why not HTML?

An HTML pipeline would look like:

```text
Markdown → HTML string → WebView → screen
```

MarkViewer instead uses:

```text
Markdown → AST → GTK widgets → screen
```

Benefits:

- Native look and feel on GNOME/GTK desktops
- No embedded browser dependency
- Direct control over RTL, tables, and code blocks per widget
- Small dependency footprint (GTK + Libadwaita + cmark-gfm only)

Trade-off: math is shown as LaTeX source, not typeset output. Some Markdown/HTML features remain harder without a browser engine.