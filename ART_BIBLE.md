# TEMPTERS — VISUAL BIBLE — CURSED RELIQUARY

## The new vision

**A beautiful, expensive-looking miniature of a revolting place.**

Think of an original, handcrafted **dark-fantasy tabletop diorama** filmed by a slightly tilted **orthographic camera**. A strange world of lacquered bark, tarnished bronze, dirty bone, cracked porcelain, damp stone, deep moss and softly luminous living tissue. The palette is sophisticated rather than saturated, the silhouettes are exaggerated and characterful, and the lighting makes every object feel tangible.

Keywords: *2.5D*, *orthographic 3D*, *macabre storybook*, *handmade miniature*, *votive relics*, *ritual unease*, *tactile materials*, *subtle organic unease*, *unsettling dependence*.

NOT: flat vector debug shapes; pixel art; random primitive meshes; cheerful mobile farming graphics; plastic neon shaders; photorealism; direct imitation of Cult of the Lamb/Don't Starve/any existing title; gloomy underlit mud with no readable objects.

## Camera and framing

- Actual Godot `Camera3D` with `PROJECTION_ORTHOGONAL` over the X/Z movement plane; maintain a **consistent 50–65° angle above the ground** (a slightly angled top-down view; not an isometric grid forced on controls).
- Keep the hero within a legible range: perceived hero height ~55–85 px at 1280x720 (final camera tuned by actual GUI viewing). Central altar 2.8–4.0 times hero's height.
- The altar fills the central composition at spawn; player begins below it on a narrow worn approach path. Foreground elements frame the view; no trees obscuring altar or player in first frame.
- Smooth camera follow with clamped framing near core; moderate mouse-wheel zoom. Avoid motion sickness; no full 3D free-look.
- Small base area is carefully art-directed: luminous center, medium-value midground, deep-value perimeter, a warm path bringing eye to central shrine.

## Central shrine: non-negotiable silhouette

The core design is **not made by stacking ellipses and triangle petals**. Use an irregular grounded 3D sculptural mass with **two prominent asymmetrically curved, elongated paired external folds**, **smaller layered inner fold ridges** and a **narrow recessed central vertical fissure**, tapering toward the lower end, capped by a **small upper hood/crown nub**. Surfaces are convex at their outer edges, concave toward the opening, with organic color variation, wrinkles, little scars, moist specular accents and slow breathing displacement. The overall silhouette must clearly evoke a **vulva-shaped dark-fantasy living shrine** without literal human anatomy, exposed human body parts or pornographic depiction. The subject is a huge stationary fantastical organism rooted into the earth. Do not replace it with an eye, flower, iris, rosebud, tentacle monster or symmetric portal frame.

Prefer authoring **custom ribbon/loft meshes** with controllable curvature, width and multiple rings, plus noise/vertex offsets and normal shading. Shape silhouette first in neutral clay material, then add surface layers, emissive seam, root plinth and offering circle. Use actual normals, shadows, AO-like contact shading where supported, and carefully tuned roughness. Avoid 100 tiny tiny particles hiding the structure.

Final in-world size for W1: approximately 4.5–6 hero heights high. Monument may be slightly leaning/upright against mound, rather than a flat decal facing straight down, to preserve silhouette under tilted orthographic camera. It should clearly belong to the ground, with organic roots/ribs and a worn circular ritual path.

## Character art

### Player — The Scavenger
- Small adult cartoon scavenger with a mushroom-like hood or ragged rain cloak, long thin boots, chunky bag, tiny gloved hands, chest lantern/charm, face partly obscured by pale oval mask.
- Three-dimensional silhouette visible at gameplay scale: oversized pack, one bent shoulder, readable legs, distinctive head-to-torso proportion. Not a stick person, disk, capsule or single cone.
- Idle weight shift, 4–8 key-frame style walk gestures or procedurally animated limb pivots, believable locomotion, tools that visibly swing on actions, rim highlight on hover/selected targets.
- Expressions conveyed by posture/eye dots in mask. Not realistic humans or detailed adult anatomy.

### Hare
- Recognizable elongated ears, stout rump, short forelegs, tail, curious posture; not two white dots above a blob. Variants: gray-brown and snow-hare later.
- Hop animation and brief prey panic when approached; visible hit reaction and usable drop marker.

### Enemy — The Raider
- Hooded rival with brass mask and long polearm; visually unlike the player; slow heavy walk and ritual capture channel later.

## Environment geometry/materials

**Ground**: uneven but navigable flat-ish sculpted floor patches, moss clusters, sparse tufts, exposed soil, veins of roots, stone chips and irregular muddy path. The collision/navigation XZ plane remains predictable; visual micro-geometry mustn't obstruct pathing.

**Pines**: tapered irregular bark trunk, root flare, layered drooping needle masses with variation/no perfect triangular stacks, dark underside, pale lichen patches. Mix in a few crooked dead birches. Trees should cast shadows.

**Rocks/ore**: chipped faceted stone clusters, roughness variance, mineral seams, distinct silhouette between plain rock and metallic ore. No single hexagonal icon.

**Props**: upside-down cracked cups, wax puddles, small ossuary stakes, loose bones, rope scraps, bronze rings, weathered wooden signs. Sparing but character-rich.

**Surface/material**: avoid uniform base color; subtle noise from vertex colors/procedural material variation, at least 3 coordinated tones per major asset family, purposeful metal/ceramic/bark/flesh distinctions. Optional Blender low-poly modeled+UV assets are permitted if Blender is already installed, but all W1 art must be creatable with stock Godot and scripted ArrayMesh/SurfaceTool meshes.

## Lighting

- One soft angled directional key; soft ambient fill; shrine-side warm/cold contrast (muted candle amber versus bruised pink-violet, NOT pure magenta everywhere).
- Plausible directional shadows from large props. Small point lights near offerings if Compatibility can support them; performance-budgeted.
- Scene readable in daylight/dusk; texture and depth should read at 720p without bloom.
- Visual contact shadow under creature, trees, and player (native if possible, subtle fake shadow decal otherwise).
- No Forward+-only feature should be mandatory for first playable WSL build.

## Palette / contrast

| Role | Color | Hex |
| --- | --- | --- |
| deepest forest shadow | pitch spruce | `#192923` |
| foliage middle | jade moss | `#536854` |
| wet soil | rust loam | `#695449` |
| bone highlights / UI text | old ivory | `#E7D9BF` |
| antiqued brass | dirty gold | `#B59658` |
| shrine deep folds | dried plum | `#56324B` |
| shrine living surface | muted rose | `#BD738C` |
| inner fissure light | pink pearl | `#F5B0B7` |
| danger/raids | oxidized vermilion | `#B64F44` |
| frost accents | blue slate | `#8CACBF` |

Target high contrast at object boundaries; magenta is local, never the entire screen. Material response differs by object type: bark matte; old porcelain semi-matte; amber/slime locally glossy; metal with restrained speculars.

## UI: clear dark-fantasy interface

- A legible 2D UI overlay on the 3D diorama. Preserve the existing brass lines, dark panels, ivory text and restrained material treatment. Follow WRITING_STYLE.md; this is visual styling, not a license for themed narration.
- HUD compact: Health, Satisfaction, Expedition Bond, bag weight and icons. Don't cover the center. UI must preserve scene readability at 1280x720.
- Use direct action labels, exact costs and brief useful warnings. Do not add dialogue to routine actions; let the environment and creature behavior carry the personality.
- On offer: visible meat prop arcs into seam, creature contracts/relaxes, +4 or configured popup, inventory counts update *once*, tiny sound/haptic feedback if available.
- At low satisfaction: shrine slowly darkens, smaller rhythmic contractions, nearby lanterns flicker, brief low-Satisfaction warning. At high satisfaction: fuller breathing, brighter slit edge, subtle relaxed motion. Never sexual motions or erotic audio.
- HUD text is readable and scalable. Use bundled permissive font if available with license or a reliable Godot default; no random system font dependency.

## Priority ordering / objective quality gate

1. **Framing and silhouette** are worth more than particles, complicated shaders or amount of features.
2. **Shrine and player** should sell the idea before resource nodes or UI embellishments.
3. **Ground depth and lighting** should signal expensive-looking world, not a cardboard illustration.
4. **Few excellent assets over dozens of primitive ones**; repeat assets only with rotation/scale/color variants.
5. **Actual running scene beats concept-only art**.

The agent must capture screenshots or use actual GUI observations if tooling permits. If unavailable, clearly mark the visual gate `UNVERIFIED — USER MUST INSPECT` and tell user where to focus. Headless Godot success does not prove art quality.

## W3 delivered assets

CombatArt adds moss-covered articulated stone golems, rust-cloth masked raiders with brass accents and polearms, and a cloth occupation banner. These use the existing sculpted mesh/material workflow and scene lighting. Walking, strikes and hit reactions communicate behavior; labels show only combat state. Approved environment and central creature geometry are preserved. Actual rendered evidence: captures/w3-combat.png.

## Permanent camera visibility and input contract

Large scenery must register render geometry with CameraOcclusion and its solid body with camera_occluder_body. Registration is reusable for trees, cliffs, walls and structures; collision/navigation must never be disabled to reveal characters. Test camera-to-character obstruction, smoothly fade only intersecting mesh groups to 35% opacity, retain a short visibility hysteresis, and restore the exact original material overrides. Never mutate shared source materials or use whole-character no-depth rendering. Compatibility is the baseline renderer.

InteractionResolver owns world picking. UI consumes input first; active construction handles placement; visible enemies and directly clicked occlusion indicators take priority over services. The shrine's solid collider is excluded from interaction picking; use its clearly marked Services hotspot. Ground behind it must remain navigable. Indicators identify nearby obscured enemies, separate overlapping targets and disappear when unobscured. Unregistered solid obstructions retain concealment. Selecting an obscured enemy never bypasses combat range or physical line of sight. All new scenery must pass rear-target, zoom, rapid-click, cancel and save/load visibility tests.
