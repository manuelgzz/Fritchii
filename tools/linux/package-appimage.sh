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
commit=$(sed -n 's/^#define GIT_REV "\([^"]*\)"/\1/p' "$build_dir/src/common/scm_rev.cpp")
package_commit=$(git -C "$source_dir" rev-parse HEAD)
if [[ ! "$commit" =~ ^[0-9a-f]{40}$ ]]; then
    echo "Missing source revision in the configured build." >&2
    exit 1
fi
compiler=$(sed -n 's/^CMAKE_CXX_COMPILER:FILEPATH=//p;s/^CMAKE_CXX_COMPILER:STRING=//p' \
    "$build_dir/CMakeCache.txt" | head -n 1)
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
        python3 "$source_dir/tools/linux/fetch-release-asset.py" \
            "linuxdeploy/$tool" continuous "$tool-$arch.AppImage" "$target"
    fi
    chmod +x "$target"
done
runtime="$tools_dir/runtime-$arch"
if [[ ! -s "$runtime" ]]; then
    python3 "$source_dir/tools/linux/fetch-release-asset.py" \
        AppImage/type2-runtime continuous "runtime-$arch" "$runtime"
fi

cp "$source_dir/LICENSE.txt" "$app_dir/usr/share/doc/fritchii/"
cp -a "$source_dir/LICENSES" "$app_dir/usr/share/doc/fritchii/"
cp "$source_dir/externals/FidelityFX-SDK/LICENSE.txt" \
    "$app_dir/usr/share/doc/fritchii/LICENSE-FidelityFX-SDK.txt"
chmod -R a+rX "$app_dir/usr/share/doc/fritchii"
desktop="$tools_dir/io.github.zortos293.lichii.desktop"
cp "$source_dir/dist/io.github.zortos293.lichii.desktop" "$desktop"
sed -i 's/^Name=Lichii$/Name=Fritchii/; s/^Keywords=.*/Keywords=Nintendo;Switch;Fritchii;Lichii;/' \
    "$desktop"
cp "$source_dir/dist/fritchii.png" "$tools_dir/io.github.zortos293.lichii.png"
{
    printf 'Version: %s\nSource: https://github.com/manuelgzz/Fritchii\nCommit: %s\n' "$version" "$commit"
    printf 'Packaging commit: %s\n' "$package_commit"
    printf 'Upstream: https://github.com/Frizti/Fritchii/tree/fritchii-v4.1\n'
    printf 'Architecture: %s\n' "$arch"
    getconf GNU_LIBC_VERSION
    "${compiler:-${CXX:-clang++}}" --version | head -n 1
    cmake --version | head -n 1
    sed -n 's/^CMAKE_CXX_FLAGS:STRING=/Compiler flags: /p' "$build_dir/CMakeCache.txt"
    sed -n 's/^CMAKE_EXE_LINKER_FLAGS:STRING=/Linker flags: /p;s/^ENABLE_LTO:BOOL=/LTO: /p;s/^YUZU_BUILD_PRESET:STRING=/CPU preset: /p' \
        "$build_dir/CMakeCache.txt"
    sha256sum "$source_dir/eglantine.profdata"
    sha256sum "$tools_dir"/*.AppImage "$runtime"
} > "$app_dir/usr/share/fritchii/build-info.txt"
cp "$app_dir/usr/share/fritchii/build-info.txt" "$output_dir/$name-build-info.txt"
if [[ -f "$build_dir/Testing/Temporary/LastTest.log" ]]; then
    cp "$build_dir/Testing/Temporary/LastTest.log" "$output_dir/unit-tests.log"
fi

export APPIMAGE_EXTRACT_AND_RUN=1
export LDAI_RUNTIME_FILE="$runtime"
export QMAKE=${QMAKE:-$(command -v qmake6 || command -v qmake)}
export EXTRA_QT_MODULES=waylandcompositor
export EXTRA_PLATFORM_PLUGINS='libqwayland-egl.so;libqwayland-generic.so'
export LDAI_VERSION="v${version}-${commit:0:10}"
export OUTPUT="$output_dir/$name.AppImage"
export ARCH="$arch"
# linuxdeploy excludes these desktop libraries by default, but minimal gaming
# distributions do not necessarily install them. Keep GPU drivers on the host.
extra_libraries=()
for library in libusb-1.0.so.0 libOpenGL.so.0 libharfbuzz.so.0 libfribidi.so.0 libasound.so.2; do
    library_path=$(ldconfig -p | awk -v name="$library" '$1 == name && !found {print $NF; found=1}')
    test -n "$library_path"
    extra_libraries+=(--library "$library_path")
done
"$tools_dir/linuxdeploy-$arch.AppImage" --appdir "$app_dir" \
    "${extra_libraries[@]}" \
    --exclude-library 'libfontconfig.so*' \
    --exclude-library 'libva.so*' --exclude-library 'libva-drm.so*' \
    --exclude-library 'libva-x11.so*' --exclude-library 'libvdpau.so*' \
    --executable "$build_dir/bin/lichii" \
    --executable "$build_dir/bin/eden-cli" \
    --desktop-file "$desktop" \
    --icon-file "$tools_dir/io.github.zortos293.lichii.png" \
    --plugin qt --output appimage
test -s "$OUTPUT"
chmod +x "$OUTPUT"
cd "$output_dir"
sha256sum "$name.AppImage" > "$name.AppImage.sha256"
printf 'Created %s\n' "$OUTPUT"
