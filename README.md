# Payload Protocol

A puzzle game about cargo in a spaceship hold. Pack the freight, warp, and watch it slide, hit, break, and explode. Made with Godot 4.7 and GDScript.

- Game design: [docs/spec.md](docs/spec.md)
- Architecture and code rules: [CLAUDE.md](CLAUDE.md)

## Requirements

- [devbox](https://www.jetify.com/devbox). It installs Task, uv, and Node.js at fixed versions.
- Godot 4.7 as `godot` on your `PATH`. To use a different binary, set `GODOT=/path/to/godot`.

## Setup

```sh
devbox shell
task import
task run
```

To open the project in the Godot Project Manager, import `project/project.godot`. The repository root is not a Godot project.

## Tasks

| Command | Action |
| --- | --- |
| `task import` | Import the project. Run after a clone. |
| `task run` | Run the game |
| `task editor` | Open the Godot editor |
| `task test` | Run the rule tests |
| `task play -- help` | The text player |
| `task smoke` | Run the game headless for 5 frames |
| `task shots` | Take screenshots of each screen into `shots/` |
| `task export:web` | Export the web build to `build/web` |
| `task serve:web` | Serve `build/web` at http://localhost:8060 |
| `task fx` | Make the effect sheets with pixelfx |
| `task fmt` | Format the GDScript code |
| `task lint` | Lint the GDScript code, and check the format |
| `task check` | Run lint, the tests, and smoke |

Run `task check` before each commit.
