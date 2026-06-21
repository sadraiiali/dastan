# Contributing to Dastan

Thank you for your interest in contributing to Dastan.

Dastan is a native GTK 4 Markdown viewer. The application is written in Vala
and uses Meson for builds.

## Reporting issues

Please report bugs and regressions on the project issue tracker:

https://github.com/sadraiiali/dastan/issues

Include your distribution, GTK/Libadwaita versions, the Markdown file that
reproduces the problem when possible, and steps to reproduce.

## Development setup

```bash
git clone --recurse-submodules https://github.com/sadraiiali/dastan
cd dastan
make init
make build
make run FILE=src/tests/test-showcase.md
```

See [docs/build-and-development.md](docs/build-and-development.md) for more
detail.

## Submitting changes

1. Fork the repository and create a feature branch.
2. Keep changes focused on the problem you are solving.
3. Run `make build` and relevant tests before opening a pull request.
4. Open a pull request with a clear description of the change and why it is
   needed.

## Translations

Translation files live in `po/`. To update the template:

```bash
meson compile -C build dastan-pot
```

## Code style

Follow the formatting rules in `.editorconfig`. Match the surrounding code
style in the files you edit.

## License

By contributing, you agree that your contributions will be licensed under
the same license as the project (AGPL-3.0-or-later).