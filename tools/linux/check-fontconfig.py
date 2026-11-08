#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check the AppDir library path against a host with Fontconfig 2.18+ rules."""

import os
from pathlib import Path
import subprocess
import sys
import tempfile


def main(appdir: Path):
    library_path = appdir.resolve() / "usr/lib"
    if not library_path.is_dir():
        raise RuntimeError(f"Missing AppDir library directory: {library_path}")
    with tempfile.TemporaryDirectory(prefix="fritchii-fontconfig-") as home:
        env = os.environ.copy()
        env.update(HOME=home, XDG_CACHE_HOME=str(Path(home) / ".cache"),
                   LD_LIBRARY_PATH=str(library_path))
        result = subprocess.run([sys.executable, "-c", """
import ctypes
fontconfig = ctypes.CDLL('libfontconfig.so.1')
version = fontconfig.FcGetVersion()
fontconfig.FcInitLoadConfigAndFonts.restype = ctypes.c_void_p
fontconfig.FcConfigDestroy.argtypes = [ctypes.c_void_p]
config = fontconfig.FcInitLoadConfigAndFonts()
assert config, 'Could not load the system font configuration'
fontconfig.FcConfigDestroy(config)
print(f'Loaded host Fontconfig {version}; system font configuration parsed')
assert version >= 21800, 'Run this regression check on a Fontconfig 2.18+ host'
"""], env=env, capture_output=True, text=True, timeout=30)
        print(result.stdout, end="")
        print(result.stderr, end="", file=sys.stderr)
        if result.returncode or "Fontconfig warning:" in result.stderr or "Fontconfig error:" in result.stderr:
            raise RuntimeError("AppDir libraries are incompatible with the host font configuration")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("Usage: check-fontconfig.py APPDIR (on a Fontconfig 2.18+ host)")
    main(Path(sys.argv[1]))
