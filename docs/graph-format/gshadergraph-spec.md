# .gshadergraph Format Specification

Version: 1 (format_version field)

## Overview

A `.gshadergraph` file is a UTF-8 JSON document that fully describes a visual shader graph. It is the source file the developer authors and commits. The compiled `.generated.gdshader` is derived from it.

## Top-level structure

```json
{
  "format_version": 1,
  "uuid": "550e8400-e29b-41d4-a716-446655440000",
  "name": "MyShader",
  "created_at": "2026-01-01T00:00:00Z",
  "modified_at": "2026-01-01T00:00:00Z",
  "compiler_version": "0.1.0",
  "shader_domain": "spatial",
  "stage_config": {
    "has_vertex": true,
    "has_fragment": true,
    "has_light": false
  },
  "nodes": [ ... ],
  "edges": [ ... ],
  "parameters": [ ... ],
  "subgraph_refs": [ ... ],
  "editor_state": { ... }
}
```

## Fields

### `format_version` (int, required)
Current version: `1`. Used for migration when loading older files.

### `uuid` (string, required)
Stable identifier for this graph. Generated once at creation, never changes.

### `shader_domain` (string, required)
One of: `spatial`, `canvas_item`, `particles`, `sky`, `fog`, `fullscreen`.

### `nodes` (array)

Each entry is a node instance:

```json
{
  "id": "node_abc123",
  "definition_id": "math/add",
  "title": "Add",
  "position": { "x": 200.0, "y": 150.0 },
  "properties": {
    "clamp_result": false
  },
  "stage_scope": "fragment",
  "preview_enabled": false
}
```

- `id`: stable per-document identifier, never reused within the same document
- `definition_id`: references a `ShaderNodeDefinition` in the registry
- `properties`: node-specific values (not port connections)
- `stage_scope`: `"vertex"`, `"fragment"`, `"light"`, or `"any"`

### `edges` (array)

Each entry is a connection between two ports:

```json
{
  "id": "edge_xyz789",
  "from_node_id": "node_abc123",
  "from_port_id": "result",
  "to_node_id": "node_def456",
  "to_port_id": "a"
}
```

### `parameters` (array)

Exposed uniforms editable from the Godot Material inspector:

```json
{
  "id": "param_001",
  "name": "AlbedoColor",
  "type": "color",
  "default_value": { "r": 1.0, "g": 1.0, "b": 1.0, "a": 1.0 },
  "hint": "color_no_alpha",
  "node_id": "node_param_abc"
}
```

### `subgraph_refs` (array)

References to `.gssubgraph` files used in this document:

```json
{
  "ref_id": "subgraph_ref_001",
  "path": "res://shaders/subgraphs/fresnel_basic.gssubgraph",
  "format_version": 1
}
```

### `editor_state` (object)

UI-only data, not used by the compiler. Safe to strip for headless compilation.

```json
{
  "zoom": 1.0,
  "scroll_offset": { "x": 0.0, "y": 0.0 },
  "selected_nodes": [],
  "minimap_enabled": true
}
```

## Migration

When loading a file with `format_version < current`, the serializer runs upgrade functions in sequence. Each upgrade function is deterministic and does not require user interaction.

| From | To | Change |
|------|----|--------|
| (future) | | |

## Stability guarantees

- Node IDs within a document are stable across saves.
- Parameter IDs are stable across saves.
- Adding new optional fields does not break older readers.
- Removing fields requires a format_version bump and a migration function.

## Generated shader header

Every `.generated.gdshader` produced by the compiler starts with:

```glsl
// ============================================================
// GENERATED FILE — DO NOT EDIT MANUALLY
// Source: res://shaders/my_shader.gshadergraph
// Compiled by: Godot Shader Studio 0.1.0
// ============================================================
shader_type spatial;
```
