#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# Clone reference repositories listed in assets/context.yml into
# ./context/<group_id>/<project_name>/.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT_YML="${ROOT}/assets/context.yml"
CONTEXT_DIR="${ROOT}/context"

if [[ ! -f "$CONTEXT_YML" ]]; then
	echo "dastan: context manifest not found: ${CONTEXT_YML}" >&2
	exit 1
fi

mkdir -p "$CONTEXT_DIR"

current_slug=""
declare -A SEEN=()

trim() {
	local value="$1"
	value="${value%%#*}"
	value="${value%"${value##*[![:space:]]}"}"
	value="${value#"${value%%[![:space:]]*}"}"
	value="${value%\"}"
	value="${value#\"}"
	printf '%s' "$value"
}

while IFS= read -r line || [[ -n "$line" ]]; do
	if [[ "$line" =~ ^[[:space:]]+slug:[[:space:]]*(.+)$ ]]; then
		current_slug="$(trim "${BASH_REMATCH[1]}")"
		continue
	fi

	if [[ ! "$line" =~ ^[[:space:]]+github:[[:space:]]*(.+)$ ]]; then
		continue
	fi

	url="$(trim "${BASH_REMATCH[1]}")"
	[[ -n "$url" ]] || continue

	if [[ -z "$current_slug" ]]; then
		echo "dastan: github URL without category slug: ${url}" >&2
		continue
	fi

	if [[ ! "$url" =~ ^https://github\.com/[^/]+/[^/?#]+$ ]]; then
		echo "dastan: skipping unsupported GitHub URL: ${url}" >&2
		continue
	fi

	project_name="${url##*/}"
	dest="${CONTEXT_DIR}/${current_slug}/${project_name}"
	dest_key="${current_slug}/${project_name}"

	[[ -n "${SEEN[$dest_key]:-}" ]] && continue
	SEEN[$dest_key]=1

	if [[ -d "${dest}/.git" ]]; then
		echo "dastan: context/${dest_key} already present, skipping"
		continue
	fi

	if [[ -e "$dest" ]]; then
		echo "dastan: context/${dest_key} exists but is not a git checkout; skipping" >&2
		continue
	fi

	mkdir -p "${CONTEXT_DIR}/${current_slug}"
	echo "dastan: cloning ${url} -> context/${dest_key}"
	git clone --depth 1 "$url" "$dest"
done < "$CONTEXT_YML"