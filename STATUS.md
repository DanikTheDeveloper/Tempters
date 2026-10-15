# TEMPTERS — W2 complete, 2026-10-14

**W2 implemented and verified. W3 has not begun.** The user-approved 2.5D environment and central creature are preserved. Existing mesh builders, scene files, camera setup, world placement, lighting and movement controller were retained. All runtime text follows WRITING_STYLE.md.

## Playable systems

- Preserved W1: planar click navigation and obstacle avoidance, moving-hare hunting, harvesting, capacity-limited inventory, resource renewal, dormant feeding, pause, zoom and GPU launch workaround.
- Shrine service panel with recipe selection, effect preview, exact resource/Satisfaction costs, level requirements and shortage feedback. Close cancels the interaction; HUD input does not move the character.
- Atomic transactions for smelting, equipment, healing and shrine upgrades. Failed requests consume nothing. Remote and paused requests are rejected; cooldowns block rapid duplicate clicks. Feeding remains possible at zero Satisfaction.
- Smelt two ore into one ingot for 10 Satisfaction. Stone axe, spear, hide armor, reinforced backpack, iron pickaxe, iron axe and reinforced armor are automatically equipped with actual gameplay benefits. Equipment cannot be purchased twice. Original accessory meshes show acquired gear on the existing character.
- Axes improve chopping from 0.9 seconds to 0.55/0.35; pickaxe improves mineral work to 0.5; spear improves hunting to 0.45 and adds 0.65 reach. Backpack increases capacity from 30 weight/12 stacks to 40/16. Armor stages each add 20 maximum Health without healing.
- Restore up to 25 Health for 10 Satisfaction with a brief magical disappearance/reappearance and rising ritual ring. New characters begin at 75/100 Health so the service is useful before combat damage arrives. Crafting creates a bounded spark burst at an offering bowl and the existing creature pulse.
- Shrine levels 1–5: Satisfaction caps 100/130/160/200/250; appetite multipliers 1/1.15/1.3/1.5/1.75. Material and Satisfaction upgrade requirements unlock meaningful equipment tiers. Bond cap scales by 30 per level; actual expedition drain remains W4.
- Scrollable resource/equipment inventory, capacity summary, discard controls and save/load buttons. All economic values and gameplay timing live in ECONOMY_BALANCE.json.
- Persistent schema-v1 user://save_slot_1.json: inventory, equipment, shrine ownership/level, offerings, Health, Satisfaction, player position, stable world IDs, depletion and renewal timers. Temporary-file flush/close then atomic rename. Load validates the entire snapshot before any live mutation. Unsupported, malformed, duplicate-ID, invalid-position and invalid-capacity data are rejected. Timers do not advance offline, and depleted nodes cannot be harvested again after loading.
- F5 saves, F9 loads. Graphical play auto-loads on startup and saves after transactions, every 30 active seconds and on normal window close. A malformed existing file blocks automatic overwrite; explicit Save can replace it. Headless smoke runs do not use the normal slot; persistence tests use disposable files.

## Verification performed

Command: `bash tests/verify.sh` under Debian WSL with Godot 4.7.2 Standard.

| Check | Result |
| --- | --- |
| Editor import and bounded headless run | PASS; no script/runtime errors |
| W1 pure systems | 13 assertions PASS |
| W1 scene, physics and input | 12 assertions PASS |
| W2 economy, service callbacks, pause, persistence and layout | 49 assertions PASS |
| Save in one process, startup restoration in another | PASS in both processes |
| Rendered W2 suite via `bash run.sh --script tests/test_economy.gd -- --visual` | 49 assertions PASS on D3D12 NVIDIA GTX 1650 |
| Actual rendered W2 screenshot | Captured and inspected at 1280x720; panels fit and central creature stays visible |
| Runtime forced-humor string search | No rejected phrases found in scripts, scenes, assets or economy data |

The tests include exact-cost transactions, insufficiency without mutation, dormancy/revival, every progression tier and gear effect, full-health rejection, forced capacity/slot failures, proximity, repeated clicks, actual service-button wiring, corrupted/unsupported saves, write failures, world restoration and reload loot protection. The rendered tests use constructed states to inspect late-game gear and UI; they are not a natural full-progression playthrough.

## Visual evidence and limitations

- captures/w2-services.png is the current rendered W2 service/inventory view with level-five gear. Its test inventory is intentionally sparse, so the selected completed recipe correctly shows Already equipped.
- Earlier captures/first-light.png, feeding.png and clay-review.png remain historical W1 evidence. They were not regenerated as part of W2.
- The established shrine/environment geometry, materials, camera and lighting were preserved. New gear and short service effects use the same muted metal/leather palette and existing sculpture helpers.
- Existing WSL D3D12 blocky shadow artifacts remain visible. The driver also warns that V-Sync switching is unsupported. No renderer or system configuration was changed.
- Plain Godot may select slow llvmpipe here; use bash run.sh for the existing GPU driver selection. Previous W1 performance measured about 42 FPS after warm-up; W2 performance was not benchmarked.
- No audio, combat damage, defense, raids, new biomes, travel or expedition drain in this milestone. Armor provides real maximum-Health capacity now; defensive combat tuning belongs to W3. No W3 placeholder actions were added to the service menu.
- Long-session economy pacing, human playthrough, Windows-native Godot and exported builds remain unverified. Save schema rejects unsupported versions; migration will be needed if the format changes later.

## Documentation and checkpoint

README, the Russian readme status, game design, technical architecture, milestones and the W2/W3 prompt now describe the working W2 and its boundaries. WRITING_STYLE.md remains authoritative. W3 requires another explicit request.

The directory was not initialized as Git. A local repository was initialized for the user-requested verified W2 checkpoint, including the existing W1 source and assets. No remote is configured or pushed. No user Git identity was configured; the checkpoint uses the explicit agent identity Codex <codex@local.invalid> for this commit only, without changing global configuration.

## Next action

Play with `bash run.sh`: gather, feed, craft the stone axe and backpack, then advance shrine levels. F5/F9 exercise persistence. The next recommended development milestone is W3, only on explicit request; first use human play feedback to assess W2 pacing. Preserve the accepted diorama and writing rules.
