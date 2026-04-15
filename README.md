# Godot Shader Studio

Visual shader editor for Godot 4, built as a pure GDScript addon.

## Overview

Godot Shader Studio is a standalone visual shader authoring tool for Godot 4. It is not a wrapper around Godot's built-in VisualShader. The addon ships its own graph model, type system, compiler, serializer, and editor UI.

All core logic is written in GDScript. No C++, no GDExtension, and no native build step.

## Features

- Node-based shader authoring inside the Godot editor
- Pure GDScript compiler pipeline with deterministic output
- Saveable graph assets with reusable subgraphs
- Built-in validation, compiler diagnostics, and preview tooling
- Support for multiple Godot shader domains

## Supported shader domains

| Domain | Status |
|--------|--------|
| `spatial` | ✅ |
| `canvas_item` | ✅ |
| `particles` | ✅ |
| `sky` | ✅ |
| `fog` | ✅ |
| `fullscreen / postprocess` | ✅ |

## File formats

| Extension | Description |
|-----------|-------------|
| `.gshadergraph` | Visual shader source file |
| `.gssubgraph` | Reusable subgraph asset |
| `.generated.gdshader` | Generated shader output |

## Installation

1. Copy `addons/ss_godot_shader_studio/` into your project's `addons/` folder.
2. Open Godot and enable the plugin in **Project Settings -> Plugins**.
3. Use the **Shader Studio** editor tab to create and edit shader graphs.

## Requirements

- Godot 4.5+

## Documentation

- [Architecture overview](docs/architecture/overview.md)
- [Compiler pipeline](docs/compiler/pipeline.md)
- [Graph format specification](docs/graph-format/gshadergraph-spec.md)
- [Node definition specification](docs/node-authoring/node-definition-spec.md)
- [Extreme validation examples](docs/examples/extreme-validation.md)
- [Roadmap](ROADMAP.md)

## Development

Run the editor once to refresh the script class cache, then execute the test runner:

```bash
godot --headless --editor --path . --quit
godot --headless --path . --script test/runner.gd
```

> The first command regenerates `.godot/global_script_class_cache.cfg`. It is required after adding any new file that declares a `class_name`. Skip it and the runner will fail with `"Could not find type"` errors.

## Release Flow

- Feature work lands in `release` through squash merges.
- Pushes to `release` create prereleases such as `ss_godot_shader_studio-v0.9.0-rc.1`.
- After validation, run the `Promote Release` workflow to open the promotion PR from `release` to `main`.
- Stable releases and downstream docs or landing updates only happen after the promotion merge into `main`.

## License

MIT. See [LICENSE](LICENSE).

*Part of the [SliceSoft](https://slicesoft.dev) ecosystem.*
