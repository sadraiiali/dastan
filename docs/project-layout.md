# Project layout

```text
markviewer/
├── Makefile                      # Convenience targets (setup, build, run, clean)
├── README.md                     # Quick start and feature summary
├── meson.build                   # Main build definition
├── LICENSE                       # AGPL-3.0
├── .gitignore                    # Build outputs, wraps, local clones, tree dumps
├── test/
│   └── test-showcase.md          # Large manual test document
├── docs/                         # Detailed documentation (this folder)
│
├── src/
│   ├── main.vala                 # Entry point; calls FontConfig.setup_bundled_fonts()
│   ├── application.vala          # CLI and window lifecycle
│   ├── window.vala               # UI shell, zoom, scrolling, Adw.Clamp
│   ├── font_config.vala          # FONTCONFIG_FILE for bundled Shabnam
│   ├── markdown_renderer.vala    # cmark-gfm → GTK widgets
│   ├── markdown_preprocessor.vala
│   ├── math_registry.vala        # LaTeX placeholder IDs during preprocessing
│   ├── math_widget.vala          # Native LaTeX source labels
│   ├── tree_dumper.vala          # AST + direction YAML dumper (dump-tree)
│   ├── config.vala.in            # Template for DATA_DIR and FONTS_CONF paths
│   └── vapi/
│       └── cmark-gfm.vapi        # Vala bindings for the parser
│
├── assets/
│   ├── markviewer.css            # Active GTK stylesheet
│   ├── markviewer-fonts.conf.in  # Fontconfig template for bundled fonts
│   └── fonts/                    # Shabnam (woff2 + ttf)
│
├── subprojects/
│   ├── cmark-gfm.wrap            # Wrap file for vendored parser (tracked)
│   ├── .wraplock                 # Meson wrap lock (tracked)
│   └── cmark-gfm/                # Full cmark-gfm source (gitignored checkout)
│
├── context/                      # Local reference clones (gitignored)
├── external/                     # Local vendored checkouts (gitignored)
│
└── build/                        # Meson build directory (gitignored)
    ├── markviewer                # Main application binary
    ├── dump-tree                 # AST dumper binary
    ├── config.vala               # Generated from config.vala.in
    └── markviewer-fonts.conf     # Generated from markviewer-fonts.conf.in
```

## Source responsibilities

### `src/main.vala`

Creates `MarkViewer.Application` and runs the GLib main loop. Calls `FontConfig.setup_bundled_fonts()` before GTK initializes when `FONTCONFIG_FILE` is not already set.

### `src/application.vala`

- Handles `markviewer <file.md>` on the command line.
- Creates the window, opens the file, presents the window.
- Prints usage when no file is provided.

### `src/window.vala`

- Builds `Adw.ToolbarView` + `Gtk.ScrolledWindow` + `Adw.Clamp`.
- Reads the Markdown file from disk.
- Calls `MarkdownRenderer.render()` and displays the result.
- Loads `assets/markviewer.css`.
- Provides zoom controls (settings dialog, Ctrl+scroll, Ctrl+/-).

### `src/font_config.vala`

Sets `FONTCONFIG_FILE` to the generated `markviewer-fonts.conf` so bundled Shabnam in `assets/fonts/` is available without a system install. `make run` and `make debug` set this variable explicitly.

### `src/markdown_renderer.vala`

- Preprocesses and parses Markdown.
- Attaches GFM extensions to the parser.
- Walks the AST and returns a `Gtk.Box` widget tree.
- Delegates math placeholders to `MathWidget`.

### `src/markdown_preprocessor.vala`

- Protects LaTeX math spans with placeholders before other transforms.
- Normalizes blockquote list markers (`> --` → `> -`).
- Converts Persian/Arabic list digits to ASCII.

### `src/math_registry.vala` / `src/math_widget.vala`

- `MathRegistry` stores LaTeX extracted during preprocessing.
- `MathWidget` renders formulas as monospace `Gtk.Label` widgets showing the LaTeX source.

### `src/tree_dumper.vala`

Standalone AST walker with per-node direction metadata. Built as `dump-tree` (no GTK dependency).

### `assets/markviewer.css`

GTK stylesheet for typography, blockquotes, lists, code, tables, and math source blocks.

### `src/vapi/cmark-gfm.vapi`

Declares cmark-gfm C functions for Vala (`parser_new`, `node_get_type_string`, extension helpers, etc.). Passed to the compiler via `--vapidir` in `meson.build`.

### `subprojects/cmark-gfm/`

Parser library checkout fetched by Meson wrap. Built as a static library and linked into `markviewer` and `dump-tree`.

## Generated files

| Path | Purpose |
|------|---------|
| `build/` | Meson/Ninja output |
| `build/config.vala` | Generated from `config.vala.in` with `DATA_DIR` and `FONTS_CONF` |
| `build/markviewer-fonts.conf` | Generated from `assets/markviewer-fonts.conf.in` with `FONTS_DIR` |
| `build/compile_commands.json` | For IDE/clang tooling (symlink at repo root is gitignored) |
| `*-tree.yml` | AST dumps from `make tree` (gitignored) |

Do not commit `build/`, `subprojects/cmark-gfm/`, `context/`, `external/`, or `*-tree.yml` to version control.

## Version control (`.gitignore`)

| Ignored path | Reason |
|--------------|--------|
| `/build/`, `/build-*/` | Meson/Ninja artifacts |
| `/subprojects/cmark-gfm/` | Wrap-fetched parser source |
| `/context/`, `/external/` | Local reference or vendored trees |
| `*-tree.yml`, `*-tree.yaml` | Generated AST dumps |
| `/compile_commands.json` | Optional root symlink for clangd |
| `.vscode/`, `.idea/`, swap files, `.DS_Store` | Editor and OS noise |

Tracked wrap metadata: `subprojects/cmark-gfm.wrap` and `subprojects/.wraplock`.

## Related documentation

- [Overview](overview.md)
- [Rendering pipeline](rendering-pipeline.md)
- [Build and development](build-and-development.md)