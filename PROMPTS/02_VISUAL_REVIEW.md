# PROMPT 02 — Visually refine the running W1 before gameplay expansion

Follow [WRITING_STYLE.md](../WRITING_STYLE.md) without exception. Convey personality and emergent humor through behavior, animation, player decisions and environmental storytelling. Keep text concise and functional; do not add forced jokes, routine commentary or unnecessary dialogue. Preserve the approved visual direction and central creature.

Continue the existing TEMPTERS project. Read `AGENTS.md`, `ART_BIBLE.md`, `CORE_CREATURES.md`, `QA_VISUAL_CHECKLIST.md`, `TECH_ARCHITECTURE.md` and `STATUS.md`. Preserve all working W1 mechanics and item/economy state.

This is NOT a new gameplay milestone. It is a **hands-on art correction pass**. Evaluate the first implementation against the 2.5D diorama requirements and substantially refine any weak elements.

1. Inspect the current Godot scenes/materials/assets and, if available, capture real GUI screenshots at 1280x720 from the actual running game. If screenshots are unavailable, do NOT fabricate impressions: explain what user should screenshot.
2. Rework the central living shrine first if its broad silhouette resembles a flower, eye, medallion or stack of smooth ovals. It must show large asymmetrical paired organic folds, inset inner ridges, recessed vertical opening, small upper cap and earth-root integration; intentional fantasy grotesque, not human-realistic imagery. Rebuild custom shaped meshes when necessary.
3. Correct stage composition: shrine dominates, hero is legible, foreground props do not block player/feeding animations, coherent key/fill lighting and shadows, ground has microdetails and a worn path.
4. Improve player character's proportions and movement, recognizable hare and pine silhouettes, material contrast, text hierarchy, readable UI and interaction feedback. Avoid asset spam and uniform procedural random clutter.
5. Tune camera, FOV/orthographic size, scale and lighting for a rich 3D feel at 720p, but preserve the fixed planar click-and-move behavior.
6. Regression-test click pathfinding, gathering, meat delivery, Satisfaction at 0, inventory display and HUD clicking. Fix errors.
7. Update `STATUS.md` with before/after changes, actual tests and visual checklist; mention unresolved limitations candidly.

Priority: shrine geometry > camera/composition > character silhouettes > ground/textures/lighting > HUD decoration > extra particles. Do not start W2 before the user accepts the core look.
