# Antfly 0.2.1 Homebrew revision 1

The original Apple Silicon archive has insufficient Mach-O header padding for
Homebrew to rewrite `libantfly.dylib`'s install name. This packaging revision
replaces only that library. The CLI and every other archive member remain
byte-for-byte identical to the official v0.2.1 download.

The runtime source is commit `e5261e9e2937d03943b518974bf8063351ad1449`
(Antfly v0.2.1), with only the adjacent `headerpad.patch` applied. It enables
Zig's `headerpad_max_install_names` for the macOS shared library. The build uses
Zig 0.16.0, baseline aarch64, ReleaseFast, stripping, Metal, and system BLAS,
matching the release configuration. The embedded version remains 0.2.1.

Run `bash packaging/antfly-0.2.1/rebuild.sh OUTPUT_DIRECTORY` on Apple Silicon
with Zig 0.16.0, Python 3, Git, curl, and Xcode Command Line Tools installed.
The script creates a fresh source checkout and a new archive; it never replaces
the upstream tag or archive. Different macOS SDKs can produce different library
checksums. The published checksum pins the tested build.

Validation includes a successful Homebrew install, the compiled C embedding
test, and an upgrade from the original version-64 keg. `revision 1` also lets
users who already installed the corrected 0.2.1 formula receive this repair.

The permanent linker and formula-generator fixes are also merged into Antfly's
main and v0.2.x branches for subsequent releases.
