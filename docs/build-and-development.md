# Build and development

## Requirements

| Dependency | Minimum version |
|------------|-----------------|
| Meson | 0.59 |
| Ninja | any recent |
| Vala | system default |
| GCC or Clang | C11 |
| GTK 4 | 4.12 |
| Libadwaita | 1.5 |

cmark-gfm and Lasem are vendored under `external/` — no system packages required for
the parser or math renderer. Lasem GObject enum sources are pre-generated in
`external/lasem-meson/generated/` so `glib-mkenums` is not needed for normal builds.
Install `glib2-devel` only when regenerating those files
(`python3 external/lasem-meson/generate-enums.py`).

Math rendering uses **bundled GUST Latin Modern** fonts (`data/fonts/math/`). Fontconfig
aliases map Lasem’s legacy `cmr10` / `cmsy10` names to those files — no LyX or TeX Live
font packages are required.

### Arch Linux

```bash
sudo pacman -S meson ninja vala gcc gtk4 libadwaita glib2-devel flex bison libxml2
```

### Fedora

```bash
sudo dnf install meson ninja vala gcc gtk4-devel libadwaita-devel flex bison libxml2-devel
```

### Debian / Ubuntu

```bash
sudo apt install meson ninja-build valac gcc libgtk-4-dev libadwaita-1-dev \
  libglib2.0-dev flex bison libxml2-dev
```

## Makefile targets

| Target | Description |
|--------|-------------|
| `make` / `make help` | List targets |
| `make setup` | `meson setup build` |
| `make build` | Compile (runs `meson compile` every time) |
| `make run FILE=doc.md` | Build and open a file (sets `FONTCONFIG_FILE`) |
| `make debug FILE=doc.md` | Run with GTK Inspector (sets `FONTCONFIG_FILE`) |
| `make clean` | Remove compiled objects, keep build config |
| `make distclean` | Delete the `build/` directory |
| `make tree FILE=doc.md OUT=tree.yml` | Dump AST with per-node direction to YAML |
| `make test` | Run unit tests under `xvfb-run` |
| `make reconfigure` | `meson setup build --wipe` and rebuild |

### Examples

```bash
make setup
make build
make run FILE=README.md
make run FILE=src/tests/test-showcase.md
make debug FILE=src/tests/test-showcase.md
make clean
make distclean
```

## Manual Meson build

```bash
meson setup build
meson compile -C build
FONTCONFIG_FILE=build/data/dastan-fonts.conf ./build/markviewer example.md
```

After changing `meson.build` or subproject wraps:

```bash
make reconfigure
```

## Bundled fonts

Meson generates `build/data/dastan-fonts.conf` from `data/fonts/dastan-fonts.conf.in`, pointing fontconfig at `data/fonts/` (Shabnam). The Makefile sets `FONTCONFIG_FILE` for `make run` and `make debug`.

When running `./build/markviewer` directly, either export `FONTCONFIG_FILE` or rely on system-installed Persian fonts. `src/font_config.vala` also sets `FONTCONFIG_FILE` at startup if the variable is unset.

## Development workflow

Typical loop:

```bash
make build
make run FILE=src/tests/test-showcase.md
```

Source files:

| File | Role |
|------|------|
| `src/main.vala` | Entry point, fontconfig bootstrap |
| `src/application.vala` | CLI handling |
| `src/window.vala` | Window, scroll, clamp, zoom, stylesheet |
| `src/font_config.vala` | Bundled fontconfig integration |
| `src/markdown_renderer.vala` | Parse + widget mapping |
| `src/markdown_preprocessor.vala` | Math protection + pre-parse fixes |
| `src/math_registry.vala` | LaTeX placeholder storage |
| `src/markdown/math/` | Lasem-backed math rendering and fallback labels |
| `src/tree_dumper.vala` | AST YAML dumper (`dump-tree`) |
| `data/markviewer.css` | GTK stylesheet |
| `data/fonts/dastan-fonts.conf.in` | Fontconfig template |
| `src/vapi/cmark-gfm.vapi` | Vala bindings for cmark-gfm |

Binaries:

| Binary | GTK | Purpose |
|--------|-----|---------|
| `build/markviewer` | yes | Main viewer |
| `build/dump-tree` | no | AST + direction YAML dump |

## IDE support

For clangd or other LSP tools, symlink the compile database from the build directory:

```bash
ln -sf build/compile_commands.json compile_commands.json
```

The root symlink is listed in `.gitignore`; the canonical file lives in `build/`.

## Debugging tips

### CSS parser warnings

If GTK prints `Theme parser error` for `markviewer.css`, the file uses unsupported properties. See [Styling and layout](styling-and-layout.md).

### Tables show as `|col|col|` text

Ensure GFM extensions are attached in `attach_gfm_extensions()` before `parser_feed()`.

### Math falls back to raw LaTeX

Lasem typesets supported formulas natively. Unsupported or invalid LaTeX is shown as
monospace source via `.md-math-source`. Computer Modern aliases are satisfied by the
bundled Latin Modern fonts shipped under `data/fonts/math/`.

### Portal warnings

Messages about `org.freedesktop.portal.Desktop` come from the desktop environment (xdg-desktop-portal). They are usually harmless when the portal service is not running.

### Inspect the parse tree

```bash
make tree FILE=src/tests/test-showcase.md OUT=test-showcase-tree.yml
```

Or run `dump-tree` directly. See [Parse tree (AST)](parse-tree.md) and [Direction in the AST](direction-in-ast.md).

### Inspect widget layout

```bash
make debug FILE=src/tests/test-showcase.md
```

Opens the GTK Inspector alongside the window.

## Version

Project version is set in `meson.build` (`0.2.0` at time of writing).