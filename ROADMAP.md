# Roadmap — Godot Shader Studio

## Versioning rules

| Range | Meaning |
|-------|---------|
| `0.x` | Architecture and format unstable — breaking changes expected |
| `1.0.0` | First complete, publishable release — stable format, stable API |
| `1.x` | Expansion without breaking main compatibility |
| `2.0.0` | Only if public format or architecture changes incompatibly |

**1.0.0 is NOT a milestone rename for a demo.** It means the product already works end-to-end for real projects.

---

## Phase A — Foundation

> Goal: C++ core compiling, graph model defined, type system, registry, minimal compiler, serializer.
> No editor UI yet.

- [ ] Repository structure and CMake setup
- [ ] GDExtension entry point compiling
- [ ] `godot-cpp` submodule configured
- [ ] `ShaderGraphDocument` — graph root resource
- [ ] `ShaderGraphNodeInstance` — node in a document
- [ ] `ShaderGraphEdge` — connection between ports
- [ ] `ShaderDomain` enum (spatial, canvas_item, particles, sky, fog, fullscreen)
- [ ] `TypeSystem` — type enum + compatibility/cast rules
- [ ] `PortDefinition` — typed port descriptor
- [ ] `ShaderNodeDefinition` — reusable node type definition
- [ ] `NodeRegistry` — singleton catalog of all node definitions
- [ ] `ValidationEngine` — structural + typing + stage + cycle passes
- [ ] `IRBuilder` — graph → topologically ordered IR
- [ ] `ShaderGraphCompiler` — IR → `.gdshader` (spatial backend first)
- [ ] `GraphSerializer` — save/load `.gshadergraph` as JSON
- [ ] Stdlib: 20–30 base nodes registered

**Milestone:** hardcoded graph (Add + Multiply + SpatialOutput) → valid `.gdshader`

---

## Phase B — First usable vertical slice

> Goal: working editor, connect nodes, save, see compiled shader in preview. Spatial only.

- [ ] Godot addon `plugin.cfg` and `plugin.gd`
- [ ] Main editor dock registered in Godot editor
- [ ] `GraphCanvasController` — creates visual nodes, handles connections
- [ ] `NodeSearchController` — popup to search and add nodes
- [ ] `NodeInspectorController` — properties panel for selected node
- [ ] `ToolbarController` — compile, save, open commands
- [ ] `GraphFileManager` — save/load `.gshadergraph` + generate `.generated.gdshader`
- [ ] `CompilerOutputPanel` — display errors and warnings
- [ ] Preview viewport — shader applied to sphere/cube/plane
- [ ] `EditorImportPlugin` for `.gshadergraph` files
- [ ] Undo/redo for graph operations

**Milestone:** open a `.gshadergraph`, connect nodes, compile, see result in preview

---

## Phase C — Serious product core

> Goal: from demo to real tool.

- [ ] Visual validation overlay — red borders on nodes with errors, port type tooltips
- [ ] Parameters panel — expose uniforms, manage shader properties
- [ ] Subgraph system — `.gssubgraph` format, inline expansion in compiler
- [ ] Subgraph browser — list and preview available subgraphs
- [ ] Custom Function Node — inline GLSL or `.gdshaderinc` reference
- [ ] Per-node preview thumbnails
- [ ] Shader regenerated on save
- [ ] Deterministic compiler output
- [ ] Comments / frame nodes in canvas
- [ ] Reroute nodes
- [ ] Multi-select, copy/paste, duplicate

---

## Phase D — Domain expansion

> Goal: platform, not just a spatial shader tool.

- [ ] `canvas_item` backend + domain-specific nodes
- [ ] `particles` backend + domain-specific nodes
- [ ] `sky` backend + domain-specific nodes
- [ ] `fog` backend + domain-specific nodes
- [ ] `fullscreen / postprocess` backend + domain-specific nodes
- [ ] Advanced stdlib nodes: Triplanar, Fresnel, Noise, Dither, Dissolve, Toon Ramp, Normal Blend
- [ ] Screen texture access, depth access nodes
- [ ] Vertex offset nodes
- [ ] 2D preview panel (UV, channels, alpha visualization)

---

## Phase E — 1.0.0 Hardening

> Goal: mature public release.

- [ ] Unit tests for core, type system, compiler
- [ ] Golden tests — `.gshadergraph` fixtures → expected `.gdshader` output
- [ ] CI/CD — build binaries on Linux/Windows/macOS + run tests
- [ ] Release pipeline — package addon as installable zip
- [ ] Complete documentation (user guide, compiler spec, node authoring, API)
- [ ] Subgraph examples library
- [ ] UX refinement pass
- [ ] Release notes and changelog
- [ ] Published on Godot Asset Library

**Milestone: 1.0.0 — first complete, production-usable release**
