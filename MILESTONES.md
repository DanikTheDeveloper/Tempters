# TEMPTERS — Milestones and Visual Gates

All milestones must follow [WRITING_STYLE.md](WRITING_STYLE.md) without exception. Preserve the approved art direction. Use clear gameplay information and environmental storytelling; no dialogue quotas or routine commentary. Milestone progression requires a user request; writing cleanup does not authorize W2.

## Five-hour windows are *planning buckets*, not quotas

A Codex usage window is not five hours of guaranteed execution. High reasoning, long context and big code changes can consume an allowance quickly. Stop when credit is low and leave a working checkpoint. **A convincing 2.5D visual W1 can be expensive**; don't estimate a fixed percentage of quota consumed.

## W1 — First 2.5D vertical slice [MANDATORY VISUAL GATE]

**Do now.** New Godot orthographic-3D project; good forest diorama; strongly vulva-shaped fantastical living shrine; distinctive adult scavenger; hares and gathering; click pathfind; functional offer-meat loop; real HUD; idle/feeding animations; tested Linux headless launch and GUI inspection if available.

Hard acceptance:
- You could show a still frame of the scene and it would show convincing volumetric forms, nuanced materials, appealing lighting and characterful composition.
- The shrine immediately reads as the massive organic centerpiece, not a magenta flower/eye. Grayscale silhouette pass matters.
- Player, hare, tree silhouettes identifiable at typical zoom with natural shading and grounded shadows.
- Running game: move to clicked ground and around objects; harvest, hunt, carry, feed; Sat falls; fed reaction is visible; zero Sat recoverable.
- No W2 features included at cost of unacceptable W1 quality.
- `STATUS.md` candid, screenshot if tool supports.

If art not ready: **DO NOT mark W1 done or start W2**. Use `PROMPTS/02_VISUAL_REVIEW.md` until user confirms.

## W1b — User-facing visual QA / iteration

Review actual screenshot at 1280x720, fix composition/materials/fold silhouette/tree/hero; improve animations, shadows and UI clutter; preserve W1. Optional separate window. Git checkpoint when approved.

## W2 — Miracles, logistics, saving

Menu costs and recipe preview; ore smelting to ingot; axe/spear, improved bag, heal via shrine, 1–5 core leveling and Sat cap; robust inventory/transaction model; real save/load. Polish interaction feedback. No service bypass of hunger mechanic.

## W3 — Siege economy and defense

Place wood fences, totem farm with diminishing returns, golem defenders; raid cues; rival NPC scouts, pathing, combat and channeling capture; temporary loss/reclaim loop. Concise threat warnings. Fair threat ramp and no hardlocks.

**Implemented and verified.** Construction, maintained totems, paid golem defenders, equipped player combat, rival scouts and escalating raids, interruptible capture, temporary occupation and free reclaim are playable. Schema-v3 saves preserve actors, structures, raid timers and ownership; W1/W2 saves migrate with full preparation time. The persistent movement bug is reproduced and fixed. See STATUS.md for test evidence and remaining balance/platform limitations. W4 is implemented and player-approved; W5 is now authorized.

## W4 — Frontier generator and distance

Deterministic seeded 32x32 world chunks; mini-map, fog of war; Forest/Desert/Snow transition plus resource distribution; Bond drain by radius/distance + world conditions; emergency return with loss; upgrade cores and bag allowing longer expedition.

## W5 — Other Temptresses and transit

Rare desert/snow shrine, their own iconography and Sat meter. NPC claim contests. Establish 2+ owned hubs, unique benefits and distinct demand clocks; fast travel with source + destination Sat costs, transactional + UI route selection. Claim 3 shrines progression goal.

## W6 — Personality and diversity

Swamp/volcanic, jealousy, demands, totem maintenance, special prey, hazards and richer rival strategies, audio design and events. Express personality and emergent humor through creature behavior, animation, player decisions and environmental storytelling. Preserve core game accessibility; no overwhelming grind.

## W7 — Balance + shipping

Gameplay metrics and difficulty sliders, optimization of instancing/chunk streams, regression tests, full save migration, detailed player onboarding, accessible UI, Linux and Windows builds, license inventory and a demo package.

## Session cadence

After each verified checkpoint:
1. Run tests, inspect if possible, list caveats.
2. `git add . && git commit -m "W1: functional 2.5D vertical slice"` (adapt message per milestone, only if repo initialized/configured).
3. Check Codex `/status` and decide whether next milestone fits.
4. Resume from `STATUS.md` and the matching prompt. Never pass an entire enormous monolithic task with 0 tests.

The priority is **the game you can play and enjoy**, not maximizing consumed quota.

## Current W2 completion

W2 remains implemented and verified: atomic crafting/smelting/healing, seven equipment upgrades, five shrine levels, recipe previews, capacity enforcement and service effects. W2 schema-v1 saves migrate into the current schema-v3 defense build. W1–W4 are implemented and player-approved; W5 is the current requested milestone. See STATUS.md for actual tests and caveats.
