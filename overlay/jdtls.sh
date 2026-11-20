#!/bin/bash
# Adds the jdtls package (Eclipse JDT language server) to a termux-packages checkout.
# Usage: overlay/jdtls.sh <termux-packages-dir>
set -euo pipefail

TARGET="${1:?usage: jdtls.sh <termux-packages-dir>}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="$TARGET/packages/jdtls"

[ -d "$TARGET/packages" ] || { echo "missing $TARGET/packages" >&2; exit 1; }
if [ -e "$DEST" ]; then
	echo "error: $DEST already exists upstream; review this overlay" >&2
	exit 1
fi

mkdir -p "$DEST"
cp "$HERE/jdtls/build.sh" "$HERE/jdtls/jdtls.in" "$DEST/"
bash -n "$DEST/build.sh" || { echo "error: jdtls build script does not parse" >&2; exit 1; }
echo "jdtls: package added"
