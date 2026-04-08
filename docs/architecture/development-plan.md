# Development Plan

## Work division

| Claude Code generates | Developer creates in Godot editor |
|----------------------|----------------------------------|
| All C++ source (`.h`, `.cpp`) | All `.tscn` scene files |
| All GDScript (`.gd`) | Signal connections in the scene editor |
| `CMakeLists.txt` | Exported variable assignments in the inspector |
| `.gdextension` descriptor | `godot-cpp` submodule init + cmake build |
| `plugin.cfg` | Copying compiled binary to `bin/` |
| JSON / config files | Project settings in Godot |
| Documentation | |
| CI/CD workflows | |

---

## Phase A — Foundation

> No editor UI. Pure C++ work. Goal: compile a hardcoded graph to a valid `.gdshader`.

### A.1 — Repo structure and CMake

**Files I create:**
- `native/CMakeLists.txt` — CMake config, godot-cpp submodule, all src files
- `addons/ss_godot_shader_studio/plugin.cfg`
- `addons/ss_godot_shader_studio/gdextension/ss_godot_shader_studio.gdextension`
- `.gitignore`, `.gitmodules`
- `native/src/core/register_types.h`
- `native/src/core/register_types.cpp` — entry point, calls all registration functions

**You do (terminal):**
```bash
cd native
git submodule add https://github.com/godotengine/godot-cpp thirdparty/godot-cpp
cd thirdparty/godot-cpp && git checkout godot-4.4
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
# Copy binary:
cp build/bin/libss_godot_shader_studio.* ../addons/ss_godot_shader_studio/gdextension/bin/
```

---

### A.2 — Graph model (`native/src/graph/`)

**Files I create:**

`shader_domain.h` — enum: SPATIAL, CANVAS_ITEM, PARTICLES, SKY, FOG, FULLSCREEN

`shader_graph_document.h/.cpp` — `Resource` subclass:
```
fields:  uuid, name, format_version, shader_domain, stage_config
         nodes[], edges[], parameters[], subgraph_refs[], editor_state
methods: add_node(definition_id, position) → String
         remove_node(node_id)
         add_edge(from_node, from_port, to_node, to_port) → bool
         remove_edge(edge_id)
         get_node(node_id) → ShaderGraphNodeInstance
         get_edges_from(node_id) → Array
         get_edges_to(node_id) → Array
         get_all_nodes() → Array
         get_all_edges() → Array
```

`shader_graph_node_instance.h/.cpp` — `Resource` subclass:
```
fields:  id, definition_id, title, position (Vector2), properties (Dictionary)
         stage_scope, preview_enabled
```

`shader_graph_edge.h/.cpp` — `Resource` subclass:
```
fields:  id, from_node_id, from_port_id, to_node_id, to_port_id
```

---

### A.3 — Type system (`native/src/types/`)

**Files I create:**

`shader_type.h` — enum with all types (base + semantic):
```
VOID, BOOL, INT, UINT, FLOAT, VEC2, VEC3, VEC4, COLOR,
MAT3, MAT4, SAMPLER2D, SAMPLER_CUBE,
UV, SCREEN_UV, NORMAL, WORLD_NORMAL, POSITION, WORLD_POSITION,
VIEW_DIRECTION, LIGHT_DIRECTION, TIME, DEPTH
```

`type_system.h/.cpp` — static class:
```
are_compatible(from, to) → bool
get_cast_type(from, to) → CastType (EXACT, IMPLICIT_SPLAT, IMPLICIT_TRUNCATE, INCOMPATIBLE)
get_base_type(semantic_type) → ShaderType
type_to_glsl(type) → String         e.g. VEC3 → "vec3"
get_component_count(type) → int
```

`port_definition.h` — struct:
```
id, name, type (ShaderType), default_value (Variant), optional (bool)
```

---

### A.4 — Node registry (`native/src/registry/`)

**Files I create:**

`shader_node_definition.h/.cpp` — `Resource` subclass (see node-definition-spec.md)

`node_registry.h/.cpp` — singleton `Object`:
```
register_definition(def)
get_definition(id) → ShaderNodeDefinition*
get_all_in_category(category) → Array
search(query) → Array
get_categories() → PackedStringArray
get_all_definitions() → Array
```

`stdlib/` — one `.h/.cpp` file per category:
```
stdlib_math.cpp         Add, Sub, Mul, Div, Power, Sqrt, Abs, Negate, Floor, Ceil, Round, Fract, Mod, Min, Max, Sign
stdlib_trig.cpp         Sin, Cos, Tan, Atan2
stdlib_vector.cpp       Dot, Cross, Normalize, Length, Distance, Reflect, Refract
stdlib_float_ops.cpp    Lerp, Clamp, Smoothstep, Step, Saturate, Remap
stdlib_swizzle.cpp      Split (vec→components), Append (components→vec), Swizzle
stdlib_color.cpp        Blend, ColorToVec, VecToColor, HSVtoRGB, RGBtoHSV
stdlib_uv.cpp           Panner, Rotator, TilingOffset
stdlib_texture.cpp      SampleTexture2D, SampleTextureCube
stdlib_input.cpp        Time, ScreenUV, VertexNormal, WorldPosition, ViewDirection
stdlib_parameters.cpp   FloatParameter, Vec4Parameter, ColorParameter, Texture2DParameter
stdlib_output.cpp       SpatialOutput (albedo, roughness, metallic, emission, normal, alpha, ao)
```

`stdlib_registration.h/.cpp` — calls all stdlib_*.cpp register functions:
```cpp
void register_stdlib(NodeRegistry* registry) {
    register_stdlib_math(registry);
    register_stdlib_trig(registry);
    // ...
}
```

---

### A.5 — Validation (`native/src/validation/`)

**Files I create:**

`validation_issue.h` — struct: severity (ERROR/WARNING/INFO), node_id, port_id, message, code

`validation_result.h` — struct: issues[], has_errors(), get_errors(), get_warnings()

`validation_engine.h/.cpp`:
```
validate(doc, registry) → ValidationResult
  → pass_structural()
  → pass_typing()
  → pass_stage()
  → pass_cycles()
  → pass_outputs()
```

---

### A.6 — IR (`native/src/ir/`)

**Files I create:**

`ir_types.h` — structs: IRValue (variable name + type), IRUniform (name, type, default), IRVarying (name, type)

`ir_node.h` — struct: id, definition_id, resolved_inputs HashMap, output_vars HashMap, template, stage

`ir_graph.h` — struct: vertex_nodes[], fragment_nodes[], uniforms[], varyings[], helper_functions[]

`ir_builder.h/.cpp`:
```
build(doc, registry, validation_result) → IRGraph
  - topological_sort(doc)
  - resolve_node_inputs(node, doc, resolved_vars)
  - assign_output_vars(node, counter)
  - collect_uniforms(doc)
  - collect_varyings(typed_graph)
  - split_stages(sorted_nodes)
```

---

### A.7 — Compiler (`native/src/compiler/`)

**Files I create:**

`compile_result.h` — struct: success, shader_code, issues[], compiler_version, source_uuid

`emit_backend.h` — abstract base class:
```
virtual String emit(const IRGraph& ir) = 0;
virtual String get_shader_type_declaration() = 0;
```

`emit_backend_spatial.h/.cpp` — emits `shader_type spatial;` + vertex/fragment bodies

`shader_graph_compiler.h/.cpp`:
```
compile(doc) → CompileResult
  - runs all validation passes
  - builds IR
  - selects backend by domain
  - calls backend.emit()
  - prepends file header banner
```

---

### A.8 — Serializer (`native/src/serializer/`)

**Files I create:**

`graph_serializer.h/.cpp`:
```
save(doc, path) → Error         writes JSON to .gshadergraph
load(path) → ShaderGraphDocument*
  - reads JSON
  - checks format_version
  - runs migration if needed
  - deserializes nodes, edges, parameters

static migrate(dict, from_version, to_version) → Dictionary
```

Format: pretty-printed JSON (readable diffs in git).

---

### A.9 — Register all classes (`native/src/core/register_types.cpp`)

**I create:**
```cpp
void initialize_ss_godot_shader_studio_module(ModuleInitializationLevel p_level) {
    if (p_level == MODULE_INITIALIZATION_LEVEL_SCENE) {
        ClassDB::register_class<ShaderGraphDocument>();
        ClassDB::register_class<ShaderGraphNodeInstance>();
        ClassDB::register_class<ShaderGraphEdge>();
        ClassDB::register_class<ShaderNodeDefinition>();
        ClassDB::register_class<NodeRegistry>();
        ClassDB::register_class<ValidationEngine>();
        ClassDB::register_class<ShaderGraphCompiler>();
        ClassDB::register_class<GraphSerializer>();

        NodeRegistry* registry = memnew(NodeRegistry);
        Engine::get_singleton()->register_singleton("NodeRegistry", registry);
        register_stdlib(registry);
    }
}
```

---

## Phase B — First usable vertical slice

### B.1 — Addon plugin base

**Files I create:**
- `addons/ss_godot_shader_studio/plugin.gd`
- `addons/ss_godot_shader_studio/scripts/shader_graph_editor.gd`
- `addons/ss_godot_shader_studio/scripts/graph_canvas_controller.gd`
- `addons/ss_godot_shader_studio/scripts/node_search_controller.gd`
- `addons/ss_godot_shader_studio/scripts/node_inspector_controller.gd`
- `addons/ss_godot_shader_studio/scripts/toolbar_controller.gd`
- `addons/ss_godot_shader_studio/scripts/graph_file_manager.gd`
- `addons/ss_godot_shader_studio/scripts/compiler_output_panel.gd`
- `addons/ss_godot_shader_studio/scripts/preview_controller.gd`

**Scenes you create (Godot editor):**
- `scenes/shader_graph_editor.tscn` — main window
- `scenes/graph_node_visual.tscn` — GraphNode for each shader node
- `scenes/node_search_popup.tscn` — search popup
- `scenes/node_inspector.tscn` — right panel
- `scenes/compiler_output.tscn` — bottom panel
- `scenes/preview_viewport.tscn` — SubViewport + camera + light + MeshInstance3D

**Signal connections to make in editor (per scene):**
```
shader_graph_editor.tscn:
  GraphEdit.connection_request     → GraphCanvasController._on_connection_request
  GraphEdit.disconnection_request  → GraphCanvasController._on_disconnection_request
  GraphEdit.node_selected          → ShaderGraphEditor._on_node_selected
  GraphEdit.popup_request          → NodeSearchController._on_canvas_popup

node_search_popup.tscn:
  LineEdit.text_changed            → NodeSearchController._on_search_text_changed
  ItemList.item_activated          → NodeSearchController._on_node_selected

toolbar (inside shader_graph_editor.tscn):
  CompileButton.pressed            → ToolbarController._on_compile_pressed
  SaveButton.pressed               → ToolbarController._on_save_pressed
  DomainOption.item_selected       → ToolbarController._on_domain_changed
```

---

## Phase C — Serious product core

### C.1 — Validation overlay
**Files I create:**
- `scripts/validation_overlay.gd` — reads ValidationResult, applies error styling to GraphNodes, shows tooltips on ports

### C.2 — Parameters panel
**Files I create:** `scripts/parameters_panel_controller.gd`
**Scenes you create:** `scenes/parameters_panel.tscn`

### C.3 — Subgraphs
**Files I create:**
- `native/src/compiler/subgraph_resolver.h/.cpp`
- `native/src/serializer/subgraph_serializer.h/.cpp`
- `scripts/subgraph_browser_controller.gd`
- `scripts/subgraph_editor_controller.gd`
**Scenes you create:** `scenes/subgraph_browser.tscn`

### C.4 — Custom Function Node
**Files I create:**
- `native/src/registry/custom_function_definition.h/.cpp`
- `scripts/custom_function_editor_controller.gd`
**Scenes you create:** `scenes/custom_function_editor.tscn` (CodeEdit-based popup)

### C.5 — Per-node preview
**Files I create:**
- `native/src/preview/node_preview_compiler.h/.cpp`
- `scripts/node_preview_renderer.gd`
**You add:** TextureRect to `graph_node_visual.tscn`

---

## Phase D — Domain expansion

**Files I create:**
- `native/src/compiler/emit_backend_canvas_item.h/.cpp`
- `native/src/compiler/emit_backend_particles.h/.cpp`
- `native/src/compiler/emit_backend_sky.h/.cpp`
- `native/src/compiler/emit_backend_fog.h/.cpp`
- `native/src/compiler/emit_backend_fullscreen.h/.cpp`
- `native/src/registry/stdlib/stdlib_canvas_item.cpp`
- `native/src/registry/stdlib/stdlib_particles.cpp`
- `native/src/registry/stdlib/stdlib_sky.cpp`
- `native/src/registry/stdlib/stdlib_screen_effects.cpp`
- `native/src/registry/stdlib/stdlib_advanced.cpp` — Triplanar, Fresnel, Noise, Dither, Dissolve, Toon Ramp

---

## Phase E — 1.0.0 Hardening

**Files I create:**
- `native/tests/CMakeLists.txt`
- `native/tests/core/` — unit tests
- `native/tests/compiler/` — golden tests
- `native/tests/fixtures/` — `.gshadergraph` + `.gdshader` expected pairs
- `.github/workflows/ci.yml` — build + test all platforms
- `.github/workflows/release.yml` — package addon zip
- `docs/user-guide/getting-started.md`
- `docs/user-guide/creating-nodes.md`

---

## Recommended start order

```
Start here: Phase A.1 + A.2
  → Repo compiles, "Hello World" node visible in Godot

Then: A.3 + A.4 (types + registry with 5 nodes)
Then: A.5 + A.6 (validation + IR)
Then: A.7 + A.8 + A.9 (compiler + serializer + registration)

Milestone A: hardcoded Add+Multiply+SpatialOutput graph → valid .gdshader

Then: Phase B (you create scenes, I create scripts in parallel)

Milestone B: open .gshadergraph, connect nodes, see preview

Continue: C → D → E
```
