# asm-packages

Terminal bootstrap and apt repository for **Android Studio Mobile** (`org.codirex.asm`).

This repository does not fork termux-packages. It pins an upstream commit
(`termux-packages.ref`), applies a tiny overlay (`overlay/apply.sh`) that sets
the app package name, and builds everything on GitHub Actions.

Prefix: `/data/data/org.codirex.asm/files/usr`

See ADR-0006 and ADR-0007 in the android-studio-mobile repository.

## Layout

- `termux-packages.ref` - pinned upstream commit.
- `overlay/apply.sh` - the only modifications applied to upstream.
- `scripts/prepare.sh` - clones upstream at the pin and applies the overlay.
- `.github/workflows/build-probe.yml` - builds one package for one architecture to validate the custom prefix.

## Status

Step 1: probe build (one small package, aarch64). Next: package set, apt repository, bootstrap archives.

## License

Apache-2.0 for the files in this repository. Packages built from termux-packages keep their own upstream licenses.
