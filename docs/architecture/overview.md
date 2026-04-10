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
│ Core Layer (GDScript)                       │
│  - Graph model (document, node, edge)       │
│  - Type system                              │
│  - Node registry (Engine singleton)         │
│  - Validation engine                        │
│  - IR builder                               │
│  - Compiler + emit backends                 │
│  - Serializer                               │
├─────────────────────────────────────────────┤
│ Output artifacts                            │
│  - .gshadergraph  (source, version-control) │
│  - .gssubgraph    (reusable component)      │
│  - .generated.gdshader  (compiled output)  │
└─────────────────────────────────────────────┘
```

## Core principle

**All critical logic lives in GDScript (`addons/ss_godot_shader_studio/core/`).**

The editor plugin only orchestrates user experience — it calls into the core layer for everything that matters: validation, compilation, serialization, type checking, registry queries.

Because this is an editor tool (not a runtime library), pure GDScript is the right choice:
- No compilation step — Godot loads `.gd` files directly
- Easy to contribute to — no toolchain to set up
- Fully extensible — third-party addons can register node definitions in GDScript
- Readable and maintainable for everyone familiar with Godot

## Module boundaries

### `core/graph/`
Owns the document model: nodes, ports, edges, IDs. No compilation logic. No UI state.
- `ShaderGraphDocument` — root resource
- `ShaderGraphNodeInstance` — node in a document
- `ShaderGraphEdge` — connection between ports

### `core/types/`
Owns the type enum and all compatibility/cast rules. No node-specific logic.
- `SGSTypes` — enum constants: ShaderType, CastType, stage/domain flags
- `TypeSystem` — static methods: `are_compatible()`, `get_cast_type()`, `type_to_glsl()`, etc.

### `core/registry/`
Owns the catalog of node definitions. Does not know about document instances.
- `ShaderNodeDefinition` — reusable node type (ports as `Array[Dictionary]`)
- `NodeRegistry` — registered as Engine singleton `"NodeRegistry"` at plugin load
- `StdlibRegistration` — registers all built-in nodes (30+) at startup

### `core/validation/`
Reads a document + registry, produces a list of issues. Does not modify the document.
- `ValidationEngine` — 5 passes: structural, typing, stage, cycle, outputs

### `core/ir/`
Transforms a validated document into an ordered, typed IR. No GLSL emission here.
- `IRBuilder` — static `build(doc, registry) -> Dictionary` (Kahn's topological sort)

### `core/compiler/`
Drives the full pipeline: validation → IR → backend emit.
- `ShaderGraphCompiler` — `compile_gd(doc) -> Dictionary`

### `core/serializer/`
Saves and loads `.gshadergraph`. Owns format versioning and migration.
- `GraphSerializer` — `save(doc, path)`, `load(path) -> ShaderGraphDocument`

### `core/registry/stdlib_registration.gd`
Registers all built-in node definitions into the registry at startup.

## Compiler pipeline

```
ShaderGraphDocument
       ↓
  Pass 1: structural validation   (ids, ports, required outputs)
       ↓
  Pass 2: type inference + coercion
       ↓
  Pass 3: stage validation        (vertex-only, fragment-only)
       ↓
  Pass 4: cycle detection
       ↓
  IRBuilder: topological sort → IRGraph (Dictionary)
       ↓
  EmitBackend (selected by shader domain)
       ↓
  .gdshader
```

## File format strategy

- `.gshadergraph` is the source of truth. Commit this file.
- `.generated.gdshader` is derived. It can be regenerated at any time.
- Both files should be committed so the shader works without running the tool.
- The compiler output is **deterministic**: same input always produces the same output.

## Editor and core responsibilities

- The editor layer owns interaction, layout, preview panels, and asset integration.
- The core layer owns graph validation, serialization, type checking, IR generation, and shader emission.
- This separation keeps the data model and compiler reusable outside the editor UI itself.
