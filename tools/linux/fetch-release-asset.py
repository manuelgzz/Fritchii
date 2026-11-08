#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-3.0-or-later
"""Fetch a public GitHub release asset through its API and verify its digest."""

import hashlib
import json
from pathlib import Path
import sys
from urllib.parse import quote
from urllib.request import Request, urlopen


def fetch(repo: str, tag: str, name: str, destination: Path) -> None:
    api = f"https://api.github.com/repos/{repo}"
    headers = {"Accept": "application/vnd.github+json", "User-Agent": "Fritchii-AppImage"}
    request = Request(f"{api}/releases/tags/{quote(tag, safe='')}", headers=headers)
    with urlopen(request, timeout=60) as response:
        release = json.load(response)
    asset = next(item for item in release["assets"] if item["name"] == name)
    headers["Accept"] = "application/octet-stream"
    request = Request(f"{api}/releases/assets/{asset['id']}", headers=headers)
    temporary = destination.with_name(destination.name + ".part")
    destination.parent.mkdir(parents=True, exist_ok=True)
    digest = hashlib.sha256()
    size = 0
    try:
        with urlopen(request, timeout=60) as response, temporary.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
                digest.update(chunk)
                size += len(chunk)
        if size != asset["size"]:
            raise ValueError(f"Incorrect download size for {name}: {size}")
        expected = asset.get("digest")
        if expected and expected != f"sha256:{digest.hexdigest()}":
            raise ValueError(f"SHA-256 mismatch for {name}")
        temporary.replace(destination)
        print(f"{name}: sha256:{digest.hexdigest()}")
    finally:
        temporary.unlink(missing_ok=True)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        sys.exit("Usage: fetch-release-asset.py OWNER/REPO TAG ASSET DESTINATION")
    fetch(*sys.argv[1:4], Path(sys.argv[4]))
