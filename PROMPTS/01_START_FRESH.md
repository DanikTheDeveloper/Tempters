# PROMPT 01 — EXECUTE: TEMPTERS, fresh 2.5D Godot game

Follow [WRITING_STYLE.md](../WRITING_STYLE.md) without exception. Convey personality and emergent humor through behavior, animation, player decisions and environmental storytelling. Keep text concise and functional; do not add forced jokes, routine commentary or unnecessary dialogue. Preserve the approved visual direction and central creature.

You are the lead developer AND art director of TEMPTERS. Start making real project files IMMEDIATELY. This is the first build of a clean project named exactly **TEMPTERS**. No scenes, scripts, `project.godot` or visual assets exist yet. Do not assume any previous code or save files. Create everything needed inside this directory.

Read these documents **fully** before implementing:
- AGENTS.md
- WRITING_STYLE.md
- ART_BIBLE.md
- CORE_CREATURES.md
- GAME_DESIGN.md
- TECH_ARCHITECTURE.md
- ECONOMY_BALANCE.json
- MILESTONES.md
- QA_VISUAL_CHECKLIST.md

Do not make the central shrine look like a flower, eye, oval emblem or generic portal. Follow the sculpture and silhouette requirements in ART_BIBLE.md and CORE_CREATURES.md.

## Vision (extremely important)

Design a visually striking, genuinely three-dimensional-looking **2.5D dark fantasy diorama**. The game is top-down point-and-click with 2D movement logic, but the world should be rendered as **3D with a fixed tilted orthographic Camera3D**. Think tactility, matte bark, ancient stone, tarnished gold, organic tissue, subtle shadowing, grime, rich composed lighting, charming twisted characters, atmospheric prop details. Not photorealistic and NOT flat vector art.

The focal creature, the **Temptress**, is a HUGE stationary biological shrine, clearly **vulva-inspired** in stylized silhouette: paired asymmetrically curved external organic folds, secondary inset folds and a recessed tall vertical fissure, a small raised upper hood/crown, breathing rhythm and expressive irritation. A grounded earth-and-root structure, sculpted volume, shadowing, and a short ceremony whenever fed. Not a flower, eyeball, pink medallion, glowing stripe between circles, generic portal, anatomically photographic illustration or sexual animation. Build it as convincing original custom sculptural geometry with actual shading, preferably ribbon/loft meshes, not piles of basic ellipsoids.

The player is a distinct hooded/masked adult scavenger with satchel, arms, boots and walking/working poses. Hares have ears and hop. Pines show layered real depth, irregular foliage and bark, environmental debris, sculpted soil paths and cohesive lighting. HUD uses dark panels, brass lines and readable ivory text without dominating the image. Follow WRITING_STYLE.md for all wording.

## Implementation contract — W1 ONLY

Deliver a **playable and polished-looking** early vertical slice, not a 2D mockup, conceptual art, planning note, or giant unplayable pipeline.

1. Bootstrap real `project.godot`, functional main scene, reasonable camera, Compatibility-friendly renderer for WSL Debian 13 (Godot Standard, GDScript). Work entirely in this project folder; preserve docs.
2. Create forest starter clearing with directional lighting, materials, irregular path and terrain variation, 3D object silhouettes; stage a memorable shrine centerpiece occupying a substantial readable part of screen. Handcraft first view.
3. Create movable scavenger character, smooth `CharacterBody3D` planar movement, click-to-ground / click-to-interact using camera raycasts, grid A* or equivalent reliable obstacles/pathfinding. Mouse clicks on HUD never move hero.
4. Create pine/tree, rock/ore node and hare scenes with adequate dimensional quality and original animations. Clicking approaches and harvests/hunts, exact item drops are inventory-based (wood, raw meat, hide, ore and stone).
5. Deliver meat by interacting with shrine (1 meat removed, Satisfaction +4, clamp to cap), Satisfaction falls continuously by config. Feed always works when Satisfaction=0. Give clear feedback: food arc or transform, fold reaction, particles kept restrained, sound only if you can make a usable original sound.
6. Real HUD: health bar, Sat and status, backpack counts/weight, responsive labels and selected-object hint. Use concise functional labels and warnings; express shrine reactions through behavior and animation, not dialogue quotas.
7. A short instruction/onboarding text so a new player knows to click a hare, bring meat back and feed the shrine.
8. Actual Godot headless import/run validation and targeted system tests. Fix all parse/script/runtime errors you can reproduce; write `STATUS.md` detailing pass/fail and how to run.

## Art delivery is not optional

W1 cannot be described as finished if the hero is a cylinder, animals are blobs, environment trees are triangles, terrain is a flat rectangle, or the shrine resembles an oval eye/flower. Pay extra attention to silhouette, shape profiles, material layering, focal value contrasts and composition. These are mandatory acceptance criteria for the first build.

Allocate effort in this order:
(A) shrine shape + composed terrain + convincing 3D lighting,
(B) hero and fauna sculpted silhouettes,
(C) reliable click/gather/feed loop,
(D) UI/feedback & local polish.

Only once (A–D) are actually playable may you work on optional details. Do **not** add W2 smelting, W3 raids, W4 infinite map, multiplayer or tangential tooling now.

## Tools & constraints

- Godot executable expected from WSL PATH. `command -v godot; godot --version`.
- No .NET/C#, no network service, no forced external asset downloads, no unapproved system packages.
- Scripted Godot SurfaceTool/ArrayMesh custom meshes or GDScript mesh utilities are viable. If Blender is already installed, you MAY use offline procedural mesh exports, but never block implementation on Blender. Keep original assets reproducible and package necessary source files.
- Architectural discipline: small scenes, reusability, predictable seed, state separate from HUD, atomic inventory/feeding.
- Prototype asset loading should be quick and run on WSLg: avoid unnecessary GPU-heavy features and high-poly meshes. Do not 'solve' performance by reverting to a flat 2D game.
- Perform `godot --headless --path . --editor --import --quit` followed by a bounded headless run, collect errors. If screenshot/GUI interaction available, actually look at image and improve; if not, mark visual quality **unverified** pending user screenshot. Do not claim unseen art looks good.
- Preserve user's work and avoid deleting content outside this working folder.

## How to finish

1. Ensure project is valid and launchable via `godot --editor --path .` and F5, with honest notes about GUI tests.
2. Update `STATUS.md` using QA_VISUAL_CHECKLIST.md, including what IS and IS NOT implemented. If game is functional but art remains primitive, explicitly mark visual gate NOT passed and recommend running `PROMPTS/02_VISUAL_REVIEW.md`.
3. Optionally create a Git checkpoint after clean tests; don't commit secrets or caches.
4. Finish with concise summary of code/assets created, tests run, user play instructions, and next bounded visual improvements.

**START BUILDING THE GAME NOW. Do not respond with a plan as the deliverable.**
