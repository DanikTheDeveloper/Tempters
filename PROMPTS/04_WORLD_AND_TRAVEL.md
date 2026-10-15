# PROMPT 04 — World generation, bond distance, rare biome shrines

Follow [WRITING_STYLE.md](../WRITING_STYLE.md) without exception. Convey personality and emergent humor through behavior, animation, player decisions and environmental storytelling. Keep text concise and functional; do not add forced jokes, routine commentary or unnecessary dialogue. Preserve the approved visual direction and central creature.

Read all project docs and STATUS.md. Continue from tested existing milestone; preserve the original 2.5D orthographic diorama look and art standards.

First do **W4** as a bounded working feature: seed-stable chunk streaming, forest to desert and snow regional transitions; minimap, fog of war, distant landmark signals, dynamic biome resources. Implement Expedition Bond independent of Satisfaction, with distance/harsh-biome drain, clear warnings, fair emergency recall and backpack/material loss as specified. Core upgrades extend practical exploration radius. Save persistent harvested/constructed chunk changes. Validate deterministic generation across reload; no holes in pathfinding; no surprise instant travel softlocks.

Next do **W5** if feasible after checkpoint: add 2 rare unique beautifully designed biome shrines (Desert Saffron Oracle, Snow Frost Matron), each maintaining same distinctive paired-fold organic silhouette and their own art elements. Add NPC guarded capture/tribute, ownership, separate Satisfaction values, cheap first inter-shrine teleport with source and destination costs, and fast travel UI only between owned charged shrines. Re-run regressions, document any remaining world issues.

Keep map infinite-capable but performant; use instancing, sparse deltas and deterministic seeded chunks. DO NOT generate hundreds of thousands of live nodes or pretend map is seamless if it is not.
