# PROMPT 03 — Economy + defense (use bounded substeps)

Follow [WRITING_STYLE.md](../WRITING_STYLE.md) without exception. Convey personality and emergent humor through behavior, animation, player decisions and environmental storytelling. Keep text concise and functional; do not add forced jokes, routine commentary or unnecessary dialogue. Preserve the approved visual direction and central creature.

Read all project docs and STATUS.md. Do NOT assume W1 visuals are accepted: if W1 visual gate is unverified or failed, do `PROMPTS/02_VISUAL_REVIEW.md` first instead of new features.

**Part A — W2**: Implement a coherent Temptress service menu, costs shown up front, atomic recipes, ore -> ingot smelting, axe, spear, armor starter, backpack upgrade, healing ritual animation, core leveling/max Sat, capacity, save/load with schema version. Keep Sat dependence severe and meaningful. No remote smelting/healing bypass. Test all insufficient Sat/materials/capacity cases. Update docs/status and checkpoint.

After W2 passes, stop at its verified checkpoint. **Part B — W3 requires a separate explicit user request**: add placeable fences, totems with diminishing returns, stone golems, limited intelligently pathing rival NPCs, warning + 1 staged fair raid, 10s capture channel, temporary occupation and reconquest. Visually keep same high-quality 3D diorama style and unique design language for golems/raiders. Test not getting stuck, zero Sat recovery, safe raider warning, and that initial W1 loop remains playable.

Do not rush through Part A to implement half-functional W3. Stop cleanly if quota exhausted. Run Godot tests, update STATUS.md, tell user next step.
