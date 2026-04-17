# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.9.0-rc](https://github.com/slice-soft/ss-godot-shader-studio/compare/ss_godot_shader_studio-v0.8.0...ss_godot_shader_studio-v0.9.0-rc) (2026-04-17)


### Features

* add controls to preview ([#13](https://github.com/slice-soft/ss-godot-shader-studio/issues/13)) ([98144dc](https://github.com/slice-soft/ss-godot-shader-studio/commit/98144dc86c04b6d67663b35908bace629c69c3a0))

## [0.9.0](https://github.com/slice-soft/ss-godot-shader-studio/compare/ss_godot_shader_studio-v0.8.0...ss_godot_shader_studio-v0.9.0) (2026-04-15)


### Features

* add controls to preview ([#13](https://github.com/slice-soft/ss-godot-shader-studio/issues/13)) ([98144dc](https://github.com/slice-soft/ss-godot-shader-studio/commit/98144dc86c04b6d67663b35908bace629c69c3a0))

## [0.8.0](https://github.com/slice-soft/ss-godot-shader-studio/compare/ss_godot_shader_studio-v0.7.0...ss_godot_shader_studio-v0.8.0) (2026-04-13)


### Features

* core stage varyings and domain validation ([#8](https://github.com/slice-soft/ss-godot-shader-studio/issues/8)) ([d7fbe9b](https://github.com/slice-soft/ss-godot-shader-studio/commit/d7fbe9b8b0f8726fe5a06b4271ded2214b307dee))
* editor inline parameters and search ([#9](https://github.com/slice-soft/ss-godot-shader-studio/issues/9)) ([495cac9](https://github.com/slice-soft/ss-godot-shader-studio/commit/495cac96a0a10bcaac8ff3720dd79efde9d1e399))
* examples extreme validation assets ([#10](https://github.com/slice-soft/ss-godot-shader-studio/issues/10)) ([e93f8df](https://github.com/slice-soft/ss-godot-shader-studio/commit/e93f8df9086f61d5a774d7468319c7572424c285))
* **registry:** split stdlib into modular node catalogs ([#6](https://github.com/slice-soft/ss-godot-shader-studio/issues/6)) ([cd0de95](https://github.com/slice-soft/ss-godot-shader-studio/commit/cd0de95a034c7079f5a64e51433cc9a3dcb51310))

## [0.7.0](https://github.com/slice-soft/ss-godot-shader-studio/compare/ss_godot_shader_studio-v0.6.0...ss_godot_shader_studio-v0.7.0) (2026-04-10)


### Features

* shader studio editor hardening ([#4](https://github.com/slice-soft/ss-godot-shader-studio/issues/4)) ([fcc51af](https://github.com/slice-soft/ss-godot-shader-studio/commit/fcc51af98109ada217486e6de1d4d5d6e9099980))

## [0.6.0](https://github.com/slice-soft/ss-godot-shader-studio/compare/ss_godot_shader_studio-v0.5.0...ss_godot_shader_studio-v0.6.0) (2026-04-10)


### Features

* pure gdscript migration ([#1](https://github.com/slice-soft/ss-godot-shader-studio/issues/1)) ([a835f1b](https://github.com/slice-soft/ss-godot-shader-studio/commit/a835f1b344c45c0c361ee5528f486d4eaf4cda7b))
* pure gdscript migration ([#2](https://github.com/slice-soft/ss-godot-shader-studio/issues/2)) ([b3d415b](https://github.com/slice-soft/ss-godot-shader-studio/commit/b3d415b77e18244ec4cd7e18a7cbde5afcbdbea1))

## [0.5.0] — 2026-04-10

### Added
- Unit test suite covering TypeSystem, ShaderGraphDocument, ValidationEngine, IRBuilder, and ShaderGraphCompiler (Phase E)
- Lightweight GDScript test framework (`test/framework/test_case.gd`)
- CI/CD via GitHub Actions: tests run on every push and pull request to `main`
- Release workflow: tag `v*.*.*` builds release zip and publishes to GitHub Releases
- Addon packaging script (`scripts/package_addon.sh`) — produces installable zip for Godot Asset Library

---

## [0.4.0] — 2026-04-10

### Added
- `canvas_item` shader backend + domain nodes: `output/canvas_item`, `input/canvas_texture`, `input/canvas_vertex`
- `particles` shader backend: `output/particles` → `start()` / `process()` functions; particle input nodes (velocity, color, index, lifetime, random)
- `sky` shader backend: `output/sky` → `sky()` function; eye direction, sun direction/color/energy, camera position inputs
- `fog` shader backend: `output/fog` → `fog()` function; world position, view direction, sky color inputs
- `fullscreen` / postprocess backend: `output/fullscreen` → compiles as `shader_type canvas_item`
- Advanced effect nodes: Triplanar, Fresnel, Value Noise, Dither, Dissolve, Toon Ramp, Normal Blend (`effects/*` category)
- Screen texture access: `input/screen_texture` with `hint_screen_texture` auto-uniform
- Depth texture access: `input/depth_texture` with `hint_depth_texture` auto-uniform
- Vertex offset node: `output/vertex_offset` — writes `VERTEX +=` in the vertex stage
- 2D preview panel — canvas_item / particles shaders route to a 2D SubViewport; 3D preview gains UV, R/G/B/Alpha channel visualization modes
- Helper function system: `ShaderNodeDefinition.helper_functions[]` deduped by IRBuilder, emitted before shader stages
- Auto-uniform system: `ShaderNodeDefinition.auto_uniform` for hint-annotated built-in samplers
- Extended domain support on existing input nodes: `input/uv`, `input/screen_uv`, `input/uv2`, `input/vertex_color`, `input/frag_coord`

---

## [0.3.0] — 2026-04-09

### Added
- Visual validation overlay: red / yellow title bars on nodes with errors or warnings
- Parameters panel: "Parameters" tab in the inspector; lists all `parameter/*` nodes and lets you rename them; uniforms emitted automatically on compile
- Subgraph system: `.gssubgraph` domain, `subgraph/input` + `subgraph/output` nodes, inline IR expansion in compiler; "New Subgraph" toolbar button; `.gssubgraph` import plugin
- Subgraph file picker: `subgraph_path` property → `…` button opens `EditorFileDialog` inside the node inspector
- Custom Function Node: `utility/custom_function` with inline GLSL body using `{a}` / `{b}` / `{c}` / `{d}` placeholders; `TextEdit` in inspector with syntax hint
- Deterministic compiler output: same graph always produces identical `.gdshader`
- Shader regenerated automatically on save
- Comment / frame nodes in canvas: Ctrl+G wraps selection in a `GraphFrame`
- Reroute nodes: `utility/reroute`, compact pass-through widget, transparent in IR
- Multi-select, copy/paste, duplicate: Ctrl+C / Ctrl+V / Ctrl+D

---

## [0.2.0] — 2026-04-09

### Added
- Godot addon `plugin.cfg` and `plugin.gd`
- Main editor dock registered in Godot editor
- `GraphCanvasController` — creates visual nodes, handles GraphEdit connections
- `NodeSearchController` — popup to search and add nodes by name or keyword
- `NodeInspectorController` — properties panel for the selected node
- `ToolbarController` — compile, save, open commands
- `GraphFileManager` — save / load `.gshadergraph`; generate `.generated.gdshader`
- `CompilerOutputPanel` — display compiler errors and warnings
- Preview viewport — shader applied to a sphere / cube / plane in a 3D SubViewport
- `EditorImportPlugin` for `.gshadergraph` files
- Undo / redo for all graph operations

---

## [0.1.0] — 2026-04-08

### Added
- Repository structure and addon skeleton
- `ShaderGraphDocument` — graph root resource
- `ShaderGraphNodeInstance` — node in a document
- `ShaderGraphEdge` — connection between ports
- `SGSTypes` — shader type enum, stage and domain bitfield constants, cast types
- `TypeSystem` — type ↔ GLSL string, component counts, compatibility and cast rules
- `ShaderNodeDefinition` — reusable node type definition (ports as `Array[Dictionary]`)
- `NodeRegistry` — Engine singleton catalog of all node definitions
- `ValidationEngine` — 5 passes: structural, typing, stage, cycle, output presence
- `IRBuilder` — graph → topologically ordered IR (Kahn's algorithm)
- `ShaderGraphCompiler` — IR → `.gdshader` (spatial backend)
- `GraphSerializer` — save / load `.gshadergraph` as JSON
- `StdlibRegistration` — 30+ base nodes registered at startup
- Architecture documentation, compiler pipeline spec, graph format spec, node authoring guide
