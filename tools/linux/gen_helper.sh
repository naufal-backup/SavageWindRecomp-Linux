#!/bin/bash
# tools/linux/gen_helper.sh <x86_64|aarch64> (inside the build container of that arch, tools/linux/appimage.sh): the
# game code generator frozen by PyInstaller (tools/swgen.spec, as `make gen-helper`) with the container's Python,
# into build/linux/<arch>/helper/swgen. PY picks the interpreter: the Ubuntu 22.04 image has python3.12, an Arch one
# only python3, so the workflow passes PY=python3 there (PyInstaller 6.22.3 supports both).
set -euo pipefail
cd "$(dirname "$0")/../.."
L=$PWD/build/linux/$1
V=$L/gen-venv
PY=${PY:-python3.12}
if [ ! -f "$V/.ok" ]; then
    rm -rf "$V" && "$PY" -m venv "$V"
    "$V/bin/python" -m pip install -q --upgrade pip
    "$V/bin/python" -m pip install -q capstone==5.0.9 unicorn==2.1.4 lz4==4.4.5 pyinstaller==6.22.3
    touch "$V/.ok"
fi
"$V/bin/python" -m PyInstaller --noconfirm --clean --log-level WARN --distpath "$L/helper" --workpath "$L/pyinstaller" \
    tools/swgen.spec
du -sh "$L/helper/swgen"
