#!/usr/bin/env python3
"""Fail if any authored text file contains a non-ASCII character.

Recorded fixtures are exempt: they are real responses and are never edited by hand.
Usage: python3 scripts/check_ascii.py [path ...]   (default: every tracked file)
"""
import subprocess
import sys

SKIP_DIRS = ("tests/fixtures/", "node_modules/", "bin/", "obj/", "web/dist/")
SKIP_EXT = (".png", ".jpg", ".jpeg", ".gif", ".ico", ".woff", ".woff2", ".pdf", ".zip", ".lock")


def tracked():
    out = subprocess.run(["git", "ls-files", "-co", "--exclude-standard"],
                         capture_output=True, text=True, check=True).stdout
    return [p for p in out.splitlines() if p]


def main():
    paths = sys.argv[1:] or tracked()
    bad = 0
    for path in paths:
        if path.startswith(SKIP_DIRS) or path.lower().endswith(SKIP_EXT):
            continue
        try:
            data = open(path, "rb").read()
        except (IsADirectoryError, FileNotFoundError):
            continue
        for lineno, line in enumerate(data.split(b"\n"), 1):
            for col, byte in enumerate(line, 1):
                if byte > 126 or (byte < 32 and byte not in (9, 13)):
                    print("%s:%d:%d non-ASCII byte 0x%02x" % (path, lineno, col, byte))
                    bad += 1
                    break
    if bad:
        print("%d line(s) failed the ASCII gate" % bad)
        return 1
    print("ASCII gate passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
