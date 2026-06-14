<div align="center">

<img src="assets/logo.jpg" alt="Dastan" width="80">

# Dastan

**A native GTK 4 Markdown viewer**

Dastan renders Markdown as native GTK widgets. It parses
[GitHub Flavored Markdown](https://github.github.com/gfm/) with
[cmark-gfm](https://github.com/github/cmark-gfm) and displays the result
without a WebView, browser engine, or embedded JavaScript runtime.

[Documentation](docs/README.md) · [Build Guide](docs/build-and-development.md) · [License](LICENSE)

</div>

---

## Overview

Dastan is a focused desktop Markdown viewer for Linux. It is designed for
fast, predictable reading of local `.md` files while keeping the rendering
stack fully native: Markdown is parsed into an AST and mapped directly to GTK 4
and Libadwaita widgets.

The project is especially attentive to mixed-direction documents, Persian and
Arabic typography, and clean Markdown presentation without relying on HTML
rendering.

## Features

- Native GTK 4 and Libadwaita interface
- GitHub Flavored Markdown parsing through vendored `cmark-gfm`
- Headings, paragraphs, emphasis, links, lists, blockquotes, code blocks,
  tables, task lists, and thematic breaks
- Right-to-left and mixed-direction text support
- Bundled Shabnam fonts through fontconfig for consistent Persian typography
- Native display of LaTeX math delimiters as readable monospace source
- AST inspection tool for debugging rendering and direction metadata
- No WebView, Chromium, WebKitGTK, KaTeX, MathJax, or browser runtime

## Quick start

```bash
git clone --recurse-submodules https://github.com/sadraiiali/dastan dastan
cd dastan
make init
make build
make run FILE=notes.md
# optional: sudo make install
```

`make build` automatically initializes the `cmark-gfm` submodule, prepares
reference context repositories, configures the build directory when needed,
and compiles the application.

```bash
dastan path/to/document.md
```

## Requirements

| Dependency | Minimum |
|------------|---------|
| Meson | 0.59 |
| Ninja | Recent version |
| Vala | System default |
| GCC or Clang | C11-capable compiler |
| GTK 4 | 4.12 |
| Libadwaita | 1.5 |

The Markdown parser is vendored under `external/cmark-gfm`; no system
`cmark-gfm` package is required.

### Arch Linux

```bash
sudo pacman -S meson ninja vala gcc gtk4 libadwaita
```

### Fedora

```bash
sudo dnf install meson ninja vala gcc gtk4-devel libadwaita-devel
```

### Debian / Ubuntu

```bash
sudo apt install meson ninja-build valac gcc libgtk-4-dev libadwaita-1-dev
```

## Usage

Run Dastan against any local Markdown file:

```bash
dastan README.md
```

During development, prefer the Makefile wrapper so the bundled fontconfig file
is set automatically:

```bash
make run FILE=test/test-showcase.md
```

To inspect the parsed Markdown tree and direction metadata:

```bash
make tree FILE=test/test-showcase.md OUT=test-showcase-tree.yml
```

## Development

Common targets:

| Target | Description |
|--------|-------------|
| `make help` | Show available commands |
| `make init` | Initialize submodules and reference context |
| `make build` | Configure if needed and compile |
| `make run FILE=doc.md` | Build and open a Markdown file |
| `make debug FILE=doc.md` | Run with GTK Inspector enabled |
| `make tree FILE=doc.md` | Dump the parsed AST to YAML |
| `make install` | Install the `dastan` executable and assets |
| `make clean` | Remove compiled objects |
| `make distclean` | Delete the build directory |

Manual Meson workflow:

```bash
meson setup build
meson compile -C build
FONTCONFIG_FILE=build/dastan-fonts.conf ./build/dastan README.md
```

## Architecture

Dastan follows a simple native rendering pipeline:

```text
Markdown file
  -> UTF-8 text
  -> preprocessing
  -> cmark-gfm parser and GFM extensions
  -> Markdown AST
  -> GTK widget tree
  -> Libadwaita application window
```

The core implementation lives in:

| Path | Purpose |
|------|---------|
| `src/application.vala` | Application startup and command-line handling |
| `src/window.vala` | Main window, scrolling layout, zoom, and styling |
| `src/markdown_renderer.vala` | AST traversal and GTK widget mapping |
| `src/markdown_preprocessor.vala` | Pre-parse Markdown normalization |
| `src/math_widget.vala` | Native rendering for math source blocks |
| `src/font_config.vala` | Bundled font configuration |
| `src/tree_dumper.vala` | AST and direction metadata export |

For deeper implementation notes, see the
[project documentation](docs/README.md).

## Project Status

Dastan is currently in beta and under active development. It is suitable for
testing and early use, but behavior, supported Markdown features, and internal
APIs may continue to change.

Dastan is a viewer, not an editor: files are opened from the command line and
are never modified by the application.

Images, raw HTML, footnotes, and typeset math are not rendered as rich UI yet.
See the documentation for the current rendering model and known limitations.

## License

Dastan is licensed under the
[GNU Affero General Public License v3.0 or later](LICENSE).