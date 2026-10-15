# TECH ARCHITECTURE — Godot 2.5D, WSL2, Testable Systems

## Text and content

Follow [WRITING_STYLE.md](WRITING_STYLE.md) for UI, prompts, warnings, dialogue and generated content. Preserve exact gameplay values and transaction feedback. Do not introduce reaction pools or repeat notifications for routine actions. Review any future localization or text-generation source against the same policy.

## Hard choices

- Runtime **Godot Standard 4.7.2 if installed**, GDScript only. Target Windows/Linux desktop. Developer: **Debian 13 Trixie on WSL2**, editor via WSLg (or Windows-native editor pointing at same files). Codex CLI runs in Linux, not PowerShell.
- Visual: true Godot **3D scene** viewed using fixed **orthographic Camera3D** angled above the ground. Gameplay: effectively **2D**. Player moves exclusively on world XZ ground plane, Y is height/visual relief. Input and AI operate on XZ coordinates.
- Physics: CharacterBody3D for player; StaticBody3D with simple shapes for trees/boulders and core; Area3D for approach radius; living entities scene-driven. Camera ray picks target colliders, clicks on bare ground projected to ground plane. Use collision layers to distinguish ground, interactable, blocked obstacles and hit actors.
- Screen UI: standard `Control` nodes in CanvasLayer, reactive to domain signals. Never use 3D interface for essential text. Use consistent viewport scaling to 1280x720 reference while supporting window resize.
- WSL compatibility: Godot renderer **Compatibility** as the robust starting setting (`rendering/renderer/rendering_method="gl_compatibility"` if supported by installed Godot); forward+ can be opt-in after testing graphics drivers. Avoid SSAO/SSGI/volumetric fog/bloom as mandatory W1 features. Make attractive looks using geometry, materials, lights/shadows and proper staging even on GL Compatibility.
- Shader complexity limited; assets created and cached once, no full rebuild per-frame. Stylized detailed meshes + vertex colors/normals + modest roughness beats primitive capsules and excessive expensive shaders.

## Architecture sketch

```
res://
  project.godot
  scenes/
    main.tscn
    world/forest_clearing.tscn
    player/wretch.tscn
    shrine/temptress.tscn
    props/tree.tscn
    props/ore_node.tscn
    animals/hare.tscn
    ui/hud.tscn
    ui/inventory.tscn
    ui/shrine_menu.tscn
  scripts/
    main.gd
    player/player_controller.gd
    player/click_controller.gd
    world/forest_generator.gd
    world/grid_navigation.gd
    world/interactable.gd
    world/resource_node.gd
    entities/hare.gd
    entities/temptress.gd
    systems/inventory_model.gd
    systems/economy.gd
    systems/game_state.gd
    systems/balance_loader.gd
    ui/hud.gd
  assets/
    geometry/ (handcrafted generated meshes or source builders)
    materials/
    textures/ (small original generated textures)
    audio/
  tests/
  STATUS.md
```

Structure is a guideline, not a mandate to create every empty file in W1. Scene-driven reusable nodes rather than a huge monolithic script. Content and economic models must not be owned by HUD widgets.

## Point-and-click 3D game, planar logic

When click is not consumed by UI:

1. `Camera3D.project_ray_origin(mouse_position)` and `project_ray_normal(mouse_position)`.
2. Use physics raycast for interactable colliders, filtered by layers; priority to clickable targets, otherwise intersect a mathematical horizontal `Plane(Vector3.UP, 0.0)` (or ground collision if varying height).
3. If target is interactable, compute desired approach point outside its obstacle collider, start path to reachable adjacent cell, perform target action only when within reach; handle destroyed target/path obstruction gracefully.
4. If ground click, path to XZ point, clamped to bounds and nearest reachable waypoint; never blindly translate through a tree.
5. Use `AStarGrid2D` for a fixed deterministic 2D obstruction grid initially, mapping grid `(i,j)` to world `(x, 0, z)`. When obstacles/spawn change update blocked cells. No need to bake 3D NavigationMeshes in W1. Later change strategy only if justified.
6. `CharacterBody3D.velocity` x/z values from next waypoint, Y managed by gravity/terrain, `move_and_slide` and coherent facing rotation/animation.
7. Clicking UI is swallowed by Control mouse filters, not sent as world click. Right-click cancels. Pointer over distant objects gets feedback.

**No pseudo pathfinding** (straight-to-click through boulders is not acceptable). Verify 5 click navigation cases: open ground, tree beyond rock, moving hare, core behind a tree, rapid target switching.

## Core and economy APIs

Pure data functions: `can_feed`, `can_craft`, `can_heal`, `can_smelt`, `try_transaction`. Maintain count, weight and slot constraints from one inventory model. Service request returns a clear success/failure enum or object; both inventories and Sat update atomically only after all checks. Use signals `satisfaction_changed`, `inventory_changed`, `core_state_changed`, `interacted`, `resource_depleted` to inform UI.

Cooldown/throttle mouse operations to avoid duplicate feeding on double clicks. Feeding accepts 1 raw meat, restores 4 Sat (clamped to cap) and must also work at Sat=0. Preserve no-free-resource exploit on repeated action.

W1: Save not mandatory but domain data should be serializable. W2: `user://save_slot_1.json` atomic save with temp file rename, explicit version, seed, position, full inventories, owned shrines, satisfaction and timers; do not serialize engine Nodes. Handle malformed/old version safely.

## Art generation pipeline

Potential installed tools in WSL:
- **Godot built-ins are REQUIRED**. Custom authored geometry generated using SurfaceTool/ArrayMesh/ImmediateMesh or authored .tscn meshes with careful curved profiles, shape variation and baked/accessory parts.
- `python3` or installed Pillow may produce original small terrain textures/noise atlases for use by Godot, but do not require online downloads. Can generate in-editor via NoiseTexture2D; check Godot API version.
- **Blender is OPTIONAL**: if `command -v blender` succeeds, agent may use headless Blender Python (`blender -b --python ...`) to generate polished original .glb static models. If missing, do not auto-install huge packages or stall waiting. W1 must render with just Godot.
- **Asset-review checkpoint:** produce actual screenshot via available desktop/GUI/screenshot tools if possible; inspect. If tools cannot capture GPU-backed graphics, mark as unverified and ask user for screenshot/approval. Never substitute unseen headless logs for artistic evaluation.

Recommended unique authored visual families W1: 1 temple creature custom curved mesh; 1 detailed wretch; 1 detailed hare; 2 pines + 1 stump variant; 1 ore rock cluster; dirt path patch; 5–8 small scatter props. Instance variants with noise instead of generating 50 distinct full designs.

## Rendering performance and fallback

- Start 1280x720. Orbit disabled. Static DirectionalLight3D plus few local lights where supported. Moderate shadow settings. Simple fog trick from world Environment or distant desaturated background if compatible.
- Use meshes rather than dense particle forests. Grass and pebbles can use MultiMeshInstance3D; avoid thousands of individual Physics bodies; collisions only for major blockers.
- Keep draw distance and world size small in W1. Cross platform compatibility more important than fancy WSLg-only effects.
- If Compatibility visuals look bad due to driver issues, test alternative renderer only with user's knowledge; note required restart/project setting differences. If WSL GUI cannot work, let Codex validate headless and user run GUI in Windows Godot native against WSL path. Do NOT silently rebuild everything as a 2D scene.

## World generation later

- Deterministic integer chunk key `(cx,cz)` and seed; world chunks e.g. 32x32 logical cells, streaming 3x3 around player. Stable world positions independent of exploration order.
- Biome determined by low-frequency seed noise (temperature, humidity, distance) with region-level patches, no random per-tile crazy quilt.
- Avoid per-chunk arbitrary spawn if that can strand the player: guarantee traversable corridors and food near each allied shrine.
- Save sparse deltas for changed nodes, barricades, core ownership, totems, golems, state. Chunk unload does not reset resource inventories.
- Mini-map samples logical world grid and visited-cell fog of war. Minimap is part of W4, optional tiny first-stage directional hint.

## Testing, trust and safety of claims

Run every time after meaningful work:

```bash
godot --version
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 60
```

The commands may use `--rendering-method gl_compatibility` or equivalent if supported. Examine stdout/stderr, return codes. If scene scripts throw runtime errors, repair. Test code can be scripted as headless pure GDScript tests with exit status but must not pretend this validates visuals.

For human validation press F5 in `godot --editor --path .` and inspect: scene composition; shrine readability; click-to-move; interaction; resource drops; feed; 0 Sat revival; UI legibility. Report honestly which were not observed.

## WSL hygiene

Keep project under `~/projects/Tempters` on WSL native ext4 instead of `/mnt/c` for better file I/O. `godot` and `codex` should be resolved from the same WSL terminal. No background services. Store config with examples; do not rewrite `~/.codex/config.toml` without user approval. Never require .NET.

## Implemented persistence and defense

SaveStore schema 3 includes all character resources, equipment, Health, Satisfaction, levels, offerings, resource depletion/renewal timers, player position, structures, golem/raider IDs and Health, guard positions, attack cooldowns, raid phase/timer/wave, capture progress, pending rewards, rescue immunity and shrine ownership. Schema 1 migrates to empty buildings, then schema 2 migrates to a fresh combat state with 360 seconds of preparation. No offline simulation occurs.

Validation precedes live-state mutation. Invalid player positions can relocate to the protected southern lane only if the entire resulting snapshot validates. Unsupported or incomplete data is rejected. Each replacement preserves the prior valid slot as .previous. Invalid originals receive timestamped .rejected backups before explicit replacement. Automatic fallback and F8 recovery preserve the current slot as a .recovery copy and suspend autosaving until F5 confirmation. Writes flush a temporary sibling before atomic rename. The initial user-data directory backup is recorded in STATUS.md.

Loading reconstructs physics/navigation, units and ownership. It clears transient movement/attack/deploy/placement requests, UI locks, paused state, time scale, ritual animation, player velocity and working state. No transient input lock is serialized. Prey use pickable layer 8; actors layer 16; fixed blockers layer 2. Player and combat units collide with fixed blockers only, avoiding dynamic actors wedging the rounded A* start waypoint. Camera picking includes all three layers.

CombatDirector owns bounded raid transitions, targeting and combat. CombatUnit owns locomotion and limb animation; original meshes are built once in CombatArt. Units replan on a 0.7-second interval. Raiders attack shielding barriers; destroyed structures rebuild navigation. Maximum three golems, five raiders and one warning scout limit AI cost. Occupation supports free reclaim and bounded enemy withdrawal; player defeat restores control at the protected approach.

Graphical play saves after transactions/state transitions, every 30 active seconds and on normal close. Barrier damage uses periodic saving; destruction saves immediately. Tests use disposable slots and headless smoke runs disable persistence. tests/verify.sh enforces per-process timeouts and detects Godot error output as well as exit codes. Tests include exact-save diagnosis, repeated movement reloads, concurrent combat persistence and separate-process occupied-world restoration. Headless checks do not certify visual quality; rendered evidence is recorded separately.
