#!/bin/bash
# termux-tools reads TERMUX_APP_PACKAGE (and TERMUX_BASE_DIR, TERMUX_PREFIX, ...) from the
# environment when it is configured and falls back to com.termux, which the termux-packages builder
# does not set. Without this fix pkg, termux-info and the login scripts point at
# /data/data/com.termux/files/usr. The package name is exported in its pre-configure step; the other
# directories follow from it.
# Usage: overlay/tools.sh <termux-packages-dir>
set -euo pipefail

TARGET="${1:?usage: tools.sh <termux-packages-dir>}"
PACKAGE_NAME="org.codirex.asm"
FILE="$TARGET/packages/termux-tools/build.sh"

[ -f "$FILE" ] || { echo "error: $FILE is missing" >&2; exit 1; }
if ! grep -q '^termux_step_pre_configure() {$' "$FILE"; then
	echo "error: termux-tools has no termux_step_pre_configure; the upstream script changed" >&2
	exit 1
fi

sed -i -E "s|^termux_step_pre_configure\(\) \{\$|&\n\texport TERMUX_APP_PACKAGE=\"${PACKAGE_NAME}\"|" "$FILE"
if ! grep -q "export TERMUX_APP_PACKAGE=\"${PACKAGE_NAME}\"" "$FILE"; then
	echo "error: could not patch termux-tools" >&2
	exit 1
fi
bash -n "$FILE" || { echo "error: termux-tools build script no longer parses" >&2; exit 1; }
echo "termux-tools: app package ${PACKAGE_NAME}"
