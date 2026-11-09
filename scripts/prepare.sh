#!/bin/bash
# Clones termux-packages at the pinned commit into ./termux-packages and applies the overlay.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REF="$(tr -d '[:space:]' < "$ROOT/termux-packages.ref")"
DEST="$ROOT/termux-packages"

if [ ! -d "$DEST/.git" ]; then
	git init -q "$DEST"
	git -C "$DEST" remote add origin https://github.com/termux/termux-packages.git
fi
git -C "$DEST" fetch --depth 1 origin "$REF"
git -C "$DEST" checkout -q --force FETCH_HEAD

bash "$ROOT/overlay/apply.sh" "$DEST"
