#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
build_dir=${BUILD_DIR:-"$source_dir/build/linux-appimage"}
output_dir=${OUTPUT_DIR:-"$source_dir/build/appimage-output"}
jobs=${BUILD_JOBS:-2}

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="${CC:-clang}" \
    -DCMAKE_CXX_COMPILER="${CXX:-clang++}" \
    -DBUILD_TESTING=ON -DYUZU_TESTS=ON \
    -DENABLE_QT=ON -DYUZU_CMD=ON \
    -DYUZU_ROOM=OFF -DYUZU_ROOM_STANDALONE=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF -DYUZU_USE_BUNDLED_SDL3=ON \
    -DVulkanHeaders_FORCE_BUNDLED=ON -DVulkanUtilityLibraries_FORCE_BUNDLED=ON \
    -DYUZU_BUILD_PRESET=generic \
    -DENABLE_UPDATE_CHECKER=OFF \
    "$@"
cmake --build "$build_dir" --target yuzu yuzu-cmd tests update_checker_tests --parallel "$jobs"
ctest --test-dir "$build_dir" --output-on-failure --no-tests=error
bash "$source_dir/tools/linux/package-appimage.sh" "$build_dir" "$output_dir"
