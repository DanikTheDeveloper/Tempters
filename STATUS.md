# Current session — occlusion and W4

The player has verified W3. Phase 0 replaces full-shrine picking with InteractionResolver and a visible Services hotspot. CameraOcclusion registers scenery mesh groups, fades obstructing pieces to 35%, restores original material identities, and provides separated clickable markers for nearby hidden enemies. Physical obstacles still block attacks and movement. Rendered regression: 24 checks passed across four approach directions, three zoom levels, overlapping enemies, raid save/load, repeated clicks and rear movement. captures/occlusion.png was captured and inspected in Compatibility on WSL D3D12. Full W1–W3 regression plus occlusion passes: 286 assertions, headless import/startup, and separate-process persistence. Phase 0 is verified; W4 implementation follows this checkpoint.

Full user-data backup before this session: /home/danik/.local/share/godot/save_backups/TEMPTERS-W4-20261015T153703Z. Live save SHA256: 14c3226fb47bb322ba052121640220969bf72a90eff0eb8f5525f544ed30444d. Tests use independent slots.

W4 is now explicitly requested; begin only after the Phase 0 checkpoint. W5 is not authorized. Historical W3 report follows.

# TEMPTERS — W3 complete; critical movement fix verified

W1, W2 and W3 are implemented and verified within the scope below. W4, procedural world generation and new biomes have not begun. The approved central creature, authored environment, camera and lighting are preserved. WRITING_STYLE.md remains authoritative.

## Critical outcome

The reported persistent loss of control was reproduced using a copy of the actual user save before changes. A hare blocked the first waypoint of every route; restoring the saved positions recreated the collision. Frames and input remained live. The collision-layer fix restores movement without deleting or rewriting the player's save. Exact diagnostic evidence, backup location and checksum appear below.

## W3 systems

- Mouse-placed palisades and ward totems with green/red previews, rotation, resource costs, protected shrine/escape lane/resource access, physical collision, durability, reinforcement, repair, maintenance and destruction. Original timber, stone, bone and metal meshes remain.
- Totems produce bounded, distance-sensitive Satisfaction with diminishing returns, up to five and 0.045/s combined. Maintenance lasts 300 active seconds. Occupation blocks production; pausing stops upkeep and income.
- Level-2 stone golems cost 8 stone, 2 ingots and 16 Satisfaction, maximum three. Automatic hostile detection, pursuit within a 10m shrine defense radius, guard deployment, limb attack animation, damage reactions, Health and destruction. Golems use the existing grid and solid structure collisions.
- Click hostile units to approach and attack. Spear, iron axe and armor affect range/damage/protection. Right-click or Escape cancels combat. Raider and golem movement cannot wedge the player through body collision.
- Rival masked raiders and a visible warning scout. Initial grace is six active minutes, including a 30-second warning; subsequent preparation is four minutes. Groups grow from two to at most five with bounded Health scaling. AI targets the player, golems and structures, attacks barriers shielding targets, and approaches the shrine. Destroyed barriers clear navigation. Attacks withdraw after a bounded 180 seconds to prevent indefinite blocked raids.
- Defense rewards: 8 Satisfaction and 3 raw meat waiting at the shrine, preserved when inventory is full and consumed only once on collection.
- Ten-second capture channel interrupted by damage. Occupation blocks crafting and totem production but preserves feeding and healing. Raiders withdraw within 120 seconds; defeat or outlast them, then remain by the shrine for a free ten-second reclaim. Occupation stops further raid scheduling until reclaimed.
- Zero-Health rescue to the protected southern approach with 50 Health and 12 seconds of protection. Lose 20% of each carried resource stack, rounded down; retain equipment, levels, structures and defenders.
- Original animated moss-covered stone golems, masked rust-cloth raiders with polearms, and an occupation banner. Existing world/creature meshes and materials are retained.
- Schema 3 persists structures, actor Health and guard positions, raid phase/timer/wave, capture progress, pending rewards, protection and ownership. Schema 1/2 migration preserves progression and grants a fresh preparation interval. Transient orders, modal locks, placement previews and pause state never survive loading.

## Validation

Godot 4.7.2 Standard, Compatibility, Debian WSL. Run `bash tests/verify.sh`.

| Check | Result |
| --- | --- |
| Headless editor import and bounded game startup | PASS |
| W1 systems | 13 checks PASS |
| W1 scene, input and physics | 12 checks PASS |
| W2 economy and persistence | 49 checks PASS |
| W3 buildings, totems and migration | 48 checks PASS |
| Original movement bug and save recovery | 61 checks PASS |
| Golems, combat, raids, defeat, capture/reclaim and persistence | 41 checks PASS |
| Twelve repeated maximum-group combat save/load cycles with active buildings and mouse movement | 38 checks PASS |
| Separate-process save/startup restore, including damaged golem, enemy, palisade and occupied shrine; movement afterward | PASS |
| Rendered recovery suite | 61 checks PASS |
| Rendered combat suite | 41 checks PASS |
| Exact backed-up user save loaded in the final rendered W3 build | Mouse dispatch and completed movement PASS |
| Runtime text audit and Git whitespace check | PASS |

Total: 262 automated assertions plus separate-process persistence and the exact-save diagnostic. Test logs: /tmp/tempters-w3-verified.log, /tmp/tempters-combat-rendered-final.log, /tmp/tempters-original-w3-rendered.log. Earlier before/after diagnostic logs are /tmp/tempters-freeze-rendered-before.log and /tmp/tempters-freeze-rendered-after.log. Logs in /tmp are session evidence, not committed fixtures.

Rendered tests ran in actual WSL D3D12 NVIDIA GTX 1650 windows and dispatched viewport mouse events. Captures w3-building.png, w3-combat.png and save-diagnostic.png were inspected. These are automated staged scenarios, not a human natural-progression playthrough. The stress test performs twelve save/reload cycles while up to three golems and five raiders run their real physics AI, with a palisade and maintained totem. It is a bounded simulation, not an hours-long soak.

## Remaining limitations and next action

- Existing blocky WSL shadow edges and the unsupported V-Sync-switch warning remain; rendering/system settings were preserved. Windows-native execution, export builds, audio and hours-long human balance testing remain unverified.
- One rival faction and the current clearing are implemented. Richer faction tactics and additional regions are later work. No W4 systems are included.
- Structure footprints are conservative circles; rotation changes appearance, not occupied footprint. Protected lanes prevent sealing the base completely. No gates or wall snapping.
- Actors can overlap each other rather than physically jam; static structures remain solid. Visual crowding and long-session balance deserve human review.
- Test setup initially omitted a required armor prerequisite; save validation correctly rejected it. The fixture was corrected and repeated stress checks pass. Tests fail on script/runtime errors even when the engine returns zero, and each process has a timeout.
- Next action: play the existing save using `bash run.sh`, prepare defenses and assess the first raid. F8 recovers the previous valid snapshot; recovered files are backed up and autosaving stays suspended until F5. Do not begin W4 without a separate user request.

## Checkpoints

c31bab0 records the reproduced movement fix, save safeguards and verified construction subset. The subsequent W3 checkpoint records combat, raids, capture/recovery, schema-3 migration, original new unit meshes and expanded tests. No remote push or system installation was performed.

## Critical movement recovery — investigated after the construction checkpoint

The user's actual WSL save reproduced a persistent loss of movement in headless and rendered tests. This was not an engine freeze: frame/physics heartbeats continued, clicks produced valid paths, pause was false, time scale was 1 and interaction lock was 0. The player at (2.5177, 0, 7.5277) touched hare_3 at (2.7203, 0, 8.1978). The hare had reached its home-radius boundary and could not flee further. Every new A* route began with the same rounded source waypoint (2.6, 0, 7.8), which the hare's solid collision blocked. Persisting both positions reproduced the blockage after restarting. This save contained no buildings.

The entire Godot user-data directory was backed up BEFORE testing to /home/danik/.local/share/godot/save_backups/TEMPTERS-20261015T050340375809Z. Original and backup save SHA-256: d136dd5bbb1fba7167bf0cccec25ddf0bfa57df3eac0e0d10bbcf3687f2cd4bd. Tests used disposable copies, never the live slot. No user progression, inventory, Satisfaction, equipment, structures or world data was deleted or rewritten.

Fix: prey use the pickable layer 8 and no longer block the player's layer-2 collision mask. Initial spawn, renewal and saved-state restoration all use the same rule. Trees, rocks, the shrine and constructed barriers remain solid. The exact saved arrangement now permits mouse movement to completion, headlessly and in a D3D12 graphics window.

Successful loading also clears pause/time-scale changes, movement requests, work state, cooldowns, modal interfaces and placement state, restores physics processing and cancels interrupted healing animation. Saves retain a .previous valid snapshot before replacing the slot. Invalid existing files are copied to timestamped .rejected backups before an explicit save can replace them. F8 or the inventory's Load previous save button restores the prior valid snapshot. Corrupt primary saves automatically try that snapshot. Invalid player spawn positions can relocate to the protected southern approach while preserving the rest of the snapshot. Recovery first makes a timestamped .recovery backup, then suspends automatic overwrite until the player explicitly saves with F5. Unsupported/incomplete snapshots are not guessed or destructively reset.

New tests/test_recovery.gd covers the original spatial reproduction, renewal collision, saves during movement/placement/open interfaces/pause/healing/unreachable requests, active totems and barriers, obstacle-adjacent spawning, twelve repeated autosave/load cycles, pre-W3 migration, malformed JSON fallback, incomplete structure fallback, explicit previous-snapshot recovery, and actual mouse-driven displacement after every successful load. tests/diagnose_save.gd can inspect an arbitrary backed-up fixture using --fixture=<path>; it records timing, input, path, collision and movement evidence while operating on its own copy. Combat, occupation and cross-process actor persistence are now covered by test_combat.gd, test_endurance.gd and test_save_restart.gd.

Stability checkpoint validation: all 183 assertions (13 W1 systems, 12 W1 scene/input, 49 W2 economy, 48 construction, 61 recovery) plus cross-process persistence passed. The original-save diagnostic failed with a live hare collision before the fix and passed to the destination afterward in both headless and actual graphics runs. The recovery suite also passed all 61 checks in a graphics window. The original live save checksum remains unchanged. Test saves now use process-specific filenames to avoid concurrent test runs sharing a disposable slot; the verification runner times out stalled tests and fails on Godot script/runtime error output even if Godot reports exit status zero.
