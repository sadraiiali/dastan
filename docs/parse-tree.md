# Parse tree (AST)

After preprocessing, cmark-gfm parses Markdown into an **abstract syntax tree** (AST). MarkViewer walks this tree to build the UI.

The AST is **not HTML**. It is a tree of typed nodes such as `heading`, `paragraph`, `table`, and `text`.

## Example

For this Markdown:

```markdown
## DuckDuckGo APIs

| Platform | Status |
|----------|--------|
| **SerpAPI** | Available |
```

The tree looks conceptually like:

```text
document
├── heading [level=2]
│   └── text "DuckDuckGo APIs"
└── table
    ├── table_header
    │   ├── table_cell → text "Platform"
    │   └── table_cell → text "Status"
    └── table_row
        ├── table_cell → strong "SerpAPI"
        └── table_cell → text "Available"
```

## Math placeholders in the tree

Preprocessing replaces LaTeX with opaque placeholders before parsing. In the AST they appear as ordinary `text` nodes, for example:

```text
paragraph
  text "⟦INLINEMATH:0⟧"
```

or a standalone block:

```text
paragraph
  text "⟦BLOCKMATH:1⟧"
```

`markdown_renderer.vala` detects these strings and routes them to `MathWidget` instead of drawing a plain label. The original LaTeX is looked up from `MathRegistry` by ID.

## Common node types

| Node type | Meaning |
|-----------|---------|
| `document` | Root of the file |
| `heading` | `#` … `######` heading |
| `paragraph` | Normal text block |
| `text` | Literal characters inside a paragraph |
| `emph` | `*italic*` |
| `strong` | `**bold**` |
| `code` | `` `inline code` `` |
| `link` | `[label](url)` |
| `softbreak` / `linebreak` | Line breaks inside a paragraph |
| `list` / `item` | Bullet or ordered lists |
| `block_quote` | `>` quoted block |
| `code_block` | Fenced ``` code |
| `table` | GFM table |
| `table_header` | First header row |
| `table_row` | Body row |
| `table_cell` | One cell |
| `thematic_break` | `---` horizontal rule |

## GFM extensions

MarkViewer attaches these extensions to the parser before `parser_feed()`:

| Extension | Purpose |
|-----------|---------|
| `table` | Pipe tables |
| `strikethrough` | `~~text~~` |
| `autolink` | URLs and emails auto-linked |
| `tagfilter` | Strip unsafe HTML tags |
| `tasklist` | `- [ ]` / `- [x]` checkboxes |

Registration alone is not enough — each extension must be **attached** to the parser instance in `attach_gfm_extensions()`.

## Nesting and CommonMark rules

How deeply nodes nest depends on **blank lines** and CommonMark rules in your source file.

If blocks are separated by single newlines instead of blank lines, cmark may nest paragraphs, lists, and blockquotes inside earlier blocks. That produces a very deep tree even when the rendered document looks like separate sections.

When debugging a complex note (for example an Obsidian export), inspect the tree to see whether structure issues come from the Markdown source or from the renderer.

## Inspecting the tree

### dump-tree (recommended)

MarkViewer ships `dump-tree`, built from `src/tree_dumper.vala`. It annotates each node with `ltr` / `rtl` / `mixed` direction metadata and writes YAML.

```bash
make tree FILE=test-showcase.md OUT=test-showcase-tree.yml
```

Output files matching `*-tree.yml` are gitignored.

For UTF-8 output (YAML tools):

```bash
./build/dump-tree --utf8 input.md output.yml
```

See [Direction in the AST](direction-in-ast.md).

### cmark-gfm XML

You can also dump the AST with cmark-gfm’s XML output:

```bash
# Conceptual — use cmark-gfm CLI if available:
cmark-gfm --extension table --to xml yourfile.md
```

A text tree dump shows `ENTER` events with indentation, one node per line:

```text
document
  heading [level=2]
    text "Title"
  paragraph
    text "Hello "
    link url="https://example.com"
      text "world"
```

## From tree to screen

MarkViewer does not serialize the tree to HTML. It calls `render_block()` / `render_blocks()` for each node and appends GTK widgets to a parent `Gtk.Box`. Math placeholders are intercepted before generic text rendering.

See [Widget mapping](widget-mapping.md) for the exact mapping table.