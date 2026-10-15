# TEMPTERS — Permanent writing rules

This is the authoritative writing policy for all existing and future milestones, prompts, UI, dialogue, objectives, tooltips, notifications, world labels, configuration and generated content. Read it before adding or editing text. Preserve the approved 2.5D art direction, environment and central creature.

1. TEMPTERS is a dark fantasy survival game with absurd and provocative themes. It is not a comedy dialogue simulator.
2. Humor must emerge naturally from gameplay, visual storytelling, animation, creature behavior, player decisions and unexpected consequences.
3. Do not use forced jokes, generic quirky narration, corporate satire, bureaucratic titles, fake departments or artificial humor.
4. Do not constantly comment on the player's actions.
5. Do not introduce funny-sounding names just to make the game seem humorous. Use descriptive names or established setting names with a clear purpose.
6. UI text must be clear, concise, readable and immersive. Prefer short, natural wording and consistent mechanic names.
7. Avoid unnecessary narration, text popups and excessive dialogue. Show information where it helps the player act; do not repeat it across multiple surfaces.
8. Absurd situations should speak for themselves. Do not explain the joke to the player.
9. Characters and creatures may have personalities, expressed primarily through behavior and animation rather than jokes.
10. Remove dialogue unless it is genuinely useful, meaningful or exceptionally well-written. Silence is the default; do not fill an empty text slot merely because it exists.
11. Every future milestone must follow these rules without exception. Prompt templates and generated text pools must enforce the same policy.

## Terminology and feedback

- Use **Health**, **Satisfaction**, **Expedition Bond**, **Inventory**, **Weight**, resource names and direct action labels such as **Hunt**, **Chop**, **Mine**, **Feed** and **Close**.
- Satisfaction is the existing meter that falls over time and rises when feeding. Do not rename it Hunger or imply a second implemented meter.
- Preserve exact costs, gains, shortages, objectives, warnings and progression information. Read quantities from balance data where applicable.
- Keep brief resource/gain feedback, such as `+1 raw meat` or `+4 Satisfaction`, when it confirms a transaction. Do not attach dialogue to it.
- Warnings state the condition and useful action: `Inventory full. Press I to discard items.` or `Dormant. Feed raw meat to restore Satisfaction.`
- Do not add random reaction pools, recurring commentary or dialogue-count requirements. Any future text pool must contain only necessary, reviewed content.

## Required review for every milestone

Audit all changed user-facing strings and generated text at their call sites, plus relevant docs, prompts, configuration and data. Remove instructions that encourage the rejected style rather than keeping them as alternative guidance. Search is a supplement to reading: synonyms and new jokes must also be rejected. Inspect text in the running UI for clarity and truncation. Record the audit and validation in STATUS.md. Writing-only changes must preserve gameplay and approved visuals.
