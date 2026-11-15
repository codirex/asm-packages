#!/bin/bash
# Source downloads that no longer work from the upstream URLs. Usage: overlay/mirrors.sh <termux-packages-dir>
#
# downloads.apache.org only keeps the newest release of each project, so an older version that a
# termux package still pins (apr-util 1.6.5, for example) answers 404 there. archive.apache.org/dist
# keeps every release with the same bytes, so the pinned checksums stay valid.
set -euo pipefail

TARGET="${1:?usage: mirrors.sh <termux-packages-dir>}"
[ -d "$TARGET/packages" ] || { echo "missing $TARGET/packages" >&2; exit 1; }

count=0
while IFS= read -r file; do
	sed -i 's|https://downloads\.apache\.org/|https://archive.apache.org/dist/|g' "$file"
	if grep -q 'downloads\.apache\.org' "$file"; then
		echo "error: $file still mentions downloads.apache.org" >&2
		exit 1
	fi
	bash -n "$file" || { echo "error: $file no longer parses" >&2; exit 1; }
	echo "apache source moved to archive.apache.org: ${file#"$TARGET"/}"
	count=$((count + 1))
done < <(grep -rlF 'https://downloads.apache.org/' "$TARGET/packages" --include=build.sh | sort)
echo "mirrors: $count build scripts changed"
