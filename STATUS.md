# TEMPTERS — W3 construction checkpoint

**W3 is IN PROGRESS, not complete.** This session delivers a stable construction-and-totem subset. W1/W2 remain playable and verified. Golems, combat, enemy factions, raids and capture/recovery are unfinished. W4 has not begun.

## Verified starting point

Read the agent contract, writing policy, game/art/creature/technical documents, balance data, milestone prompt, QA checklist and implementation before changes. The clean W2 checkpoint passed editor import, bounded launch, 13 system assertions, 12 scene/input assertions, 49 economy/persistence assertions and cross-process save restoration before W3 work began.

## Implemented in this checkpoint

- Build toolbar and G shortcut. Choose Palisade or Ward totem, then a ground-snapped mouse location. Green/red previews show validity; R rotates; right-click/Escape cancel without payment. Actual click coordinates determine placement, preventing stale-preview placement.
- Atomic resource costs from existing recipes: 4 wood for a palisade; 8 wood + 2 hide for a totem. Failed overlap, range, resource, pause and capacity-of-world checks consume nothing. No inventory kits or decorative purchase buttons.
- Placement within 9m of the shrine and 5m of the player. Conservative circular footprints reject overlap with the hero, resources, shrine roots and other structures. The southern approach stays open. A candidate navigation grid verifies resource access before committing. At most 24 structures and five totems.
- Physical static-body barriers and rebuilt A* navigation. Actual player locomotion around a newly constructed palisade is tested. Removing/destroying structures clears their collision and navigation obstruction.
- Original authored meshes: irregular pointed timber stakes, stone footings, crossrails, bindings and reinforced metal bracing; carved bone ward posts with hanging charms, stone bases, collars and an active ember. Existing terrain, shrine, player, camera, lights, scene files and original geometry builders are unchanged.
- Mouse-selectable structures, approach behavior and concise inspection UI. Palisades have 100 durability; totems 60. Reinforcement at shrine level 2 costs 2 wood + 1 ingot and grants 50% more maximum durability without repairing current damage. Totem reinforcement also boosts output by 50%.
- Repair restores up to 50 durability for 2 wood + 1 stone. Dismantle is free, without refunds. Damage produces visible leaning/sinking; zero durability removes the structure. Damage/destruction are exercised through tests; there is no hostile damage source yet.
- Maintained totems generate Satisfaction at 0.015/s for the strongest inner totem; subsequent active strengths receive 60% geometric diminishing returns. Beyond 6m output is reduced to 60%. Strongest contributions rank first, so placement order is irrelevant. Combined output is capped at 0.045/s and Satisfaction never exceeds its level cap.
- Each totem has 300 active seconds of maintenance. One wood + one hide restores the timer. Expired embers go dark and production stops. Time is consumed even at full Satisfaction; no offline income, paused income or indefinite unattended farming. Large simulation steps split at expiry boundaries to avoid overproduction.
- Schema-v2 saves persist stable structure IDs, positions, rotations, tiers, durability and remaining maintenance time alongside all W2 state. Schema-v1 W2 saves explicitly migrate to an empty building set, preserving the character and resources. Load validates the whole snapshot before applying it and rebuilds physics/navigation. Invalid structure values, IDs, overlaps and blocked access are rejected.
- Construction/repair/maintenance/reinforcement/dismantling use the existing autosave path. Cross-process restoration now verifies a constructed palisade as well as W2 inventory and depleted prey.

## Validation

Run `bash tests/verify.sh` from Debian WSL. Godot: 4.7.2 Standard, Compatibility.

| Check | Result |
| --- | --- |
| Headless editor import and bounded launch | PASS |
| W1 system checks | 13 PASS |
| W1 scene/physics/input checks | 12 PASS |
| W2 economy and persistence checks | 49 PASS |
| W3 construction, totems, input, collision, migration and persistence | 48 PASS |
| Cross-process save and startup restoration, including a barrier | PASS |
| Rendered W3 building suite on WSL D3D12 NVIDIA GTX 1650 | 48 PASS |
| Actual 1280x720 construction screenshot | Captured and inspected |
| Changed runtime strings and rejected-phrase scan | Reviewed; no forced humor introduced |

Total: 122 assertions, plus the cross-process save check. Tests include atomic failure, repeated actions, real mouse placement dispatch, player detouring around a barrier, physical picking, bounded production, outer-ring penalties, upgrades, maintenance expiry, pause, malformed building data and W2 migration.

A rendered check caught the expanded inspection panel overlapping the bottom HUD. The panel was compacted and the rendered assertion now passes. Another check caught JSON numeric version values failing strict array-membership comparison; version validation now accepts the correctly parsed integral schema number and still rejects unsupported formats.

## Evidence and limitations

- captures/w3-building.png: actual scene with two totems, a reinforced palisade and the inspection panel. The test constructs known states; this is not a full natural progression playthrough.
- Existing WSL D3D12 blocky shadows and unsupported V-Sync-switch warning remain. No rendering or system settings were changed. Use `bash run.sh` for the established GPU-driver launcher.
- Building placement deliberately protects the shrine mound and main approach. This makes trapping the player difficult, but means the base cannot be completely sealed; raids will need to respect this open-lane layout.
- Physics footprints are conservative circles around the authored meshes. Rotation affects appearance; it does not change the occupied footprint. There are no gates, wall-snapping chains or relocated buildings.
- Durability, repairs and destruction work, but incoming damage is currently test-driven. There are no natural attacks, combat animations, golem defenders, faction AI, scouts, raid scheduling, warning countdowns, occupied-creature reactions, capture channels or reconquest mechanics yet. No raid/golem state is falsely claimed as saved.
- No additional audio. Long-session balance, maximum-density performance, Windows-native Godot, exports and a human playthrough remain unverified.
- W2 feeding, crafting, smelting, healing, equipment, levels and saves remain available. Totems slightly offset drain; upkeep and the cap preserve the feeding economy.

## Documentation and checkpoint

README (including Russian status), GAME_DESIGN, TECH_ARCHITECTURE and MILESTONES now distinguish the working construction subset from remaining W3 work. WRITING_STYLE.md remains authoritative. The local Git checkpoint records this bounded increment; no remote push is performed. Commit identity uses the already-established explicit agent identity when user Git identity is unavailable.

## Next W3 increment

Continue W3 with a small complete combat/raid slice: original golem and raider assets; resource-and-Satisfaction-paid summoning; automatic defender targeting; click-to-attack player combat; obstacle-aware enemies attacking barriers; at least six minutes of initial safety and a clear scout/warning before the first raid; gradual bounded escalation; ten-second damage-interruptible capture; temporary occupation with accessible feeding/healing and free recovery. Extend schema v2 through an explicit migration for actor health, raid timers and ownership, then test defeat/recovery and reload behavior before calling W3 complete. Do not begin W4.

To play this checkpoint: `bash run.sh`, gather wood/hide, move beside the shrine, open Build [G], place and maintain a ward totem. F5 saves and F9 loads.

## Critical movement recovery — investigated after the construction checkpoint

The user's actual WSL save reproduced a persistent loss of movement in headless and rendered tests. This was not an engine freeze: frame/physics heartbeats continued, clicks produced valid paths, pause was false, time scale was 1 and interaction lock was 0. The player at (2.5177, 0, 7.5277) touched hare_3 at (2.7203, 0, 8.1978). The hare had reached its home-radius boundary and could not flee further. Every new A* route began with the same rounded source waypoint (2.6, 0, 7.8), which the hare's solid collision blocked. Persisting both positions reproduced the blockage after restarting. This save contained no buildings.

The entire Godot user-data directory was backed up BEFORE testing to /home/danik/.local/share/godot/save_backups/TEMPTERS-20261015T050340375809Z. Original and backup save SHA-256: d136dd5bbb1fba7167bf0cccec25ddf0bfa57df3eac0e0d10bbcf3687f2cd4bd. Tests used disposable copies, never the live slot. No user progression, inventory, Satisfaction, equipment, structures or world data was deleted or rewritten.

Fix: prey use the pickable layer 8 and no longer block the player's layer-2 collision mask. Initial spawn, renewal and saved-state restoration all use the same rule. Trees, rocks, the shrine and constructed barriers remain solid. The exact saved arrangement now permits mouse movement to completion, headlessly and in a D3D12 graphics window.

Successful loading also clears pause/time-scale changes, movement requests, work state, cooldowns, modal interfaces and placement state, restores physics processing and cancels interrupted healing animation. Saves retain a .previous valid snapshot before replacing the slot. Invalid existing files are copied to timestamped .rejected backups before an explicit save can replace them. F8 or the inventory's Load previous save button restores the prior valid snapshot. Corrupt primary saves automatically try that snapshot. Invalid player spawn positions can relocate to the protected southern approach while preserving the rest of the snapshot. Recovery first makes a timestamped .recovery backup, then suspends automatic overwrite until the player explicitly saves with F5. Unsupported/incomplete snapshots are not guessed or destructively reset.

New tests/test_recovery.gd covers the original spatial reproduction, renewal collision, saves during movement/placement/open interfaces/pause/healing/unreachable requests, active totems and barriers, obstacle-adjacent spawning, twelve repeated autosave/load cycles, pre-W3 migration, malformed JSON fallback, incomplete structure fallback, explicit previous-snapshot recovery, and actual mouse-driven displacement after every successful load. tests/diagnose_save.gd can inspect an arbitrary backed-up fixture using --fixture=<path>; it records timing, input, path, collision and movement evidence while operating on its own copy. NPC/combat/capture persistence tests remain pending until those systems exist.

Stability checkpoint validation: all 183 assertions (13 W1 systems, 12 W1 scene/input, 49 W2 economy, 48 construction, 61 recovery) plus cross-process persistence passed. The original-save diagnostic failed with a live hare collision before the fix and passed to the destination afterward in both headless and actual graphics runs. The recovery suite also passed all 61 checks in a graphics window. The original live save checksum remains unchanged. Test saves now use process-specific filenames to avoid concurrent test runs sharing a disposable slot; the verification runner times out stalled tests and fails on Godot script/runtime error output even if Godot reports exit status zero.
