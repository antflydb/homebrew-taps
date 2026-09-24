#!/usr/bin/env bash
set -euo pipefail

output=${1:?usage: rebuild.sh OUTPUT_DIRECTORY}
test "$(uname -s)" = Darwin
test "$(uname -m)" = arm64
test "$(zig version)" = 0.16.0
recipe_dir="$(cd "$(dirname "$0")" && pwd -P)"
mkdir -p "$output"
output="$(cd "$output" && pwd -P)"
work="$(mktemp -d "${TMPDIR:-/tmp}/antfly-homebrew-rebuild.XXXXXX")"
echo "Build workspace: $work"

git init "$work/source"
git -C "$work/source" remote add origin https://github.com/antflydb/antfly.git
git -C "$work/source" fetch --depth 1 origin e5261e9e2937d03943b518974bf8063351ad1449
git -C "$work/source" checkout --detach FETCH_HEAD
git -C "$work/source" submodule update --init
git -C "$work/source" apply "$recipe_dir/headerpad.patch"
(
  cd "$work/source/zig"
  python3 tools/run_bounded_zig_build.py --zig zig --max-rss-cap 21474836480 -- \
    build -j2 capi -Dtarget=aarch64-macos -Dcpu=baseline \
    -Doptimize=ReleaseFast -Dstrip=true -Dantfly-version=0.2.1 \
    -Dantfly-bin-name=antfly -Donnx=false -Dmetal=true \
    -Dcuda=false -Dpjrt=false -Dsystem-blas=true --prefix "$work/install"
)

curl --fail --location --retry 3 \
  https://releases.antfly.io/antfly/v0.2.1/antfly_0.2.1_Darwin_arm64.tar.gz \
  -o "$work/original.tar.gz"
echo "d169bd4dfdee1cb007092770e62181061207649463a56a3ef02cbeb431aa1e62  $work/original.tar.gz" \
  | shasum -a 256 --check
mkdir "$work/stage"
tar -xzf "$work/original.tar.gz" -C "$work/stage"
cmp "$work/stage/include/antfly.h" "$work/install/include/antfly.h"
cp "$work/install/lib/libantfly.dylib" "$work/stage/lib/libantfly.dylib"
python3 "$work/source/scripts/packaging/create_reproducible_tar.py" \
  --source "$work/stage" --mtime 1788913782 \
  --output "$output/antfly_0.2.1_Darwin_arm64_homebrew_1.tar.gz"
shasum -a 256 "$output/antfly_0.2.1_Darwin_arm64_homebrew_1.tar.gz"
