# TEMPTERS — Acceptance & Visual QA (Honest Checklist)

W1 does not pass automatically when headless import passes. This checklist is for agent + user; check with real running scene and record results in `STATUS.md`.

## Quality (look at a 1280×720 screenshot)

- [ ] First glance: original high-contrast dark fantasy **2.5D handcrafted diorama**, not a flat vector game.
- [ ] Shrine is unmistakably **vulva-inspired as a sculptural fantasy organism**, recognizable without relying only on pink + glowing line; paired layered ridges and recess; no radial flower/eye structure.
- [ ] Shrine is largest and brightest narrative focal object, its lower roots embed in the ground.
- [ ] Hero visibly has a hood/head, torso, limbs and satchel; appears to walk instead of sliding.
- [ ] Hares have obvious ears, legs and hop animation; trees have dimensional trunks, root base, believable irregular crowns; ore appears mineral not button icon.
- [ ] Landscape has nuanced soil/grass/path, debris, soft spatial depth, light/shadow/contact grounding. Not one solid green rectangle or random confetti grass.
- [ ] HUD is readable, distinct, intentionally styled and doesn't occlude shrine / player. World clicks won't fire when interacting with HUD.
- [ ] Animation: idle shrine visibly breathes, fed shrine visibly reacts and a piece of food is represented moving toward the slit or a short clear feed effect.
- [ ] Gameplay camera actually presents tilted orthographic 3D world. No perspective zoom distortions or free camera.
- [ ] Scene remains readable even with emissive lighting reduced and as 160px shrine thumbnail (manual approximation acceptable).

## Writing review — required for every milestone

- [ ] All UI, world labels, dialogue, tooltips, objectives, notifications, data and generated text follow WRITING_STYLE.md.
- [ ] Text is useful, concise and readable; routine actions do not trigger commentary.
- [ ] Personality and emergent humor come from behavior and environmental storytelling.
- [ ] Future prompts and documentation contain no conflicting writing instructions or reaction quotas.
- [ ] Costs, gains, warnings and gameplay information remain accurate after text edits.

## Functionality

- [ ] `godot --version` executes from WSL; `godot --headless --path . --editor --import --quit` exits without unhandled errors.
- [ ] F5 launches main scene in GUI. *If not GUI-tested, mark unverified instead of pass.*
- [ ] Click navigable ground => player moves smoothly; clicking on a UI button does not move player.
- [ ] Click tree/rock/prey => path to interaction distance, action once; no clipping through blockers.
- [ ] Hunt hare => +1 raw meat and +1 hide, or correct explicit drop; UI bag changes only once.
- [ ] Click shrine => approach, clear feeding action. Feed 1 meat => meat −1 and Sat +4 (capped) exactly once.
- [ ] Sat declines with elapsed simulation; at 0 feeding works and services (when they exist) are dormant.
- [ ] Bag capacity enforced and communicates full state; no negative resources.
- [ ] Repeated rapid clicking doesn't duplicate meat, rewards or transactions.
- [ ] Small clear spawn has reachable trees, prey and ore, so no early unwinnable state.
- [ ] Save/load (W2 onward) works after exit/reopen; no object respawn exploits.

## Reviewer red flags (reject even if it technically runs)

- Shrine resembles pink eye in the center of petals, UFO, logo or bubble gum oval.
- Default gray capsules / cones / spheres used as finished hero, animals, trees and shrine.
- Beautiful still screenshot but no actually working W1 controls and feeding.
- Fake progress report claiming 'screenshots visually inspected' without displaying/capturing them.
- Renderer output fails under user's WSLg and fallback silently converts game to 2D.

## Test report template

```
W1 gameplay: PASS / FAIL / UNVERIFIED
W1 visuals: APPROVED BY USER / NEEDS ITERATION / UNVERIFIED
Headless import: PASS / FAIL, command and key output
GUI F5: PASS / FAIL / NOT TESTED
Bugs and workarounds: ...
Next single bounded task: ...
```
