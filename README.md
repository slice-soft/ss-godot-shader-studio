# Godot Shader Studio

Professional visual shader editor for Godot 4, built as a GDExtension native plugin.

> **Status:** Phase A — Foundation (in development)

## Overview

Godot Shader Studio is a standalone visual shader authoring platform for Godot 4.4+. It is not a wrapper around Godot's built-in VisualShader — it is an independent system with its own graph model, type system, compiler, and editor UI.

## Architecture

| Layer | Technology | Responsibility |
|-------|-----------|----------------|
| Native core | C++ 17 + GDExtension | Graph model, type system, compiler, serializer, registry |
| Editor plugin | GDScript + Godot Controls | UI, docks, canvas, inspector, asset integration |

## Shader domains supported (planned)

- `spatial` ✓ (Phase B)
- `canvas_item` (Phase D)
- `particles` (Phase D)
- `sky` (Phase D)
- `fog` (Phase D)
- `postprocess / fullscreen` (Phase D)

## File formats

| Extension | Description |
|-----------|-------------|
| `.gshadergraph` | Visual shader source — the file you author |
| `.gssubgraph` | Reusable subgraph component |
| `.generated.gdshader` | Compiled output — do not edit manually |

## Repository structure

```
ss-godot-shader-studio/
├── addons/ss_godot_shader_studio/   ← Godot addon (install this in your project)
│   ├── plugin.cfg
│   ├── plugin.gd
│   ├── scripts/                     ← GDScript editor logic
│   ├── scenes/                      ← Editor UI scenes (created in Godot editor)
│   ├── icons/
│   └── gdextension/                 ← Native binaries + .gdextension descriptor
├── native/                          ← C++ GDExtension source
│   ├── CMakeLists.txt
│   ├── thirdparty/godot-cpp/
│   └── src/
│       ├── core/                    ← Entry point, class registration
│       ├── graph/                   ← Document, node instance, edge
│       ├── types/                   ← Type system, port definitions
│       ├── registry/                ← Node definitions, stdlib
│       ├── validation/              ← Validation engine and results
│       ├── ir/                      ← Intermediate representation
│       ├── compiler/                ← Graph → IR → .gdshader
│       └── serializer/              ← Save/load .gshadergraph
├── examples/
│   ├── sandbox-3d/
│   └── sample-graphs/
├── docs/
│   ├── architecture/
│   ├── compiler/
│   ├── graph-format/
│   └── node-authoring/
└── tools/
```

## Building

```bash
# Clone with submodules
git clone --recurse-submodules https://github.com/slice-soft/ss-godot-shader-studio

# Build native extension
cd native
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build

# Copy binary to addon
cp build/libss_godot_shader_studio.* addons/ss_godot_shader_studio/gdextension/bin/
```

## Requirements

- Godot 4.4+
- CMake 3.22+
- C++17 compatible compiler

## License

MIT — see [LICENSE](LICENSE)

---

*Part of the [SliceSoft](https://slicesoft.dev) / Gameforge ecosystem.*
