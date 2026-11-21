#!/bin/bash
# Changes to the JDK packages. Usage: overlay/jdk.sh <termux-packages-dir>
#
# openjdk-17, openjdk-21 and openjdk-25 list alsa-plugins as a run time dependency. That pulls in
# pulseaudio (which needs libsndfile, libwebrtc-audio-processing and more) only for Java sound,
# which the IDE does not use; the JDK needs alsa-lib to build (a build dependency, which stays), not
# the plugins. The build of pulseaudio failed here (meson did not find sndfile), so the dependency
# is removed.
#
# gradle lists "openjdk-21 | openjdk-25 | openjdk-17" and the build resolves the first alternative.
# Gradle 9 runs on JDK 17, so it depends on openjdk-17 alone (the Java language server needs 25 and
# says so in its own package).
set -euo pipefail

TARGET="${1:?usage: jdk.sh <termux-packages-dir>}"

no_alsa_plugins() {
	local package="$1"
	local file="$TARGET/packages/$package/build.sh"
	[ -f "$file" ] || { echo "missing $file" >&2; exit 1; }
	sed -i '/^TERMUX_PKG_DEPENDS=/ s/, alsa-plugins//' "$file"
	if grep -E '^TERMUX_PKG_DEPENDS=' "$file" | grep -q 'alsa-plugins'; then
		echo "error: $file still depends on alsa-plugins" >&2
		exit 1
	fi
	bash -n "$file" || { echo "error: $file no longer parses" >&2; exit 1; }
	echo "$package: alsa-plugins removed from the dependencies"
}

no_alsa_plugins openjdk-17
no_alsa_plugins openjdk-21
no_alsa_plugins openjdk-25

GRADLE="$TARGET/packages/gradle/build.sh"
[ -f "$GRADLE" ] || { echo "missing $GRADLE" >&2; exit 1; }
sed -i -E 's/^TERMUX_PKG_DEPENDS=.*/TERMUX_PKG_DEPENDS="openjdk-17"/' "$GRADLE"
if [ "$(grep -E '^TERMUX_PKG_DEPENDS=' "$GRADLE")" != 'TERMUX_PKG_DEPENDS="openjdk-17"' ]; then
	echo "error: $GRADLE does not depend on openjdk-17 alone" >&2
	exit 1
fi
bash -n "$GRADLE" || { echo "error: $GRADLE no longer parses" >&2; exit 1; }
echo "gradle: depends on openjdk-17 only"
