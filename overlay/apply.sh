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

# --- 2. Source archives whose bytes are not stable -------------------------------------------------
# Some hosts (for example GitLab) generate archives on demand, and the bytes change without the
# content changing, so no pinned checksum lasts. For such a package the checksum is skipped; the
# source is still the tagged release, fetched over HTTPS. Remove an entry when the pin moves past it
# or the upstream package uses a stable archive.

skip_checksum() {
	local package="$1"
	local file="$TARGET/packages/$package/build.sh"
	[ -f "$file" ] || { echo "error: $file is missing" >&2; exit 1; }
	if ! grep -qE '^TERMUX_PKG_SHA256=' "$file"; then
		echo "error: $package has no TERMUX_PKG_SHA256 line; review this fix" >&2
		exit 1
	fi
	sed -i -E 's|^TERMUX_PKG_SHA256=.*|TERMUX_PKG_SHA256=SKIP_CHECKSUM|' "$file"
	echo "checksum of $package skipped"
}

# apt 2.8.4 comes from a salsa.debian.org archive whose bytes changed twice.
skip_checksum apt

# --- 3. ncurses without the foot terminfo ----------------------------------------------------------
# ncurses downloads the foot terminal's source from codeberg.org only to install foot's terminfo
# entry. From GitHub runners that download times out. Foot is not needed in the IDE's terminal, so
# its source and its two install steps are removed. The result must not mention foot any more, so a
# change in the upstream script fails here instead of in the middle of a one-hour build.

NCURSES="$TARGET/packages/ncurses/build.sh"
[ -f "$NCURSES" ] || { echo "error: $NCURSES is missing" >&2; exit 1; }

if grep -q 'foot' "$NCURSES"; then
	perl -0pi -e '
		s/\n[ \t]*"\$\(\. "\$TERMUX_SCRIPTDIR\/x11-packages\/foot\/build\.sh"; echo "\$TERMUX_PKG_\w+"\)"\)/)/g;
		s/\n[ \t]*# Upstream instructions for building foot.*?tic -x -e foot,foot-direct -o "\$TI" -//s;
		s/\n[^\n]*full-terminfo\/f\/foot[^\n]*//;
	' "$NCURSES"
	if grep -n 'foot' "$NCURSES"; then
		echo "error: ncurses still mentions foot; the upstream script changed, review this fix" >&2
		exit 1
	fi
	bash -n "$NCURSES" || { echo "error: ncurses build script no longer parses" >&2; exit 1; }
	echo "ncurses: foot terminfo removed"
else
	echo "ncurses: no foot terminfo (already removed)"
fi

# --- 4. Our own signing key and our own repository -------------------------------------------------
# termux-keyring ships the keys apt trusts. Ours replaces all of Termux's, so apt trusts only
# packages signed by the key of this repository. apt's default sources.list points at our
# repository instead of packages.termux.dev. The public key is overlay/asm-packages.asc; the private
# key exists only as a GitHub secret (ADR-0007).

REPO_URL="https://codirex.github.io/asm-packages/"
OVERLAY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEYRING_DIR="$TARGET/packages/termux-keyring"
KEYRING="$KEYRING_DIR/build.sh"
[ -f "$KEYRING" ] || { echo "error: $KEYRING is missing" >&2; exit 1; }
[ -f "$OVERLAY_DIR/asm-packages.asc" ] || { echo "error: overlay/asm-packages.asc is missing" >&2; exit 1; }

gpg --dearmor < "$OVERLAY_DIR/asm-packages.asc" > "$KEYRING_DIR/asm-packages.gpg"
[ -s "$KEYRING_DIR/asm-packages.gpg" ] || { echo "error: the public key could not be converted" >&2; exit 1; }

# Remove every upstream key from the install step, then install ours right after the directory is
# created.
sed -i -E '/^[[:space:]]*install -Dm600 "\$TERMUX_PKG_BUILDER_DIR\/[A-Za-z0-9._-]+\.gpg" "\$GPG_SHARE_DIR"$/d' "$KEYRING"
sed -i -E 's|^([[:space:]]*)mkdir -p "\$GPG_SHARE_DIR"$|&\n\1install -Dm600 "$TERMUX_PKG_BUILDER_DIR/asm-packages.gpg" "$GPG_SHARE_DIR"|' "$KEYRING"
if [ "$(grep -c 'install -Dm600' "$KEYRING")" != 1 ] || ! grep -q 'asm-packages.gpg' "$KEYRING"; then
	echo "error: termux-keyring still installs other keys; the upstream script changed, review this fix" >&2
	exit 1
fi
bash -n "$KEYRING" || { echo "error: termux-keyring build script no longer parses" >&2; exit 1; }
echo "termux-keyring: only the key of this repository"

APT="$TARGET/packages/apt/build.sh"
[ -f "$APT" ] || { echo "error: $APT is missing" >&2; exit 1; }
perl -0pi -e '
	s/\t\{\n\t\techo "# The main termux repository, with cloudflare cache".*?\} > \$TERMUX_PREFIX\/etc\/apt\/sources\.list/\techo "deb '"${REPO_URL//\//\\/}"' stable main" > \$TERMUX_PREFIX\/etc\/apt\/sources.list/s;
' "$APT"
if ! grep -q "deb ${REPO_URL} stable main" "$APT" || grep -q 'packages-cf.termux.dev' "$APT"; then
	echo "error: apt still points at the Termux repository; the upstream script changed, review this fix" >&2
	exit 1
fi
bash -n "$APT" || { echo "error: apt build script no longer parses" >&2; exit 1; }
echo "apt: sources.list points at ${REPO_URL}"
