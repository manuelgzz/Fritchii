#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Check that the packaged GUI opens an X11 window with isolated user data."""

import ctypes as C
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import time


def window_titles(x11, display):
    root = C.c_ulong()
    parent = C.c_ulong()
    children = C.POINTER(C.c_ulong)()
    count = C.c_uint()
    titles = []
    if x11.XQueryTree(display, x11.XDefaultRootWindow(display), C.byref(root),
                      C.byref(parent), C.byref(children), C.byref(count)):
        for index in range(count.value):
            name = C.c_void_p()
            if x11.XFetchName(display, children[index], C.byref(name)) and name.value:
                titles.append(C.string_at(name).decode("utf-8", errors="replace"))
                x11.XFree(name)
        if children:
            x11.XFree(children)
    return titles


def main(image: Path, log: Path):
    x11 = C.CDLL("libX11.so.6")
    x11.XOpenDisplay.argtypes = [C.c_char_p]
    x11.XOpenDisplay.restype = C.c_void_p
    x11.XDefaultRootWindow.argtypes = [C.c_void_p]
    x11.XDefaultRootWindow.restype = C.c_ulong
    x11.XQueryTree.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_ulong),
                              C.POINTER(C.c_ulong), C.POINTER(C.POINTER(C.c_ulong)),
                              C.POINTER(C.c_uint)]
    x11.XFetchName.argtypes = [C.c_void_p, C.c_ulong, C.POINTER(C.c_void_p)]
    x11.XFree.argtypes = [C.c_void_p]
    x11.XCloseDisplay.argtypes = [C.c_void_p]
    display = x11.XOpenDisplay(None)
    if not display:
        raise RuntimeError("No X11 display; run this check with xvfb-run -a")
    try:
        with tempfile.TemporaryDirectory(prefix="fritchii-smoke-") as state:
            env = os.environ.copy()
            for key, directory in [("XDG_CONFIG_HOME", "config"), ("XDG_DATA_HOME", "data"),
                                   ("XDG_CACHE_HOME", "cache"), ("XDG_RUNTIME_DIR", "runtime")]:
                path = Path(state) / directory
                path.mkdir(mode=0o700)
                env[key] = str(path)
            env.update(APPIMAGE_EXTRACT_AND_RUN="1", QT_QPA_PLATFORM="xcb")
            with log.open("w") as output:
                process = subprocess.Popen([str(image.resolve())], env=env, stdout=output,
                                           stderr=subprocess.STDOUT, start_new_session=True)
                try:
                    deadline = time.monotonic() + 45
                    while time.monotonic() < deadline:
                        if process.poll() is not None:
                            raise RuntimeError(f"AppImage exited with {process.returncode}; see {log}")
                        titles = window_titles(x11, display)
                        if any("Fritchii" in title for title in titles):
                            time.sleep(2)
                            if process.poll() is not None:
                                raise RuntimeError("AppImage exited after creating its window")
                            print(f"Packaged X11 GUI opened successfully: {titles}")
                            return
                        time.sleep(0.5)
                    raise RuntimeError(f"No Fritchii window appeared; see {log}")
                finally:
                    if process.poll() is None:
                        os.killpg(process.pid, signal.SIGTERM)
                        try:
                            process.wait(timeout=5)
                        except subprocess.TimeoutExpired:
                            os.killpg(process.pid, signal.SIGKILL)
                            process.wait()
    finally:
        x11.XCloseDisplay(display)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        sys.exit("Usage: xvfb-run -a python3 smoke-appimage.py IMAGE LOG")
    main(Path(sys.argv[1]), Path(sys.argv[2]))
