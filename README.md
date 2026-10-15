# TEMPTERS — W2 playable economy

Godot 4.7.2 Standard / GDScript. Original orthographic 3D diorama with planar X/Z gameplay. Follow [WRITING_STYLE.md](WRITING_STYLE.md); see [STATUS.md](STATUS.md) for verification and limitations.

## Run

From Debian WSL in this project directory, run `bash run.sh` to play or `bash run.sh --editor` and press F5. The launcher uses the existing WSL D3D12 driver when available and respects an explicit GALLIUM_DRIVER setting. No system settings are changed. Windows-native Godot can open project.godot, but has not been tested here.

## Play

1. Click a hare to approach, hunt and collect meat and hide. Click trees and deposits to gather wood, stone and ore.
2. Click the living shrine to approach its service menu. Feed raw meat for +4 Satisfaction, including when dormant.
3. Select a service to preview its effect, exact costs, level requirement and any shortages. Craft a stone axe, smelt ore into ingots, and reinforce your backpack.
4. Upgrade the shrine through levels 1–5 to unlock the spear, hide armor, iron pickaxe, iron axe and reinforced armor. Higher levels increase Satisfaction capacity and appetite.
5. Equipment is automatically equipped. Armor increases maximum Health without healing. Restore up to 25 Health at the shrine for 10 Satisfaction. New characters start at 75 Health.

I or B opens inventory; scroll to equipment and Save/Load controls. Discard buttons free bag space. Right-click cancels; Escape cancels an active request or pauses/resumes. Wheel zooms. F2 toggles 65%/100% render resolution. F5 saves; F9 loads. Mouse clicks on UI do not move the character.

Pines and rocks renew after 65 seconds, hares after 35. Feeding remains available at zero Satisfaction. The clearing is inside the starter Bond aura; expedition drain and combat damage remain future milestones. W3 has not begun.

## Saving

Graphical play automatically loads at startup and saves after transactions, every 30 active seconds and on normal window close. The versioned user://save_slot_1.json contains character resources, gear, Health, Satisfaction, shrine level, position and resource depletion/timers. Timers do not advance while closed. Saving uses a temporary file followed by atomic replacement.

Invalid saves leave the live game unchanged and suspend automatic saving to preserve the file. An explicit Save replaces the slot. Headless smoke runs and automated gameplay tests leave the normal player slot untouched. Tests use separate disposable filenames.

## Verify

Run `bash tests/verify.sh` for import, bounded headless launch, W1 systems/physics, W2 economy/save tests, and restoration across separate Godot processes.

Rendered checks:

```sh
bash run.sh --script tests/test_scene.gd -- --visual
bash run.sh --script tests/test_economy.gd -- --visual
```

These save captures/feeding.png and captures/w2-services.png. Headless testing alone does not establish visual quality.

## Source map

- assets/geometry/: original mesh/material builders, unchanged by W2.
- scripts/game_state.gd: inventory, atomic feeding/services, equipment and progression.
- scripts/save_store.gd: schema validation and atomic save replacement.
- scripts/grid_navigation.gd: deterministic obstacle-aware A*.
- scripts/player.gd: planar character movement and work animation.
- scripts/interactable.gd: prey/resources, stable IDs and renewable state.
- scripts/main.gd: scene orchestration, interaction, equipment visuals and ritual effects.
- scripts/hud.gd: recipe previews, inventory and functional controls.
- ECONOMY_BALANCE.json: resource costs, requirements, gear benefits, appetite, action timings and save interval.
