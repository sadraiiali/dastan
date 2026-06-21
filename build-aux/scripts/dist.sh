#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

VERSION="$(grep -m1 "version:" meson.build | sed -E "s/.*'([^']+)'.*/\1/")"
DIST="$ROOT/dist"
STAGING="$DIST/staging"
PKG_BUILD="$DIST/build"
APPDIR="$DIST/AppDir"
NFPM_VERSION="${NFPM_VERSION:-2.41.3}"
NFPM_BIN="$DIST/tools/nfpm"
APPIMAGETOOL_VERSION="${APPIMAGETOOL_VERSION:-continuous}"

map_arch() {
  case "$(uname -m)" in
    x86_64) echo amd64 ;;
    aarch64|arm64) echo arm64 ;;
    *)
      echo "dastan: unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

map_nfpm_arch() {
  case "$(uname -m)" in
    x86_64) echo x86_64 ;;
    aarch64|arm64) echo aarch64 ;;
    *)
      echo "dastan: unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

map_appimage_arch() {
  case "$(uname -m)" in
    x86_64) echo x86_64 ;;
    aarch64|arm64) echo aarch64 ;;
    *)
      echo "dastan: unsupported architecture: $(uname -m)" >&2
      exit 1
      ;;
  esac
}

ensure_nfpm() {
  if command -v nfpm >/dev/null 2>&1; then
    NFPM_BIN="$(command -v nfpm)"
    return
  fi

  if [ -x "$NFPM_BIN" ]; then
    return
  fi

  local machine
  machine="$(uname -m)"
  case "$machine" in
    x86_64) machine="x86_64" ;;
    aarch64|arm64) machine="arm64" ;;
    *)
      echo "dastan: cannot download nfpm for architecture: $machine" >&2
      exit 1
      ;;
  esac

  mkdir -p "$DIST/tools"
  local archive="nfpm_${NFPM_VERSION}_Linux_${machine}.tar.gz"
  local url="https://github.com/goreleaser/nfpm/releases/download/v${NFPM_VERSION}/${archive}"

  echo "dastan: downloading nfpm ${NFPM_VERSION}..."
  curl -fsSL "$url" | tar -xz -C "$DIST/tools" nfpm
  chmod +x "$NFPM_BIN"
}

download_tool() {
  local name="$1"
  local url="$2"
  local dest="$DIST/tools/$name"

  if [ -x "$dest" ]; then
    echo "$dest"
    return
  fi

  mkdir -p "$DIST/tools"
  echo "dastan: downloading $name..." >&2
  curl -fsSL -o "$dest" "$url"
  chmod +x "$dest"
  echo "$dest"
}

ensure_appimage_icon() {
  local icon="$ROOT/data/icons/hicolor/256x256/apps/io.github.markviewer.png"
  local fallback="$ROOT/build-aux/packaging/appimage/io.github.markviewer.png"
  if [ -f "$icon" ] || [ -f "$fallback" ]; then
    return
  fi

  icon="$fallback"
  mkdir -p "$(dirname "$icon")"
  if command -v magick >/dev/null 2>&1; then
    magick "$ROOT/data/logo.jpg" -resize 256x256 "$icon"
  elif command -v convert >/dev/null 2>&1; then
    convert "$ROOT/data/logo.jpg" -resize 256x256 "$icon"
  elif command -v ffmpeg >/dev/null 2>&1; then
    ffmpeg -y -i "$ROOT/data/logo.jpg" -vf scale=256:256 -frames:v 1 -update 1 "$icon" >/dev/null
  else
    echo "dastan: need ImageMagick or ffmpeg to generate AppImage icon" >&2
    exit 1
  fi
}

stage_install_tree() {
  rm -rf "$STAGING" "$PKG_BUILD" "$APPDIR"
  mkdir -p "$STAGING"

  make init-build

  meson setup "$PKG_BUILD" . \
    --prefix=/usr \
    --buildtype=release \
    --strip

  meson compile -C "$PKG_BUILD"
  DESTDIR="$STAGING" meson install -C "$PKG_BUILD"
  glib-compile-schemas "$STAGING/usr/share/glib-2.0/schemas"
}

build_nfpm_packages() {
  export VERSION
  export ARCH="$(map_arch)"

  "$NFPM_BIN" pkg \
    -f "$ROOT/build-aux/packaging/nfpm.yaml" \
    -p deb \
    -t "$DIST/dastan_${VERSION}_${ARCH}.deb"

  "$NFPM_BIN" pkg \
    -f "$ROOT/build-aux/packaging/nfpm.yaml" \
    -p rpm \
    -t "$DIST/dastan-${VERSION}-1.$(map_nfpm_arch).rpm"

  "$NFPM_BIN" pkg \
    -f "$ROOT/build-aux/packaging/nfpm.yaml" \
    -p archlinux \
    -t "$DIST/dastan-${VERSION}-1-$(map_nfpm_arch).pkg.tar.zst"
}

build_appimage() {
  local arch desktop icon appimagetool output

  arch="$(map_appimage_arch)"
  ensure_appimage_icon

  desktop="$STAGING/usr/share/applications/io.github.markviewer.desktop"
  icon="$STAGING/usr/share/icons/hicolor/256x256/apps/io.github.markviewer.png"
  if [ ! -f "$desktop" ] || [ ! -f "$icon" ]; then
    echo "dastan: desktop entry or icon missing from staged install tree" >&2
    exit 1
  fi

  appimagetool="$(download_tool "appimagetool-${arch}.AppImage" \
    "https://github.com/AppImage/AppImageKit/releases/download/${APPIMAGETOOL_VERSION}/appimagetool-${arch}.AppImage")"

  rm -rf "$APPDIR"
  mkdir -p "$APPDIR"
  cp -a "$STAGING/usr" "$APPDIR/usr"
  install -m 0755 "$ROOT/build-aux/packaging/appimage/AppRun" "$APPDIR/AppRun"
  cp "$desktop" "$APPDIR/io.github.markviewer.desktop"
  cp "$icon" "$APPDIR/io.github.markviewer.png"

  output="$DIST/dastan-${VERSION}-${arch}.AppImage"

  echo "dastan: building AppImage..."
  ARCH="$arch" VERSION="$VERSION" APPIMAGE_EXTRACT_AND_RUN=1 \
    "$appimagetool" --no-appstream "$APPDIR" "$output"

  chmod +x "$output"
  echo "dastan: AppImage -> $output"
}

create_source_tarball() {
  local tarball="$DIST/dastan-${VERSION}.tar.gz"

  tar -czf "$tarball" \
    --exclude=build \
    --exclude=dist \
    --exclude=context \
    --exclude=.git \
    -C "$ROOT" .

  echo "dastan: source tarball -> $tarball"
}

main() {
  mkdir -p "$DIST"
  chmod +x "$ROOT/build-aux/packaging/scripts/postinstall.sh"
  chmod +x "$ROOT/build-aux/packaging/scripts/postremove.sh"
  chmod +x "$ROOT/build-aux/packaging/appimage/AppRun"

  ensure_nfpm
  stage_install_tree
  build_nfpm_packages
  build_appimage
  create_source_tarball

  echo
  echo "dastan: packages ready in $DIST/"
  ls -1 "$DIST"/*.{deb,rpm,pkg.tar.zst} 2>/dev/null || true
  ls -1 "$DIST"/*.AppImage 2>/dev/null || true
  ls -1 "$DIST"/*.tar.gz 2>/dev/null || true
}

main "$@"