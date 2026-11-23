TERMUX_PKG_HOMEPAGE=https://github.com/eclipse-lemminx/lemminx
TERMUX_PKG_DESCRIPTION="Eclipse LemMinX, the XML language server (LSP)"
TERMUX_PKG_LICENSE="EPL-2.0"
TERMUX_PKG_MAINTAINER="@codirex"
TERMUX_PKG_VERSION="0.31.1"
TERMUX_PKG_SRCURL="https://download.eclipse.org/lemminx/releases/${TERMUX_PKG_VERSION}/org.eclipse.lemminx-uber.jar"
TERMUX_PKG_SHA256=0fba0b09a039ae5fcaa99ffa9d99ee9234bee3ff0a63fc1ab991d79922ce0491
# The source is one jar, not an archive: nothing to extract.
TERMUX_PKG_SKIP_SRC_EXTRACT=true
# The jar is built for Java 11 (class file version 55); it runs on the JDK 17 of the userland.
TERMUX_PKG_DEPENDS="openjdk-17"
TERMUX_PKG_PLATFORM_INDEPENDENT=true

termux_step_make_install() {
	local jar="$TERMUX_PKG_CACHEDIR/org.eclipse.lemminx-uber-${TERMUX_PKG_VERSION}.jar"
	termux_download "$TERMUX_PKG_SRCURL" "$jar" "$TERMUX_PKG_SHA256"

	mkdir -p "$TERMUX_PREFIX/opt/lemminx"
	install -m 644 "$jar" "$TERMUX_PREFIX/opt/lemminx/lemminx.jar"

	mkdir -p "$TERMUX_PREFIX/bin"
	sed -e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" "$TERMUX_PKG_BUILDER_DIR/lemminx.in" > "$TERMUX_PREFIX/bin/lemminx"
	chmod 700 "$TERMUX_PREFIX/bin/lemminx"
}
