# Original asset sources

All game meshes and surface grain in this checkpoint are authored in the three GDScript files under `geometry/`. No downloaded or ripped art, model, texture, font, or audio is used. UI typography uses Godot's bundled default font.

`sculpt.gd` provides lofts, material grain, accessory geometry and one-time mesh consolidation. `creatures.gd` authors the living shrine, Wretch and hares. `woodland.gd` authors irregular conifer boughs, rocks, terrain, moss, debris and instanced grass. The source builders are the reproducible committed-format assets; runtime construction happens once at scene startup, not every frame.

No external authoring application or online asset service is required.
