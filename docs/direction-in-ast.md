# Direction in the parse tree

MarkViewer can annotate each AST node with a **text direction** (`ltr` or `rtl`) before rendering. This helps RTL support, debugging, and tooling.

## Is enriching the tree a good idea?

**Yes, for MarkViewer’s model.** A short summary:

| Benefit | Why it matters |
|---------|----------------|
| Explicit metadata | Direction is visible in dumps and tests, not hidden in render code |
| Same rules everywhere | Dumper, renderer, and future exporters share one decision per node |
| Easier debugging | Compare `test-showcase-tree.yml` with what you see on screen |
| Section-level RTL | Each paragraph, heading, or list item can carry its own direction |

**Caveats:**

- Direction is **inferred** from character ranges (Arabic/Persian script), not from HTML `dir="auto"` or locale headers.
- **Mixed lines** (English and Persian in one paragraph) are tagged `rtl` if any RTL character appears; Pango still handles mixed glyphs inside the line.
- **Code and tables** are always `ltr`, matching the renderer.
- The document root may be `mixed` when the file contains both RTL and LTR letter content.

MarkViewer today applies direction at **render time** (`apply_rtl_if_needed`). Enriching the tree is the natural next step if you want a dedicated layout pass:

```text
parse → annotate direction on nodes → render widgets
```

The `dump-tree` tool already implements the annotation rules for inspection.

## Direction rules

| Node kind | Direction |
|-----------|-----------|
| `document` | `ltr`, `rtl`, or `mixed` (summary of the whole file) |
| `code_block`, `table`, `table_*`, inline `code` | always `ltr` |
| Other nodes (heading, paragraph, list item, …) | `rtl` if plain text contains Arabic/Persian letters, else `ltr` |

Detection uses the same Unicode ranges as `markdown_renderer.vala`:

- `U+0600`–`U+06FF`, `U+0750`–`U+077F`, `U+08A0`–`U+08FF`, `U+FB50`–`U+FDFF`, `U+FE70`–`U+FEFF`

## YAML dump format

```yaml
source: "/path/to/file.md"
tree:
  type: document
  direction: mixed
  children:
    - type: heading
      direction: rtl
      level: 2
      text: |-
        عنوان
      children:
        - type: text
          direction: rtl
          text: |-
            عنوان
    - type: code_block
      direction: ltr
      info: "python"
      text: |-
        print('hi')
```

Long `text` fields are truncated to 120 characters with `…` for readability.

Output files default to **UTF-16LE with BOM** so Persian shows correctly in most editors (including Windows Notepad). Text uses YAML block literals (`|-`).

If you see `Ø³Øª` or `¬Ø³` garbage, the file is being opened as Latin-1 — reopen as UTF-16 or UTF-8.

For UTF-8 output (YAML tools): `./build/dump-tree --utf8 input.md output.yml`

## Generate a tree file

```bash
make tree FILE=test-showcase.md OUT=test-showcase-tree.yml
```

Or run the binary directly:

```bash
./build/dump-tree /path/to/file.md output.yml
./build/dump-tree --utf8 /path/to/file.md output.yml
```

Files matching `*-tree.yml` are listed in `.gitignore` and should not be committed.

Implementation: `src/tree_dumper.vala`, built as `dump-tree` (no GTK dependency).

## Related docs

- [RTL and typography](rtl-and-typography.md)
- [Parse tree (AST)](parse-tree.md)