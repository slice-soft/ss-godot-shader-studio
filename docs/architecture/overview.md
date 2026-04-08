# Architecture Overview

## System layers

```
┌─────────────────────────────────────────────┐
│              Godot Editor                   │
├─────────────────────────────────────────────┤
│ Addon / Editor Plugin Layer (GDScript)      │
│  - Docks and windows                        │
│  - Graph canvas UI (GraphEdit)              │
│  - Node inspector and properties            │
│  - Toolbar and commands                     │
│  - Asset integration (import plugin)        │
├─────────────────────────────────────────────┤
│ GDExtension Native Layer (C++)              │
│  - Graph core (document, node, edge)        │
│  - Type system                              │
│  - Node registry                            │
│  - Validation engine                        │
│  - IR builder                               │
│  - Compiler + emit backends                 │
│  - Serializer                               │
│  - Preview services                         │
├─────────────────────────────────────────────┤
│ Output artifacts                            │
│  - .gshadergraph  (source, version-control) │
│  - .gssubgraph    (reusable component)      │
│  - .generated.gdshader  (compiled output)  │
└─────────────────────────────────────────────┘
```

## Core principle

**All critical logic lives in C++ (native layer).**

The editor plugin only orchestrates user experience — it calls into the native layer for everything that matters: validation, compilation, serialization, type checking, registry queries.

This means:
- The compiler can run headless (CI, command-line tools)
- Unit tests do not require the Godot editor
- The native layer is stable and versioned independently
- The editor can be replaced or extended without touching core logic

## Module boundaries

### `shader_graph_core` (graph/)
Owns the document model: nodes, ports, edges, IDs. No compilation logic. No UI state.

### `shader_graph_types` (types/)
Owns the type enum and all compatibility/cast rules. No node-specific logic.

### `shader_graph_registry` (registry/)
Owns the catalog of node definitions. Does not know about document instances.

### `shader_graph_validation` (validation/)
Reads a document + registry, produces a list of issues. Does not modify the document.

### `shader_graph_ir` (ir/)
Transforms a validated document into an ordered, typed IR. No GLSL emission here.

### `shader_graph_compiler` (compiler/)
Drives the full pipeline: validation → IR → optimization passes → backend emit.

### `shader_graph_serializer` (serializer/)
Saves and loads `.gshadergraph` and `.gssubgraph`. Owns format versioning and migration.

### `shader_graph_preview` (preview/)
Compiles sub-shaders for per-node preview thumbnails and the full preview viewport.

### `shader_graph_stdlib` (registry/stdlib/)
Registers all built-in node definitions into the registry at startup.

## Compiler pipeline

```
ShaderGraphDocument
       ↓
  Pass 1: structural validation   (ids, ports, required outputs)
       ↓
  Pass 2: type inference + coercion
       ↓
  Pass 3: stage validation        (vertex-only, fragment-only, varyings)
       ↓
  Pass 4: cycle detection
       ↓
  IRBuilder: topological sort → IRGraph
       ↓
  Pass 5: dead node elimination
       ↓
  EmitBackend (spatial / canvas_item / particles / sky / fog / fullscreen)
       ↓
  .gdshader
```

## File format strategy

- `.gshadergraph` is the source of truth. Commit this file.
- `.generated.gdshader` is derived. It can be regenerated at any time.
- Both files should be committed so the shader works without running the tool.
- The compiler output is **deterministic**: same input always produces the same output.

## Division of responsibility: what Claude Code generates vs what is created in Godot editor

| Claude Code generates | Developer creates in Godot editor |
|----------------------|----------------------------------|
| All C++ source files | All `.tscn` scene files |
| All GDScript `.gd` files | Signal connections in the editor |
| CMakeLists.txt | Exported variable assignments in inspector |
| `.gdextension` descriptor | Godot project settings and input maps |
| `plugin.cfg` | |
| JSON/config files | |
| Documentation | |
