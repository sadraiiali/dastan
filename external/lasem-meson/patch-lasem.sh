#!/bin/sh
# Apply local patches to the lasem submodule (not yet upstream).
set -e

lasem_dir="${1:-external/lasem}"
patch_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/patches"

if [ ! -d "$lasem_dir/src" ]; then
  echo "dastan: lasem submodule missing at $lasem_dir" >&2
  exit 1
fi

for patch in "$patch_dir"/*.patch; do
  [ -f "$patch" ] || continue
  if patch -d "$lasem_dir" -p1 --forward -r - < "$patch" >/dev/null 2>&1; then
    :
  elif patch -d "$lasem_dir" -p1 --reverse --dry-run -r - < "$patch" >/dev/null 2>&1; then
    :
  else
    echo "dastan: failed to apply $(basename "$patch") to $lasem_dir" >&2
    exit 1
  fi
done