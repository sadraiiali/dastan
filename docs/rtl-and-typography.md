# RTL and typography

MarkViewer targets mixed documents with English, Persian, and Arabic text.

## Detection

`contains_rtl()` in `markdown_renderer.vala` scans text for characters in Arabic Unicode ranges:

- `U+0600`–`U+06FF` (Arabic)
- `U+0750`–`U+077F` (Arabic Supplement)
- `U+08A0`–`U+08FF` (Arabic Extended-A)
- `U+FB50`–`U+FDFF` (Arabic Presentation Forms-A)
- `U+FE70`–`U+FEFF` (Arabic Presentation Forms-B)

If a block contains RTL characters, `apply_rtl_if_needed()` sets widget direction to RTL.

## Per-block direction

Direction is applied **per block** (paragraph, heading, list row, blockquote), not only once for the whole file.

This allows mixed documents:

- A Persian paragraph renders right-aligned.
- An English paragraph in the same file stays left-aligned.

For `Gtk.Label` in RTL blocks:

```vala
label.xalign = 1;
label.justify = Gtk.Justification.RIGHT;
```

For LTR labels:

```vala
label.xalign = 0;
label.justify = Gtk.Justification.LEFT;
```

Previously, labels always used `justify = LEFT`, which broke wrapped RTL text even when direction was RTL.

## Lists in RTL

List rows are horizontal `Gtk.Box` widgets. When direction is RTL:

- GTK mirrors child order: the marker appears on the right.
- CSS adjusts marker margins with `:dir(rtl)` on `.md-list-item`.

## Blockquotes in RTL

The blockquote container gets RTL direction when its text is RTL. CSS moves the accent bar from left to right using `.md-blockquote:dir(rtl)`.

## Code is always LTR

Source code, shell commands, and APIs are always shown left-to-right:

| Construct | LTR enforcement |
|-----------|-----------------|
| Fenced code block | `Gtk.TextView` + `apply_ltr()` + `justification = LEFT` |
| Inline `` `code` `` | `<tt>` in Pango markup (neutral direction inside label) |
| Tables | `apply_ltr()` on `Gtk.Grid` |
| Math source | `apply_ltr()` on math labels |

This matches common expectations for code and formulas in RTL documents.

## Persian ordered lists

Persian and Eastern Arabic digits in list markers (`۱.`, `۲.`) are normalized to ASCII digits (`1.`, `2.`) in preprocessing so cmark-gfm parses ordered lists correctly. See [Preprocessing](preprocessing.md).

## Fonts

### Bundled Shabnam

MarkViewer ships Shabnam in `assets/fonts/` (woff2 and ttf). At build time, Meson generates `build/markviewer-fonts.conf` from `assets/markviewer-fonts.conf.in`, which tells fontconfig to search that directory.

Use `make run` or set `FONTCONFIG_FILE` when invoking the binary directly:

```bash
FONTCONFIG_FILE=build/markviewer-fonts.conf ./build/markviewer notes.md
```

`src/font_config.vala` sets `FONTCONFIG_FILE` at startup when the variable is not already defined.

### CSS font stack

`assets/markviewer.css` sets a mixed-script stack on `.markdown-body`:

- Shabnam (bundled), Vazirmatn, IRANSansWeb, IBM Plex Sans Arabic, Noto Naskh Arabic, …

Additional Arabic-friendly fonts installed on the system are used automatically when listed in the stack. GTK falls back to `sans-serif` when none match.

### Monospace

Code blocks and math source prefer **Noto Sans Mono** in Pango markup. Install it on the system for best results, or rely on GTK’s generic monospace fallback.

## Document-level marker

If any RTL text exists in the document, the root `markdown-body` box receives CSS class `has-rtl`. This is a marker for styling hooks; child blocks still get their own direction.