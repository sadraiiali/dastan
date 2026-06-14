# Styling and layout

MarkViewer styles content with **GTK CSS** (`assets/markviewer.css`) and **widget properties** in Vala. This is not browser CSS.

## Reading column layout

Wide windows use a centered column with a maximum width of about **31.25 rem** (512 px at the default scale).

This is handled by `Adw.Clamp` in `src/window.vala`:

```vala
return new Adw.Clamp () {
    maximum_size = rem_to_layout_units (CONTENT_MAX_WIDTH_REM),
    tightening_threshold = rem_to_layout_units (CONTENT_MAX_WIDTH_REM),
    margin_top = 24,
    margin_bottom = 24,
    margin_start = 24,
    margin_end = 24,
    child = widget,
};
```

`Adw.Clamp` is preferred over CSS `max-width` because GTK’s CSS parser does not support `max-width` or `width: 100%`.

## Stylesheet loading

On window construction, `load_styles()` reads `assets/markviewer.css` and registers it application-wide:

```vala
var provider = new Gtk.CssProvider ();
provider.load_from_path (css_path);
Gtk.StyleContext.add_provider_for_display (display, provider, APPLICATION);
```

The path comes from `Config.DATA_DIR`, set at build time in `meson.build` (points at the `assets/` directory).

## Zoom / font scale

The header **View settings** dialog and keyboard shortcuts (Ctrl+/-, Ctrl+scroll) adjust a document-wide scale factor. `window.vala` injects a high-priority CSS provider:

```css
.markdown-body, .md-content-column { --md-scale: 1.0000; }
```

Headings and body text scale with `--md-scale`. Math source labels use the same variable via `.md-math-source`.

## CSS classes

| Class | Applied to | Purpose |
|-------|------------|-----------|
| `markdown-body` | Root content box | Base font stack |
| `md-empty` | Empty-state label | Muted hint text |
| `md-h1` … `md-h6` | Heading labels | Size and weight |
| `md-paragraph` | Body labels | Line height |
| `md-blockquote` | Blockquote box | Border and background |
| `md-list` | List container | Vertical spacing |
| `md-list-item` | List row | Row layout |
| `md-list-marker` | Bullet/number label | Marker column |
| `md-code-block` | Code `TextView` | Monospace background |
| `md-table-scroll` | Table scroller | Margins |
| `md-table-cell` | Table cell box | Padding and border |
| `md-table-header` | Header cells | Bold, background |
| `md-math` | Math label | Base math spacing |
| `md-math-block` | Display-mode math | Centered block with subtle background |
| `md-math-paragraph` | Inline-math paragraph | Mixed text + formulas |
| `md-math-source` | Math labels | Monospace LaTeX source |
| `has-rtl` | Root box when doc contains RTL | Marker class for mixed docs |

## GTK CSS limitations

GTK 4’s CSS engine supports a **subset** of web CSS. Properties that work in browsers but **fail in GTK** include:

- `max-width`, `width` (percentage)
- `direction`
- `margin-start`, `margin-end` (use `margin-left` / `margin-right` with `:dir(rtl)` overrides)
- `border-start-width`, `border-end-width` (use `border-left` / `border-right`)
- `align-items`, `flex`, `grid` layout properties
- `min-width: max-content`

If you see warnings like:

```text
Theme parser error: markviewer.css: No property named "max-width"
```

remove or replace those properties with GTK-supported alternatives or Vala widget properties.

## Blockquote borders (RTL)

Blockquotes use physical borders with an RTL override:

```css
.md-blockquote {
  border-left-width: 3px;
  border-left-color: alpha(currentColor, 0.25);
}

.md-blockquote:dir(rtl) {
  border-left-width: 0;
  border-right-width: 3px;
  border-right-color: alpha(currentColor, 0.25);
}
```

## Typography and bundled fonts

### Fontconfig

Meson generates `build/markviewer-fonts.conf` from `assets/markviewer-fonts.conf.in`. It includes the system fontconfig and adds `assets/fonts/` so bundled **Shabnam** (woff2 and ttf) is available without a package install.

`make run` sets `FONTCONFIG_FILE` to that generated file. `src/font_config.vala` sets the same variable at startup when it is unset.

### CSS font stack

The font stack in `markdown-body` prioritizes Persian and Arabic faces:

- Shabnam (bundled), Vazirmatn, IRANSansWeb, IBM Plex Sans Arabic, Noto Naskh Arabic, …

Code blocks and math source use **Noto Sans Mono** in Pango markup plus `Gtk.TextView.monospace = true` for fenced code.

## Theming

Light and dark appearance follow the system theme through Libadwaita. MarkViewer does not ship a separate dark CSS file; it uses `alpha(currentColor, …)` and theme-aware colors where possible.