#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-or-later
set -euo pipefail

source_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
build_dir=${BUILD_DIR:-"$source_dir/build/linux-appimage"}
output_dir=${OUTPUT_DIR:-"$source_dir/build/appimage-output"}
jobs=${BUILD_JOBS:-2}
llvm_bin=${LLVM_BIN:-/usr/lib/llvm-23/bin}
if [[ -d "$llvm_bin" ]]; then
    export PATH="$llvm_bin:$PATH"
fi
profile_flags=""
if [[ ${BUILD_PGO:-1} == 1 ]]; then
    llvm-profdata show "$source_dir/eglantine.profdata" >/dev/null
    profile_flags="-fprofile-use=\"$source_dir/eglantine.profdata\" -Wno-backend-plugin"
    profile_flags+=" -Wno-profile-instr-unprofiled -Wno-profile-instr-out-of-date"
fi

cmake -S "$source_dir" -B "$build_dir" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER="${CC:-clang}" \
    -DCMAKE_CXX_COMPILER="${CXX:-clang++}" \
    "-DCMAKE_C_FLAGS=$profile_flags" "-DCMAKE_CXX_FLAGS=$profile_flags" \
    -DBUILD_TESTING=ON -DYUZU_TESTS=ON \
    -DENABLE_QT=ON -DYUZU_CMD=ON \
    -DYUZU_ROOM=OFF -DYUZU_ROOM_STANDALONE=OFF \
    -DYUZU_USE_BUNDLED_QT=OFF -DYUZU_USE_BUNDLED_SDL3=ON \
    -DVulkanHeaders_FORCE_BUNDLED=ON -DVulkanUtilityLibraries_FORCE_BUNDLED=ON \
    -DYUZU_BUILD_PRESET=generic \
    -DENABLE_LTO=ON -DUSE_FASTER_LINKER=ON \
    -DCMAKE_JOB_POOLS=appimage_link=1 -DCMAKE_JOB_POOL_LINK=appimage_link \
    -DENABLE_UPDATE_CHECKER=OFF \
    "$@"
cmake --build "$build_dir" --target yuzu yuzu-cmd tests update_checker_tests --parallel "$jobs"
ctest --test-dir "$build_dir" --output-on-failure --no-tests=error
python3 -B "$source_dir/tools/nx2/test_debug_mcp.py"
python3 -B "$source_dir/tools/nx2/test_thread_worker_wake.py"
python3 -I "$source_dir/tools/nx2/thread_worker_wake.py" --cxx "${CXX:-clang++}"
bash "$source_dir/tools/linux/package-appimage.sh" "$build_dir" "$output_dir"
