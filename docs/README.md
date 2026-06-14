# MarkViewer Documentation

MarkViewer is a native GTK 4 Markdown viewer for Linux. It reads a `.md` file, parses it with [cmark-gfm](https://github.com/github/cmark-gfm), and draws the result with GTK widgets only — no browser engine and no WebView.

## Guides

| Document | What it covers |
|----------|----------------|
| [Overview](overview.md) | What MarkViewer is, what it is not, and the big picture |
| [Rendering pipeline](rendering-pipeline.md) | From file on disk to pixels on screen |
| [Parse tree (AST)](parse-tree.md) | How cmark-gfm structures Markdown and how to inspect it |
| [Direction in the AST](direction-in-ast.md) | Per-node `ltr`/`rtl` metadata and YAML dumps |
| [Widget mapping](widget-mapping.md) | Which GTK widget is created for each AST node |
| [Styling and layout](styling-and-layout.md) | CSS, `Adw.Clamp`, fonts, zoom, and GTK CSS limits |
| [RTL and typography](rtl-and-typography.md) | Arabic/Persian text, bundled fonts, and mixed documents |
| [Preprocessing](preprocessing.md) | Math protection and text fixes before parsing |
| [Build and development](build-and-development.md) | Makefile, Meson, fonts, and day-to-day workflow |
| [Project layout](project-layout.md) | Repository structure, generated files, and `.gitignore` |

## Quick answers

**Does MarkViewer render HTML?**  
No. It parses Markdown into a tree, then builds GTK widgets. Only a small subset of [Pango markup](https://docs.gtk.org/Pango/pango_markup.html) (`<b>`, `<i>`, `<tt>`, `<a>`) is used inside labels for inline formatting.

**Does MarkViewer use a WebView?**  
No. The entire UI is native GTK 4 + Libadwaita. There is no WebKitGTK, no KaTeX, and no embedded JavaScript runtime.

**How does math work?**  
LaTeX delimiters are recognized during preprocessing and shown as monospace source in `Gtk.Label` widgets. Formulas are not typeset.

**How does content appear on screen?**  
Widgets are stacked in a vertical `Gtk.Box`, placed inside `Adw.Clamp` (max width ~31.25 rem, centered), inside a `Gtk.ScrolledWindow`, inside an `Adw.ApplicationWindow`. GTK lays out and paints them using your desktop theme.

**Where is the main code?**

- `src/window.vala` — window shell, zoom, scrolling layout
- `src/markdown_renderer.vala` — AST walk and widget creation
- `src/markdown_preprocessor.vala` — math protection and pre-parse normalization
- `src/math_widget.vala` — native LaTeX source labels
- `src/font_config.vala` — bundled Shabnam via fontconfig
- `assets/markviewer.css` — application stylesheet

## See also

- [README.md](../README.md) — install, usage, and quick start
- [test/test-showcase.md](../test/test-showcase.md) — large mixed English/Farsi sample document
- [cmark-gfm specification](https://github.github.com/gfm/)