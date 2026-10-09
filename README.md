# The Purple Man — 3D Starter

A small Godot first-person playground built from editable primitive meshes. Explore a purple test room, jump onto blocks, and climb a ramp. No plugins, downloaded assets, or external services are needed.

## Play

Use **Godot 4.6.3 standard edition** with GDScript. Import `project.godot` in the Godot Project Manager, then press **F6** while viewing `scenes/test_room.tscn`, or **F5** to run the project.

| Control | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Mouse | Look |
| Shift | Sprint |
| Space | Jump |
| R | Return to the spawn point |
| Escape | Release the mouse and stop movement |
| Left click | Capture the mouse and resume |

The camera pitch is limited to prevent flipping. Falling below the room resets the player automatically. This is a movement prototype; enemies, objectives, and story are not implemented yet.

## Project layout

- `scenes/test_room.tscn`: lighting, floor, walls, ramp, and jump obstacles. Open it in Godot's 3D editor to rearrange the room.
- `scenes/player.tscn` and `scripts/player.gd`: reusable first-person controller. Movement speeds, acceleration, jump velocity, and mouse sensitivity can be adjusted in the Inspector.
- `scenes/hud.tscn` and `scripts/hud.gd`: crosshair, controls, and mouse capture prompt.
- `tests/run_tests.gd`: headless scene and controller integration checks.

## Cloud validation

From this repository run:

```bash
bash tests/run.sh
```

The runner uses writable Godot cache/settings directories outside the checkout, imports the project, and runs the integration suite. It fails on script/engine errors and requires an explicit test result. All 40 checks passed during creation, and the scene/HUD were also checked with software OpenGL rendering under a temporary virtual display. This cloud machine has no interactive desktop by default. Play locally to check mouse feel.

For a standalone import in this cloud environment:

```bash
export XDG_CACHE_HOME=/workspace/.cloud-environment/godot/cache
export XDG_DATA_HOME=/workspace/.cloud-environment/godot/data
export XDG_CONFIG_HOME=/workspace/.cloud-environment/godot/config
export XDG_RUNTIME_DIR=/workspace/.cloud-environment/godot/runtime
mkdir -p "$XDG_CACHE_HOME" "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
godot --headless --path . --editor --import
```

Godot's `.godot/` import cache is ignored. Keep the generated `.gd.uid` files with their scripts so resource identities remain stable. Export templates and release presets can be added when a target platform is chosen.
