# TEMPTERS — Agent Contract (READ FIRST)

Continue the existing TEMPTERS Godot project in this directory. Preserve the user-approved 2.5D visual direction, environment and central creature. Do not recreate the project or start another milestone unless requested. The visual result must be a crafted, dimensional dark-fantasy diorama, not flat debug shapes, simple circles/triangles, or a central shrine that reads as a flower or eye.

## Permanent writing policy
Read and follow [WRITING_STYLE.md](WRITING_STYLE.md) before editing any text. It governs all runtime strings, generated content, documentation and future prompts without exception. TEMPTERS is dark fantasy survival; personality and emergent humor belong primarily in behavior, animation and environmental storytelling. Use concise functional UI and remove unnecessary commentary.

## Authoritative reading order
1. `WRITING_STYLE.md` — mandatory writing policy; then `ART_BIBLE.md` and `CORE_CREATURES.md` — art identity and visual acceptance criteria.
2. `GAME_DESIGN.md` — gameplay identity and entire progression.
3. `TECH_ARCHITECTURE.md` — implementation choices, WSL environment.
4. `ECONOMY_BALANCE.json` — tweakable first-pass economy.
5. `MILESTONES.md`, `QA_VISUAL_CHECKLIST.md` — what to deliver, how to test.
6. The prompt matching the explicitly requested task. `PROMPTS/01_START_FRESH.md` is for initial bootstrap only. All prompts are subordinate to WRITING_STYLE.md and the design bible.

## Non-negotiable design decisions
- Engine: installed **Godot Standard 4.7.2 if available**, using **GDScript**, no C#/.NET, no Unity, no web game, no multiplayer.
- Presentation: **3D-rendered 2.5D orthographic diorama**, not a flat 2D TileMap, while **gameplay is strictly planar X/Z**. Use `Camera3D` + `CharacterBody3D` / physics bodies, `Control` HUD, camera raycasts for clicking.
- Visual ambition: a **distinctive authored diorama** with readable 3D shapes, depth, grounding shadows, material variance, hand-crafted detailing, controlled focal lighting and visual hierarchy. Nothing is 'finished' if it only resembles flat debug geometry.
- Core visual: **vulva-inspired organic living shrine**, unmistakable in broad stylized shape, not a flower, not an eye, not a portal icon. Do not make anatomically photographic genitalia; keep fantasy-grotesque abstraction. This is a fixed environmental creature, not a human NPC. Do not make nudity or sexual animation.
- Player's role: unwillingly dependent servant to a demanding, ravenous living base. All major gameplay loops connect to feeding, services, protection, bond range, jealousy and rare new Temptresses.
- Single-player opponent NPCs only for initial development.
- Original code and assets only; never rip existing game art.

## Visual gate — stronger than feature count
**Milestone W1 is not complete without an intentionally designed visual composition**, not just functional placeholders. Stage an attractive initial clearing, central shrine, player, 1 large tree + variants, rabbit/prey, ore/stone. Use procedural mesh authoring, distinct materials, selective textures/noise and proper lighting. Native Godot meshes/materials/shaders are acceptable when custom shaped and carefully composed. Blender scripted offline mesh authoring is OPTIONAL only if installed; never let missing Blender block completion.

Main screen expectations at 1280x720:
- Shrine reads as dominant focal element (roughly 220–340 screen pixels tall, depending on camera framing), with visible nested folds, central vertical slit/seam and a small upper crown/hood feature; ground integration with organic roots and ring of offerings.
- Protagonist is a recognizable short hooded or masked scavenger silhouette with head/body/limbs/tools/backpack, not a cylinder or a circle.
- Trees show layered trunk/root/canopy character with depth and irregularity; prey have identifiable silhouette and animation.
- Terrain is NOT a flat uniform green plane: multiple ground material regions, path, height/vegetation variation, small debris, occasional moss, edge dressing.
- Lighting and shadows feel grounded; palette avoids uniform black or neon pink overload.
- Personality and emergent humor come from animation, behavior, decisions and environmental storytelling. Labels and UI convey necessary gameplay information only.

## Implementation discipline
- Start with a playable `project.godot`, `scenes/main.tscn`, clean modular script architecture and `assets/` organization. Prefer committed assets/files over generating a huge random 3D mesh every frame. Procedural geometry can be built once and cached/instanced.
- Preserve responsive click-to-move with scene-object approach + interaction; never permit HUD clicks to walk character. Path around physical obstacles with a deterministic XZ-grid A* if needed; validate visually and via reproducible tests.
- NO full procedural infinite world in W1. One curated or seeded handcrafted-looking forest clearing, guaranteed resources and traversable lanes, is better.
- Bind numeric values to `ECONOMY_BALANCE.json` or mirrored data resources; centralize state and validation; don't hide hardcoded values across UI widgets.
- Any service transaction is atomic; feeding always possible from dormancy; zero resource softlocks are unacceptable.
- Keep machine-friendly checks: `godot --headless --path . --editor --import --quit`, `godot --headless --path . --quit-after 60` (adjust for environment), plus optionally reproducible game-state tests. Headless does NOT certify visual polish.
- Default renderer can be Compatibility for WSL if necessary; choose a compatible lighting/material workflow and verify GUI. Do not silently sacrifice 3D depth by changing the game to 2D.
- No auto `sudo`, no dangerous commands outside workspace, no unapproved system-wide installs, no `git reset --hard`/destructive cleans. Assume owner may have files to preserve.
- Keep CPU/GPU budgets sensible: instancing/multimesh for repeated foliage, capped particles, limited shadow lights, deterministic seeded procedural placements.
- Commit a verified milestone if Git is initialized and user has approved repository ownership; otherwise advise user of commands. Always update `STATUS.md` with accurate implemented vs missing behavior, visual caveats, test commands/result and next actions.
- When stopping early, leave a runnable vertical slice, not an unbuildable half-feature. Do not claim GUI/screenshot inspection unless actually performed.

## Communication
- Work on real files; don't deliver mere pseudo-code, plans or mockups instead of game implementation.
- Concise final report of what worked, what is unverified, and an explicit next action.
- Do not silently make promises about Codex five-hour/week usage. The user monitors limits themselves.
