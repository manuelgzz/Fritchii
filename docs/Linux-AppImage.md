# Fritchii for Linux

This fork builds Fritchii **v4.1**, including the complete source history of the
Windows release `f6d42b87150678e001dbeb84679a9595935ce951` (8 November 2026).
The original default branch `nx2` predates that release; building it alone misses
the changes on `hotfix/v4.1`.

The shared emulation changes are retained: the water/texture-handle fix, lighting
buffer ranges, foliage and storage bindings, AMD shader fixes, cooperative-matrix
HMMA where the driver supports it, audio, synchronization, dynamic FPS patches,
and v4.1 settings and pipeline-cache migration. This establishes source parity;
gameplay and performance still depend on the Linux GPU driver and require testing.

## Platform differences

- NVIDIA DLSS replacement uses Windows Streamline DLLs, Authenticode and Win32
  APIs. Upstream gates it to MSVC x86_64. It is unavailable in this native Linux
  build; a separate Linux backend and NVIDIA hardware validation are required.
  FSR and the normal game-rendering paths remain as implemented upstream.
- Windows in-place updates/rollback, Overwolf handling, crash dumps and profiling
  hooks are platform-specific. Automatic updates are disabled for this AppImage:
  the upstream update sources serve other forks or Windows packages. Download
  updates from this fork's releases instead.
- The generic x86_64 build uses Clang ThinLTO and lld, and avoids `-march=native`.
  It is not the Windows PGO build and does not claim the same performance. The
  repository's PGO profile needs a newer LLVM reader than Ubuntu's Clang 18.

## Build

Build on Ubuntu 24.04 (glibc 2.39) for an AppImage targeting that baseline. Use
CMake 3.31+, Clang, LLVM tools, lld, Ninja, patch, Python, pkg-config and the development dependencies in
[Deps.md](Deps.md). Install Qt Charts, Qt tools, Qt Wayland and
`qt6-wayland-dev`, as well as FFmpeg, PulseAudio/ALSA, libudev, libusb, OpenSSL,
Boost context/fiber, glslang and SPIR-V tools. The build downloads additional
dependencies from their pinned entries in `cpmfile.json`.

```sh
BUILD_JOBS=2 bash tools/linux/build-appimage.sh
```

Set `CC`, `CXX`, `BUILD_DIR`, `OUTPUT_DIR` or `QMAKE` when using a custom toolchain
or Qt installation. Extra arguments go to CMake, for example
`-DCMAKE_PREFIX_PATH=/opt/Qt/6.8.3/gcc_64`.

The script builds the GUI, CLI and unit tests, runs CTest, then packages Qt,
Wayland/X11 platform plugins, shared dependencies and license notices using
linuxdeploy. It writes the AppImage, SHA-256 checksum and build provenance to
`build/appimage-output`. Packaging tools are cached in the build directory; their
hashes are recorded in the build information. Downloads can use GitHub's public
release-asset API when browser download URLs fail; the pinned dependency hashes
are still checked, and packaging-tool digests are checked when GitHub provides them.

To package an already-tested build:

```sh
bash tools/linux/package-appimage.sh build/linux-appimage build/appimage-output
```

## Run

```sh
sha256sum -c Fritchii-v4.1-Linux-x86_64.AppImage.sha256
chmod +x Fritchii-v4.1-Linux-x86_64.AppImage
./Fritchii-v4.1-Linux-x86_64.AppImage
```

For systems without FUSE, set `APPIMAGE_EXTRACT_AND_RUN=1`. The host still needs
a compatible GPU driver and Vulkan loader. No games, keys, firmware or NVIDIA
proprietary runtime files are bundled.
