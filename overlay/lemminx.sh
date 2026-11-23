#!/bin/bash
# Adds the lemminx package (Eclipse LemMinX, the XML language server) to a termux-packages checkout.
# Usage: overlay/lemminx.sh <termux-packages-dir>
set -euo pipefail

TARGET="${1:?usage: lemminx.sh <termux-packages-dir>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$TARGET/packages/lemminx"

[ -d "$TARGET/packages" ] || { echo "missing $TARGET/packages" >&2; exit 1; }
if [ -e "$DEST" ]; then
	echo "error: $DEST already exists upstream; review this overlay" >&2
	exit 1
fi

mkdir -p "$DEST"
cp "$HERE/lemminx/build.sh" "$HERE/lemminx/lemminx.in" "$DEST/"
bash -n "$DEST/build.sh" || { echo "error: lemminx build script does not parse" >&2; exit 1; }
echo "lemminx: package added"
