# Widget mapping

`src/markdown_renderer.vala` converts each AST node into GTK 4 widgets. This is the core of MarkViewer’s display logic.

## Block nodes

| AST node | GTK widget | CSS class | Notes |
|----------|------------|-----------|-------|
| `document` | `Gtk.Box` (vertical) | `markdown-body` | Root container for all blocks |
| `heading` | `Gtk.Label` | `md-h1` … `md-h6` | Math-only headings use `MathWidget` |
| `paragraph` | `Gtk.Label` | `md-paragraph` | Math placeholders → `MathWidget` |
| `block_quote` | `Gtk.Box` (vertical) | `md-blockquote` | Children rendered inside |
| `list` | `Gtk.Box` (vertical) | `md-list` | One row per `item` |
| `item` | `Gtk.Box` (horizontal) | `md-list-item` | Marker label + content box |
| `code_block` | `Gtk.TextView` in `Gtk.Box` | `md-code-block` | Monospace, read-only, always LTR |
| `table` | `Gtk.Grid` in `Gtk.ScrolledWindow` | `md-table`, `md-table-scroll` | Horizontal scroll for wide tables |
| `table_cell` | `Gtk.Box` (vertical) | `md-table-cell` | Header row uses `md-table-header` |
| `thematic_break` | `Gtk.Separator` | — | Horizontal line |
| `html_block` | `Gtk.Label` | `md-paragraph` | Raw HTML shown as plain text |

### Math blocks and paragraphs

During preprocessing, LaTeX is replaced with placeholders like `⟦BLOCKMATH:0⟧` and `⟦INLINEMATH:1⟧`. At render time:

| Placeholder kind | Widget | CSS class |
|------------------|--------|-----------|
| Block (`⟦BLOCKMATH:n⟧`) | `Gtk.Label` | `md-math`, `md-math-block`, `md-math-source` |
| Inline in paragraph | `Gtk.Label` (whole paragraph) | `md-math`, `md-math-paragraph`, `md-math-source` |

`MathWidget` shows the original LaTeX source in monospace. Block formulas are centered with a subtle background; inline math uses `<tt>` spans inside Pango markup.

Supported LaTeX delimiters are normalized in preprocessing: `$…$`, `$$…$$`, `\(...\)`, `\[...\]`.

### Tables

- First row with type `table_header` gets `md-table-header` on each cell.
- Body rows use type `table_row`.
- The grid is wrapped in a horizontal `Gtk.ScrolledWindow` when content is wide.
- Table layout is forced **LTR** even in RTL documents.

### Lists

- Ordered lists show `1.`, `2.`, … from the parser.
- Task list items show `☐` or `☑` when the tasklist extension marks them.
- Bullet lists use `•`.

### Code blocks

- Implemented as `Gtk.TextView`, not `Gtk.Label`, so multi-line code preserves formatting.
- Wrapped in a vertical `Gtk.Box` with direction set to LTR.
- `justification = LEFT` keeps lines left-aligned.
- Math delimiters inside fenced code are **not** preprocessed.

## Inline nodes (inside paragraphs and headings)

When a paragraph contains no math placeholders, inline nodes are converted to a **Pango markup string** on one `Gtk.Label`:

| AST node | Markup |
|----------|--------|
| `text` | Escaped plain text |
| `emph` | `<i>…</i>` |
| `strong` | `<b>…</b>` |
| `strikethrough` | `<s>…</s>` |
| `code` | `<tt>…</tt>` with `Noto Sans Mono` |
| `link` | `<a href="url">…</a>` |
| `image` | `<i>[alt text]</i>` (placeholder) |
| `softbreak` / `linebreak` | Newline |

**Important:** Gtk.Label supports [Pango markup](https://docs.gtk.org/Pango/pango_markup.html), not full HTML. Attributes like `class="…"` or `dir="ltr"` on `<span>` are not reliable and should be avoided.

Paragraphs that still contain inline-math placeholders bypass Pango markup for the whole paragraph and go through `MathWidget.make_inline_paragraph()`.

## RTL handling

For block-level widgets, if text contains Arabic or Persian characters, `apply_rtl_if_needed()` sets:

- `widget.direction = RTL`
- On labels: `xalign = 1`, `justify = RIGHT`

For labels without RTL characters, direction stays LTR even inside a mixed document.

Code blocks and tables always use `apply_ltr()`. Math source labels are always LTR.

Details: [RTL and typography](rtl-and-typography.md).

## Window shell (not from AST)

These widgets are created in `src/window.vala`, not from the parse tree:

| Widget | Role |
|--------|------|
| `Adw.ApplicationWindow` | Top-level window |
| `Adw.ToolbarView` | Header + content area |
| `Adw.HeaderBar` | Title, settings button |
| `Gtk.ScrolledWindow` | Scrollable content |
| `Adw.Clamp` | Max width ~31.25 rem, centered column |
| `Adw.Dialog` | View settings (zoom) |

## Visual hierarchy

```text
Adw.ApplicationWindow
└── Adw.ToolbarView
    ├── Adw.HeaderBar
    │   └── Gtk.Label (filename)
    └── Gtk.ScrolledWindow
        └── Adw.Clamp
            └── Gtk.Box.markdown-body
                ├── Gtk.Label          (heading)
                ├── Gtk.Label          (paragraph)
                ├── Gtk.Label          (block math source)
                ├── Gtk.Box.md-blockquote
                ├── Gtk.Box.md-list
                │   └── Gtk.Box.md-list-item
                ├── Gtk.Box → Gtk.TextView (code)
                └── Gtk.ScrolledWindow → Gtk.Grid (table)
```