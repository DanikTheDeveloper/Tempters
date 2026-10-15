# CORE CREATURES — Silhouettes, Anatomy-inspired Form, Animation and Behavior

The living shrine is the **star**. It must visually communicate a grotesque quasi-divine creature and a recognizable **vulva-shaped organic structure**, not generic occult flowers or glowy portals. Its design is deliberately fantastical, not a human anatomy plate or sexual depiction.

## Readability tests

**Test 1: thumbnail / grayscale.** Reduce the rendered shrine to about 160 px high, no emissive light. Two overarching fleshy outer ridges frame a single long narrow recessed vertical cleft. Inner folds give depth. Crown forms a small distinct nub at the upper pole. If the form becomes a radial flower, eye, symmetric disc or indistinct blob, REJECT.

**Test 2: gameplay framing.** The shrine is large, upright/angled toward camera and mounted to an irregular mound/roots. It dominates visually relative to the scavenger. Keep front-plane broad enough to read from orthographic camera; do not bury it in dense vines or glowing particles.

**Test 3: color neutral.** Core must stay readable even without pink and emissive seam; silhouette and shading do the work.

## Modular shape kit

- Root/mound: an irregular living raised bed with stone/organic ribs tying into terrain; broken bronze offering circle around it (not a perfectly perfect ring).
- Outer folds: pair of elongated asymmetric crescent-like loft meshes with irregular width, shallow waveforms, muscular volume, muted dusty-rose highlights and dried-plum occlusion. Their visible rims move with breathing.
- Inner folds: inset pair of narrower rippling fleshy ridges, lighter material, separating the outer mass from central fissure.
- Fissure: recessed, tall narrow dark seam that tapers vertically, pearl rose internal glow attenuating toward center, hidden emissive core; it should look like depth, not a luminous flat stripe.
- Hood/crown: small asymmetrically arched fleshy upper cap with a tiny round protruding bead as a visual focal detail; proportion small relative to overall shrine.
- Wrinkles and surface: irregular geometry bands/scars, painted mottling by vertex color/noise or material; specular highlights restricted to wet edges.
- Anchors: fibrous tendons/roots attaching sides to rocks/earth, 2–3 votive bowls, bone chimes and a weathered plinth.

**Authoring recommendation:** custom procedural loft/ribbon meshes following a spline-like spine and variable cross section (SurfaceTool/ArrayMesh). Do not achieve this by arranging basic sphere/capsule primitives with no sculpting. Procedural script builds once as a cached static or skinned mesh and animates subtle idle using shader/time or a few nested animated mesh root transforms. Choose material/shading mechanisms available in Godot Compatibility mode if that renderer is used.

## States

| State | Form/ambient reaction | Gameplay |
| --- | --- | --- |
| Content (70–100%) | calm slow flexing, rich inner glow, occasional warm motes | all available services |
| Impatient (30–69%) | quicker breath, occasional tense contraction | all services if affordable |
| Furious (1–29%) | tense contraction, darkening fold shadows, harsh bells | low Sat warnings |
| Dormant (0%) | collapsed relaxed shape, extremely dim seam, one intermittent twitch | feed ALWAYS accepted; paid miracles disabled |
| Fed | incoming meat swallowed into depth; expansion pulse then exhale | +4 or food value, inventory -1 |
| Craft | ribs brace, grinding reverberation, sparks/debris at output receptacle | pay resources+Sat atomically |
| Heal | stylized magical plunge/fade silhouette and reappear (non-sexual) | Sat cost, HP restored |
| Threatened | defensive tightening, red silhouette edge, bell alarm | raid nearby |
| Occupied | foreign faction banner/seal overlays ritual stones; still same creature | reclaim mission |

Ambient animation should be eerie and expressive, like irritated breathing — never explicit sexual movement.

## Biome variations retain the same base shape

1. **Widow of Roots (Forest)**: mossy bronze ribs, rose-plum folds, sap beads, root lattice. Expresses impatience through breathing, posture and response to offerings. Starter core; most polished W1.
2. **Saffron Oracle (Desert)**: sandstone base, turquoise mineral veins, gilded beetle charms, ochre/russet organic folds, sharp headpiece; oil-lamp glow. Smelting specialist.
3. **Frost Matron (Snow)**: translucent pale-lilac ridges, rime hanging on rim, ice-gold crests, cracked porcelain mound; slow breath emits mist. Bond range specialist.
4. **Mire Empress (Swamp)**: deep aubergine/teal flesh, translucent algae drapes, phosphorescent spores, bone bells. Totem specialist.
5. **Ember Sovereign (Volcanic)**: charcoal-cracked dark folds with orange subsurface fissures, obsidian crown, scorched offering dais. Golem/metal specialist.

## Proportions at W1 staging

- Shrine 4.5–6× hero's in-world height; 2.8–4× the visible screen-space hero-height depending on perspective.
- Main central inner cleft 50–65% of shrine visible vertical extent.
- Paired outer fold curves together account for 50–70% of shrine readable width; slight variance from side to side to avoid flower symmetry.
- Hood 10–15% shrine width.
- Votive plinth, altars, offerings and roots around base should imply scale, not obscure shape.

## Interaction feedback and grounding

The player brings meat home and throws it into the shrine. Feeding is confirmed by its physical reaction, the inventory change and a brief Satisfaction gain. Invalid food receives a concise requirement message only when needed; stone may still be accepted by a separate recipe if specified. Large Satisfaction expenses cause a visible slump. Every reaction must correspond to a clear state change. Follow WRITING_STYLE.md: personality comes primarily from behavior and animation, without routine dialogue or commentary.

## W3 implemented defensive behavior

The living shrine reacts to summoning and occupation through its existing pulse animation; an adjacent rival banner marks occupation. Ten uninterrupted seconds of enemy channeling capture it. Feeding and healing remain possible while occupied; crafting and passive totem output resume after a free ten-second reclaim once raiders are defeated or withdrawn. No dialogue barks are added. Original creature geometry and materials are preserved.
