#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
build_dir=$(realpath "${1:?Usage: package-appimage.sh BUILD_DIR OUTPUT_DIR}")
mkdir -p "${2:?Usage: package-appimage.sh BUILD_DIR OUTPUT_DIR}"
output_dir=$(realpath "$2")
arch=$(uname -m)
case "$arch" in
    x86_64|aarch64) ;;
    *) echo "Unsupported AppImage architecture: $arch" >&2; exit 1 ;;
esac
for binary in lichii eden-cli; do
    test -x "$build_dir/bin/$binary"
done

version=$(head -n 1 "$source_dir/dist/frizti_version.txt" | tr -d '\r\n')
commit=$(git -C "$source_dir" rev-parse HEAD)
name="Fritchii-v${version}-Linux-${arch}"
tools_dir="$build_dir/appimage-tools"
app_dir="$build_dir/Fritchii.AppDir"
mkdir -p "$tools_dir" "$app_dir/usr/share/doc/fritchii" "$app_dir/usr/share/fritchii"
if [[ -e "$app_dir/AppRun" ]]; then
    echo "AppDir already packaged: use a fresh build directory or remove $app_dir first." >&2
    exit 1
fi

for tool in linuxdeploy linuxdeploy-plugin-qt; do
    target="$tools_dir/$tool-$arch.AppImage"
    if [[ ! -s "$target" ]]; then
        curl --fail --location --retry 3 \
            "https://github.com/linuxdeploy/$tool/releases/download/continuous/$tool-$arch.AppImage" \
            --output "$target.part"
        mv "$target.part" "$target"
    fi
    chmod +x "$target"
done

cp "$source_dir/LICENSE.txt" "$app_dir/usr/share/doc/fritchii/"
cp -a "$source_dir/LICENSES" "$app_dir/usr/share/doc/fritchii/"
cp "$source_dir/externals/FidelityFX-SDK/LICENSE.txt" \
    "$app_dir/usr/share/doc/fritchii/LICENSE-FidelityFX-SDK.txt"
cp "$source_dir/dist/io.github.zortos293.lichii.desktop" "$tools_dir/fritchii.desktop"
sed -i 's/^Name=Lichii$/Name=Fritchii/; s/^Keywords=.*/Keywords=Nintendo;Switch;Fritchii;Lichii;/' \
    "$tools_dir/fritchii.desktop"
cp "$source_dir/dist/fritchii.png" "$tools_dir/io.github.zortos293.lichii.png"
{
    printf 'Version: %s\nSource: https://github.com/manuelgzz/Fritchii\nCommit: %s\n' "$version" "$commit"
    printf 'Upstream: https://github.com/Frizti/Fritchii/tree/fritchii-v4.1\n'
    printf 'Architecture: %s\n' "$arch"
    getconf GNU_LIBC_VERSION
    "${CXX:-clang++}" --version | head -n 1
    cmake --version | head -n 1
    sha256sum "$tools_dir"/*.AppImage
} > "$app_dir/usr/share/fritchii/build-info.txt"
cp "$app_dir/usr/share/fritchii/build-info.txt" "$output_dir/$name-build-info.txt"

export APPIMAGE_EXTRACT_AND_RUN=1
export QMAKE=${QMAKE:-$(command -v qmake6 || command -v qmake)}
export EXTRA_QT_MODULES=waylandcompositor
export EXTRA_PLATFORM_PLUGINS='libqwayland-egl.so;libqwayland-generic.so'
export LDAI_VERSION="v${version}-${commit:0:10}"
export OUTPUT="$output_dir/$name.AppImage"
export ARCH="$arch"
"$tools_dir/linuxdeploy-$arch.AppImage" --appdir "$app_dir" \
    --executable "$build_dir/bin/lichii" \
    --executable "$build_dir/bin/eden-cli" \
    --desktop-file "$tools_dir/fritchii.desktop" \
    --icon-file "$tools_dir/io.github.zortos293.lichii.png" \
    --plugin qt --output appimage
test -s "$OUTPUT"
chmod +x "$OUTPUT"
cd "$output_dir"
sha256sum "$name.AppImage" > "$name.AppImage.sha256"
printf 'Created %s\n' "$OUTPUT"
