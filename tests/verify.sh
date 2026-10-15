#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot --version
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 60
godot --headless --path . --script tests/test_systems.gd
godot --headless --path . --script tests/test_scene.gd
godot --headless --path . --script tests/test_economy.gd
godot --headless --path . --script tests/test_save_restart.gd -- --write
godot --headless --path . --script tests/test_save_restart.gd
