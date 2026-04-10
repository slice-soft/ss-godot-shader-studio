# Compiler Pipeline

## Overview

The compiler transforms a `ShaderGraphDocument` into valid `.gdshader` source code through a series of passes. Each pass is independent and testable.

```
ShaderGraphDocument  (source)
        │
        ▼
┌───────────────────────────┐
│  Pass 1: Structural       │  ids valid, ports exist, required outputs connected
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│  Pass 2: Typing           │  type inference, coercion, incompatibilities
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│  Pass 3: Stage validation │  vertex-only / fragment-only, varyings
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│  Pass 4: Cycle detection  │  no feedback loops allowed
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│  IRBuilder                │  topological sort → IRGraph
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│  Pass 5: Optimization     │  dead node elimination, constant folding (future)
└───────────────────────────┘
        │
        ▼
┌───────────────────────────┐
│  EmitBackend              │  IRGraph → .gdshader text
└───────────────────────────┘
        │
        ▼
   CompileResult
   (success, shader_code, issues[])
```

## Pass 1 — Structural validation

Checks document integrity without any type knowledge:

- All `edge.from_node_id` / `to_node_id` reference existing nodes
- All `edge.from_port_id` / `to_port_id` reference existing ports on their definitions
- Required output ports (e.g. `SpatialOutput.albedo`) are connected or have defaults
- No duplicate node IDs, no duplicate edge IDs
- `definition_id` of each node exists in the registry

**Failure:** emits `ERROR` issues, compilation stops.

## Pass 2 — Typing

Resolves port types and validates connections:

- For each edge, checks `TypeSystem::are_compatible(from_type, to_type)`
- Applies implicit casts where allowed (e.g. `float → vec3` splat)
- Marks edges with their `CastType` for IR use
- Reports `ERROR` for incompatible connections
- Reports `WARNING` for lossy casts (e.g. `vec4 → vec3` truncation)

## Pass 3 — Stage validation

Validates stage scoping rules:

- A `vertex`-only node cannot receive connections from `fragment`-only nodes
- Connections crossing stage boundaries require a `varying` — detected and recorded
- Output node (`SpatialOutput`) checks that vertex-stage inputs come from vertex stage

## Pass 4 — Cycle detection

Performs a DFS on the graph. Any back edge indicates a cycle, which is an error.
Shaders are acyclic by definition (no feedback loops).

## IRBuilder

After all validation passes succeed:

1. **Topological sort** — produces a linear order of nodes where all inputs come before outputs
2. **Variable assignment** — assigns a unique GLSL variable name to each output port (`_t0`, `_t1`, ...)
3. **Uniform collection** — collects all `Parameter` nodes → `uniform` declarations
4. **Varying collection** — collects all stage-crossing edges → `varying` declarations
5. **Stage split** — separates nodes into `vertex_nodes[]` and `fragment_nodes[]`

## Pass 5 — Optimization

Applied to the `IRGraph`:

- **Dead node elimination** — removes nodes whose outputs are not reachable from any Output node
- **Constant folding** *(future)* — evaluates constant expressions at compile time
- **Common subexpression reuse** *(future)* — shares computed values used in multiple places
- **Cast simplification** — removes redundant casts (e.g. `float → float`)

## EmitBackend

Backends are swappable per `shader_domain`. Each backend knows:
- Which `shader_type` declaration to emit
- Which built-in variables are available in each stage
- How to emit the stage function signatures
- How to bind the Output node's inputs to the correct built-in outputs

### EmitBackend (spatial)

```glsl
// header
shader_type spatial;
render_mode unshaded;   // if configured

// uniforms
uniform vec4 AlbedoColor : source_color = vec4(1.0);
uniform sampler2D AlbedoTexture : source_color;

// varyings
varying vec3 world_pos_vary;

void vertex() {
    // vertex-stage nodes in topological order
    world_pos_vary = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
    // fragment-stage nodes in topological order
    vec3 _t0 = texture(AlbedoTexture, UV).rgb;
    vec4 _t1 = AlbedoColor;
    ALBEDO = _t0 * _t1.rgb;
    ROUGHNESS = 0.5;
    METALLIC = 0.0;
}
```

### Node template system

Each `ShaderNodeDefinition` has a `compiler_template` string with placeholders:

```
// Example: Add node
// inputs:  {a}, {b}
// outputs: {result}
float {result} = {a} + {b};
```

The emitter substitutes `{a}`, `{b}`, `{result}` with the assigned variable names.

## CompileResult

`ShaderGraphCompiler.compile_gd(doc)` returns a Dictionary:

```gdscript
{
    "success":     bool,    # false if any ERROR-level issue
    "shader_code": String,  # empty if success == false
    "issues":      Array,   # [{severity, node_id, port_id, message, code}]
}
```

Consumers should always check `success` before using `shader_code`.
`issues` may contain warnings even when `success == true`.

## Determinism guarantee

Given the same `ShaderGraphDocument` and the same `NodeRegistry`, the compiler always produces byte-identical output. This is enforced by:

- Topological sort is deterministic (tie-breaking by node ID, lexicographic)
- Variable names are assigned by topological order index
- Uniform/varying declarations are sorted alphabetically
- No timestamps or random values in emitted code
