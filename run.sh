#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
# WSL's default Mesa choice can be llvmpipe even with /dev/dxg available.
# This affects only this child process; explicit caller choices are preserved.
if [[ -z "${GALLIUM_DRIVER:-}" && -e /dev/dxg && -f /usr/lib/x86_64-linux-gnu/dri/d3d12_dri.so ]]; then
    export GALLIUM_DRIVER=d3d12
fi
exec godot --path "$PWD" "$@"
