#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
godot_binary="$(command -v godot)"
godot() {
  local output="${PWD}/verification-${BASHPID}.log"
  if ! timeout 120 "$godot_binary" "$@" >"$output" 2>&1; then
    cat "$output"
    return 1
  fi
  cat "$output"
  if grep -Eq 'SCRIPT ERROR:|^ERROR:' "$output"; then return 1; fi
}
godot --version
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 60
godot --headless --path . --script tests/test_systems.gd
godot --headless --path . --script tests/test_scene.gd
godot --headless --path . --script tests/test_economy.gd
godot --headless --path . --script tests/test_building.gd
godot --headless --path . --script tests/test_recovery.gd
godot --headless --path . --script tests/test_occlusion.gd
godot --headless --path . --script tests/test_combat.gd
godot --headless --path . --script tests/test_endurance.gd
godot --headless --path . --script tests/test_save_restart.gd -- --write
godot --headless --path . --script tests/test_save_restart.gd
