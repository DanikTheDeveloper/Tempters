# TEMPTERS — Complete Gameplay Bible v2.0

## One-sentence premise
An absurdist, ruthless survival/expedition/base-defense game in which your one indispensable workshop, hospital, teleporter and protector is a ravenously demanding **living shrine** you must keep fed. Survival depends on maintaining that relationship while exploring and defending the clearing.

## Fantasy and emotional hook
You are an adult scavenger dependent on the Temptress for survival. You roam the map harvesting, hunting and mining, carrying offerings home. She grants miraculous services at ruinous Satisfaction prices. Every second spent adventuring risks an empty hunger meter, a severed Expedition Bond and rivals stealing your living workshop. Your base is a living creature with needs of its own.

Genre: solo PC, real-time 2.5D visually / **2D planar systems**, point-and-click, survival crafting, dark fantasy with absurd and provocative themes, light base defense, open-ended procedural exploration. The creatures are static beings embedded in the terrain, not human NPCs. An overt vulva-inspired visual metaphor is intentionally part of the fantasy grotesquerie; no sexual gameplay interactions.

## Non-negotiable player experience
- Click ground to walk. Click resources and enemies to approach and interact/attack; click core to approach and present menu. Stop/chase behavior predictable, with reachable-point pathfinding.
- Entire loop is about **feeding and serving your home creature**: no portable free forge, auto-heal or trivial instant teleport that bypasses core dependence.
- Carrying capacity is modest. A successful expedition requires inventory prioritization, route planning, and the decision to retreat and deliver food before the core grows angry.
- Distinct resource trips: meat & hide from hare/deer/boar; wood from trees; stone and ore from deposits. Metal comes from ore processed by the Temptress at Satisfaction cost.
- Services: smelting, crafting, tool upgrades, armor, healing via magical immersion, spawning golems, fast travel, core leveling.
- Protect the core with fences/palisades, totems, golems, traps. AI competitors raid or occupy her; capture never permanently deletes or fully softlocks the game.
- Other rare biome Temptresses can be won over, maintained, and connected for travel and regional resource collection. A multi-core network amplifies obligations rather than erasing them.

## Phase 1 — W1: the first playable loop

One rich woodland diorama and *one* incredible Temptress; one identifiable scavenger; 10–15 believable trees/ore rocks; a few clearly identifiable hares; walking and automatic resource interaction; minimal inventory; giving raw meat; Satisfaction depletion; tactile feedback and a compact UI. Not a massive world yet.

At minute 0: opening shot shows shrine and character in a hand-crafted clearing. Visible bark, votive objects, soft shadows and the central breathing motion establish the atmosphere without narration.

At minute 1–2: player clicks pine; walks around boulders, chops wood with visible swing. Hunts a hare, receives raw meat + hide and a popup, sack fills. Moves back to the shrine; tosses one chunk of meat into central fissure; shrine inhales/squeezes briefly; Satisfaction rises. No dialogue is needed.

At minute 4: Satisfaction has declined noticeably but not catastrophically. Tooltip explains the asymmetry: it takes many meat trips to afford a miracle. No hardlock if Satisfaction hits zero; feeding always works.

Visual quality of this **single scene** is more important than implementing W2 in same agent window. The initial loop must be worth watching even before there is a crafting menu.

## Controls

| Action | Input |
| --- | --- |
| Walk / interact / approach+attack | left mouse click on world / object |
| Open creature menu | left mouse click shrine (approach first) |
| Cancel path/target | right-click or Escape |
| Backpack | I or B |
| Camera zoom | mouse wheel within safe bounds |
| Pause | Escape when nothing to cancel |
| Attack modifier (later) | optional Shift-click |
| Building menu (later) | B (if I is inventory) / toolbar |

Primary use is mouse only; keyboard are accessibility shortcuts. UI should not let clicks propagate to world.

## The three-meter dilemma

**Satisfaction**: how pleased the Temptress is. Starts ~65/100. Passive hungry drain; feed meat to restore +4 raw / +7 cooked. Services are MUCH more expensive than an ordinary offering. Zero satisfaction = Dormant services, never removes food option.

**Expedition Bond**: separate magic leash anchored in nearest owned core. Refills near a fed core, bleeds when beyond its aura, drains faster at distance/bad weather. At zero, forced rescue/recall with a clearly signaled inventory penalty, not permadeath. Upgrading core raises Bond cap/range, letting the player explore farther.

**HP**: player survival versus animals/rivals/weather, healed through a Satisfaction-costly shrine ritual. For W1 the HP bar can exist even if damage comes in W3.

Why separate Satisfaction and Bond: Satisfaction drives the economy, Bond limits how long you can roam. If only one stat did both, players would encounter confusing feedback, repeated softlocks and difficulty tuning.

## Gathering, progression and economy

Resources:
- Raw meat: hare 1, boar 3, deer 2. Primary Satisfaction source.
- Hide: hare 1, boar 2, deer 2; backpack/armor.
- Wood: trees 2–4; fences, tools, totems.
- Stone: rocks 2–3; starter tools, walls, golems.
- Ore: nodes 2–3; must be given to the core for smelting.
- Ingot: refined at shrine from 2 ore and Satisfaction; advanced tools/armor/golems.
- Region-only later: resin/herbs (swamp), copper (desert), dense pelts/iron (snow), obsidian/crystal (volcanic).

Inventory: 12 slots / 30 weight initially. Resource stack caps; visible load feedback; backpack upgrade to +10 weight/+4 slots (repeatable only when defined by tier). Prevent pickup beyond capacity. Dropped excess remains in world where possible. Returning physically with food is a design pillar; do not auto-transfer to shrine.

Candidate recipes / Satisfaction costs:

| Service | Inputs | Sat cost | Output |
| --- | --- | ---: | --- |
| Feed raw meat | 1 raw meat | +4 | +4 Sat |
| Feed cooked meat | 1 cooked meat | +7 | +7 Sat |
| Refine | 2 ore | 10 | 1 ingot |
| Repair / healing | Player below max HP | 10 | +25 HP |
| Primitive axe | 3 wood, 2 stone | 12 | better harvesting |
| Spear | 2 wood, 1 ingot | 12 | better hunting/defense |
| Larger sack | 6 hide, 4 wood | 18 | +10 carrying weight, +4 slots |
| Golem | 8 stone, 2 ingot | 16 | 1 defendable golem |
| Teleport | 2 owned cores | source 20 + destination 10 | transfer hero and bag |

These are *provisional* tuning values. Interactions must be transactional with validation before deduction. Low-Sat UI communicates exact shortages. Core progression tiers 1–5 raise max Satisfaction (100,130,160,200,250), raise max Bond and unlock services, while **appetite and rival interest also increase**.

## Defense and enemies

Rival scavengers and hostile factions compete for control of the shrines. From W3 onward:
1. Visible scouting enemy with a readable warning cue.
2. Telegraph a raid and spawn outside cleared area, no invisible instant damage.
3. Raider pursues shrine using obstacles and attackable gates/walls. He can distract golems or break palisade.
4. If undefended, channels a 10s control theft ritual at the shrine. Interruptible by damage. Ownership changes temporarily; shrine cannot be destroyed.
5. On capture, player receives reconquest quest and temporary fallback feed loop: game always remains playable.

Defense tools: wood palisade, thorn fence, stone golem, repaired barriers, radiating ward totems. Golems cost both resources and Sat. Totems slowly earn Sat in shrine radius but have diminishing returns, cap, occasional maintenance and potential danger attraction. Prevent infinite free overnight farming.

## World, rare cores and biomes

W1: one carefully curated/semi-seeded starter forest clearing, guaranteed tree/prey/ore and walkable routes. World is not 'infinite' until later milestone.

W4: deterministic chunks (recommend logical 32x32 cell units, e.g. 2 world units/cell), low-overhead terrain generation from seed and climate/moisture noise. Background biome transitions are coherent broad regions. Save only persistent differences and dynamically occupied world objects rather than entire chunks.

| Biome | Architecture & palette | Biome shrine | Challenge / special |
| --- | --- | --- | --- |
| Forest | wet spruce, black loam, bronze votives | Widow of Roots | starter, effective healing |
| Desert | bleached limestone, ochre sand, jade scarabs | Saffron Oracle | copper ore, cheap metal smelting |
| Snow | blue slate, hoarfrost, cracked ivory | Frost Matron | longer bond range, pelt hunting |
| Swamp | black teal ponds, moths, spore lanterns | Mire Empress | totem efficiency, herbs/resin |
| Volcanic | ash, black glass, embers, oxidized iron | Ember Sovereign | crystals, high-tier forging |

Temptresses are **rare biome landmarks**, not random spawns beside each other. One guaranteed near player spawn, then a rare opportunity after significant travel. Rival factions control some. Different color/materials/crowns/appetites, but same unmistakable shrine anatomy and layered fold silhouette. Far-away shrine capture earns a new base hub, fast-travel node and extra demand clock.

## Exploration/remote reach

While outside an allied core's aura, Bond drains and increases with distance from nearest allied core. Progression in Satisfaction capacity increases Bond max. When Bond collapses, show a 10s final warning and initiate emergency recall: player returns to nearest allied core, losing 20% *unbanked* carried resources, with low HP. Never lose starter core to recall, never trap them away from food. Fast travel between owned, charged shrines costs Sat at BOTH ends; unavailable if either core dormant.

Later consider jealousy: feeding a remote shrine more than the home shrine leads to changed feeding needs, service costs and visible agitation — tune so it's a meaningful decision, not a grind trap.

## Tone and environmental storytelling

Follow [WRITING_STYLE.md](WRITING_STYLE.md) in every milestone. TEMPTERS is a dark fantasy survival game with an inherently absurd premise. Humor emerges from the interaction of creature needs, limited resources, player decisions and unexpected consequences. Let these situations speak for themselves. Express creature personality through behavior and animation. Keep UI, objectives and warnings concise and functional; do not add recurring commentary or routine reaction dialogue.

## Good balance / anti-softlock guarantees

- Starter area always has reachable prey and trees; creatures respawn on timer when necessary, never leaving the player unable to feed after depletion.
- Sat==0 blocks luxuries but feeding always works. Recovery actions from defeated states are free or extremely cheap.
- Fair raid grace (first raid no sooner than 6 gameplay minutes, preferably after a warning objective), player never loses everything permanently.
- Unlimited world size is not permission for unlimited game-scene cost: deterministic chunks and sparse delta persistence.
- Never punish saving/reloading with duplicate rewards, missed satiation costs, or double spawns.

## Win and endgame

First achievement: deliver first meat and perform first miracle. Midgame: survive raid, build golem/totem setup, upgrade bag and satisfy jealous demands. Long term: claim three regional Temptresses, establish a delivery-and-teleport network, survive the final siege. Endless sandbox after objective.

## Non-goals for early windows

Multiplayer networking; internet services; real-money economy; procedural every biome in W1; complex skinned characters; AAA hyperrealism; explicit sex content; hundreds of empty craft recipes; unnecessarily heavy architecture.

## W2 implementation notes

W2 is implemented and verified; STATUS.md records the checks. Shrine recipes listed in progression.w2_recipes remain available. The subsequent W3 construction checkpoint exposes the palisade and totem recipes through the building menu. Golems, cooking and travel remain inactive.

Shrine levels 2/3/4/5 require respectively: 4 wood + 3 stone + 2 hide / 2 ingots + 4 stone + 3 hide / 4 ingots + 6 wood + 4 hide / 6 ingots + 6 stone + 6 hide, plus 20/25/30/40 Satisfaction. Caps are 100/130/160/200/250; appetite multipliers are 1/1.15/1.3/1.5/1.75. Level two unlocks spear and hide armor, three iron pickaxe, four iron axe, five reinforced armor. Costs and effects are authoritative in ECONOMY_BALANCE.json.

Equipment occupies dedicated equipped slots rather than resource stacks. Stone/iron axes reduce chopping time to 0.55/0.35 seconds, pickaxe reduces mineral work to 0.5, spear reduces hunting to 0.45 and adds 0.65 reach. Backpack grants +10 carrying weight and +4 stacks. Armor stages each grant +20 maximum Health without restoring current Health. New characters begin at 75/100 Health so the healing service has an immediate use before W3 damage exists. Healing costs 10 Satisfaction for up to 25 Health and plays a brief magical disappearance/reappearance. World geometry and creature design are preserved.

Saves restore renewable-node timers without offline advancement. A failed validation changes no live state. W3 has now been requested and is in progress; its construction checkpoint adds schema-v2 structure persistence while migrating W2 saves.

## W3 construction checkpoint — incomplete milestone

Palisades and ward totems can be placed with a ground-snapped preview within 9m of the shrine and 5m of the player. Placement protects the creature's root mound, main approach, renewable resource areas and path access. Building charges the existing recipes only on valid placement. Structures have durability and can be reinforced at shrine level 2, repaired, or dismantled without refunds. Combat damage is testable through the structure API but has no hostile source until the remaining W3 combat work.

Totems run for 300 active seconds per maintenance payment of 1 wood and 1 hide. Their base production is 0.015 Satisfaction/s, with 60% geometric diminishing returns (strongest first), at most five active totems and a combined 0.045/s cap. Beyond 6m from the shrine each totem produces 60% of its inner-ring rate. Reinforcement grants +50% maximum durability and totem output without healing durability. Expired totems stop producing; pause and closed-game time do not consume maintenance or generate Satisfaction. This finite upkeep prevents unattended unlimited income.

Golems, player/enemy combat, faction scouts, escalating raids, ownership capture and free recovery remain unfinished. Keep the planned six-minute raid grace, ten-second interruptible capture and anti-softlock guarantees when implementing them. Do not advance to W4 yet.
