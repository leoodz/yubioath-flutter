#!/usr/bin/env python3
import re
import sys

"""
This script updates version numbers in various files.
"""

version_pattern = r"(\d+)\.(\d+)\.(\d+)(-[^\s+]+)?"
lib_version_pattern = rf"const\s+String\s+version\s+=\s+'({version_pattern})';"
lib_build_pattern = rf"const\s+int\s+build\s+=\s+(\d+);"


def sub1(pattern, repl, string):
    buf, n = re.subn(pattern, repl, string)
    if n != 1:
        raise ValueError(f"Did not find string matching {pattern} to replace")
    return buf

def update_file(fname, func):
    with open(fname) as f:
        orig = f.read()

    buf = func(orig)

    if buf != orig:
        with open(fname, "w") as f:
            f.write(buf)
        print("Updated", fname)

def read_lib_version():
    with open("lib/version.dart") as f:
        buf = f.read()

    m = re.search(
        lib_version_pattern,
        buf,
        re.MULTILINE,
    )
    version = m.group(1)
    m = re.search(
        lib_build_pattern,
        buf,
        re.MULTILINE,
    )
    build = int(m.group(1))
    return version, build


def update_lib(buf):
    buf = sub1(
        lib_version_pattern,
        f"const String version = '{version}';",
        buf,
    )

    buf = sub1(
        lib_build_pattern,
        f"const int build = {build};",
        buf,
    )

    return buf

# Handle invocation
args = sys.argv[1:]
if not args:
    version, build = read_lib_version()
    print(f"Using version: {version}, build: {build}...")
elif len(args) == 2:
    version = args[0]
    if not re.fullmatch(version_pattern, version):
        print("Version is not a valid semver string!")
        sys.exit(1)
    build = int(args[1])
    print(f"Setting new version: {version}, build: {build}...")
    update_file("lib/version.dart", update_lib)
else:
    print("Usage: set-version.py <version> <build>")
    sys.exit(1)

# x.y.z without trailing part
short_version = re.search("(\d+\.\d+\.\d+)", version).group()

# pubspec.yaml
def update_pubspec(buf):
    return sub1(
        r'version:\s+\d+\.\d+\.\d+\+\d+',
        f'version: {short_version}+{build}',
        buf,
    )

# Windows Runner.rc
def update_runner_rc(buf):
    buf = sub1(
        rf'#define VERSION_AS_STRING "{version_pattern}"',
        f'#define VERSION_AS_STRING "{version}"',
        buf,
    )

    version_as_number = short_version.replace(".", ",")
    buf = sub1(
        r"#define VERSION_AS_NUMBER \d+,\d+,\d+",
        f"#define VERSION_AS_NUMBER {version_as_number}",
        buf,
    )
    return buf

# Helper version_info
def update_helper_version(buf):
    version_tuple = repr(tuple(int(d) for d in short_version.split(".")) + (0,))
    buf = sub1(
        rf'filevers=\(\d+, \d+, \d+, \d+\)',
        f'filevers={version_tuple}',
        buf,
    )
    buf = sub1(
        rf'prodvers=\(\d+, \d+, \d+, \d+\)',
        f'prodvers={version_tuple}',
        buf,
    )
    buf = sub1(
        rf"'FileVersion', '{version_pattern}'",
        f"'FileVersion', '{version}'",
        buf,
    )
    buf = sub1(
        rf"'ProductVersion', '{version_pattern}'",
        f"'ProductVersion', '{version}'",
        buf,
    )
    return buf


update_file("pubspec.yaml", update_pubspec)
update_file("windows/runner/Runner.rc", update_runner_rc)
update_file("helper/version_info.txt", update_helper_version)