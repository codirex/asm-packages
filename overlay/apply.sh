#!/bin/bash
# Applies the Android Studio Mobile overlay to a termux-packages checkout.
# Usage: overlay/apply.sh <termux-packages-dir>
set -euo pipefail

TARGET="${1:?usage: apply.sh <termux-packages-dir>}"
PROPS="$TARGET/scripts/properties.sh"
PACKAGE_NAME="org.codirex.asm"

[ -f "$PROPS" ] || { echo "missing $PROPS" >&2; exit 1; }

# --- 1. The app package name (and with it the prefix) ---------------------------------------------

echo "Lines mentioning TERMUX_APP__PACKAGE_NAME before:"
grep -n 'TERMUX_APP__PACKAGE_NAME=' "$PROPS" || true

if ! grep -qE '^TERMUX_APP__PACKAGE_NAME=' "$PROPS"; then
	echo "error: no top-level TERMUX_APP__PACKAGE_NAME assignment found; upstream layout changed" >&2
	exit 1
fi

sed -i -E "s|^TERMUX_APP__PACKAGE_NAME=.*|TERMUX_APP__PACKAGE_NAME=\"${PACKAGE_NAME}\"|" "$PROPS"

echo "After:"
grep -n 'TERMUX_APP__PACKAGE_NAME=' "$PROPS"

# --- 2. Source checksums that upstream has not fixed yet ----------------------------------------
# Some source archives are generated on demand by their host (for example GitLab) and their bytes
# change without the content changing. Each fix names the package, the checksum in the pinned
# upstream and the checksum the host serves now. Remove a fix when the pin moves past it.

fix_checksum() {
	local package="$1" old="$2" new="$3"
	local file="$TARGET/packages/$package/build.sh"
	[ -f "$file" ] || { echo "error: $file is missing" >&2; exit 1; }
	if grep -q "$old" "$file"; then
		sed -i "s|$old|$new|" "$file"
		echo "checksum of $package updated"
	elif grep -q "$new" "$file"; then
		echo "checksum of $package already up to date"
	else
		echo "error: $package has neither the expected old nor the new checksum; review this fix" >&2
		exit 1
	fi
}

# apt 2.8.4 comes from a salsa.debian.org archive whose bytes changed.
fix_checksum apt \
	13b4cf69639f1c1e5bdbc5b790d85c87e371a4054a51e2b512b670d3693329a0 \
	d61bb433da8f622ee81b1d3d80e872abf54807ffbde39a1d4ba413b90b24ae7f
