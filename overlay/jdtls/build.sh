TERMUX_PKG_HOMEPAGE=https://github.com/eclipse-jdtls/eclipse.jdt.ls
TERMUX_PKG_DESCRIPTION="Eclipse JDT language server for Java (LSP)"
TERMUX_PKG_LICENSE="EPL-2.0"
TERMUX_PKG_MAINTAINER="@codirex"
TERMUX_PKG_VERSION="1.61.0"
TERMUX_PKG_REVISION=1
_TIMESTAMP="202609031315"
TERMUX_PKG_SRCURL="https://download.eclipse.org/jdtls/milestones/${TERMUX_PKG_VERSION}/jdt-language-server-${TERMUX_PKG_VERSION}-${_TIMESTAMP}.tar.gz"
TERMUX_PKG_SHA256=338e7e73d61836651ba2453919a0d34fa763eb4e7c03342092309bffb8934c64
# The archive has no top-level folder, so the generic extraction (which strips one) is not used.
TERMUX_PKG_SKIP_SRC_EXTRACT=true
# 1.62.0 and later need Java 25 (Eclipse 4.42 platform bundles); 1.61.0 runs on Java 21.
TERMUX_PKG_DEPENDS="openjdk-21"
TERMUX_PKG_PLATFORM_INDEPENDENT=true

termux_step_make_install() {
	local archive="$TERMUX_PKG_CACHEDIR/jdt-language-server-${TERMUX_PKG_VERSION}-${_TIMESTAMP}.tar.gz"
	termux_download "$TERMUX_PKG_SRCURL" "$archive" "$TERMUX_PKG_SHA256"

	rm -rf "$TERMUX_PREFIX/opt/jdtls"
	mkdir -p "$TERMUX_PREFIX/opt/jdtls"
	tar xzf "$archive" -C "$TERMUX_PREFIX/opt/jdtls"

	# What the launcher relies on must be there; fail here, not on the device.
	ls "$TERMUX_PREFIX"/opt/jdtls/plugins/org.eclipse.equinox.launcher_*.jar > /dev/null
	test -d "$TERMUX_PREFIX/opt/jdtls/config_linux"
	test -d "$TERMUX_PREFIX/opt/jdtls/config_linux_arm"
	# The archive carries launchers for other systems; only the jar-based start is used here.
	rm -f "$TERMUX_PREFIX/opt/jdtls/bin/jdtls.bat"

	mkdir -p "$TERMUX_PREFIX/bin"
	sed -e "s|@TERMUX_PREFIX@|$TERMUX_PREFIX|g" -e "s|@VERSION@|$TERMUX_PKG_VERSION|g" \
		"$TERMUX_PKG_BUILDER_DIR/jdtls.in" > "$TERMUX_PREFIX/bin/jdtls"
	chmod 700 "$TERMUX_PREFIX/bin/jdtls"
}
