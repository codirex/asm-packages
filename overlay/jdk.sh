#!/bin/bash
# Changes to the JDK packages. Usage: overlay/jdk.sh <termux-packages-dir>
#
# openjdk-17 lists alsa-plugins as a run time dependency. That pulls in pulseaudio (which needs
# libsndfile, libwebrtc-audio-processing and more) only for Java sound, which the IDE does not use;
# the JDK needs alsa-lib to build (a build dependency, which stays), not the plugins. The build of
# pulseaudio failed here (meson did not find sndfile), so the dependency is removed.
#
# gradle lists "openjdk-21 | openjdk-25 | openjdk-17" and the build resolves the first alternative,
# which is not in our package list and has the same alsa-plugins dependency. Gradle 9 runs on JDK
# 17, the only JDK this repository ships, so it depends on openjdk-17 alone.
set -euo pipefail

TARGET="${1:?usage: jdk.sh <termux-packages-dir>}"
FILE="$TARGET/packages/openjdk-17/build.sh"
[ -f "$FILE" ] || { echo "missing $FILE" >&2; exit 1; }

sed -i '/^TERMUX_PKG_DEPENDS=/ s/, alsa-plugins//' "$FILE"
if grep -E '^TERMUX_PKG_DEPENDS=' "$FILE" | grep -q 'alsa-plugins'; then
	echo "error: $FILE still depends on alsa-plugins" >&2
	exit 1
fi
bash -n "$FILE" || { echo "error: $FILE no longer parses" >&2; exit 1; }
echo "openjdk-17: alsa-plugins removed from the dependencies"

GRADLE="$TARGET/packages/gradle/build.sh"
[ -f "$GRADLE" ] || { echo "missing $GRADLE" >&2; exit 1; }
sed -i -E 's/^TERMUX_PKG_DEPENDS=.*/TERMUX_PKG_DEPENDS="openjdk-17"/' "$GRADLE"
if [ "$(grep -E '^TERMUX_PKG_DEPENDS=' "$GRADLE")" != 'TERMUX_PKG_DEPENDS="openjdk-17"' ]; then
	echo "error: $GRADLE does not depend on openjdk-17 alone" >&2
	exit 1
fi
bash -n "$GRADLE" || { echo "error: $GRADLE no longer parses" >&2; exit 1; }
echo "gradle: depends on openjdk-17 only"
