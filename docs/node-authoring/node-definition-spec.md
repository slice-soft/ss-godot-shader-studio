# Node Definition Spec

A `ShaderNodeDefinition` describes a reusable node type. It is registered in the `NodeRegistry` at startup and referenced by `definition_id` in graph documents.

## Fields

```cpp
class ShaderNodeDefinition : public Resource {
    String id;                    // e.g. "math/add"
    String display_name;          // e.g. "Add"
    String category;              // e.g. "Math"
    PackedStringArray keywords;   // for search: ["add", "sum", "plus"]
    Array inputs;                 // PortDefinition[]
    Array outputs;                // PortDefinition[]
    Dictionary properties_schema; // editable properties on the node
    int stage_support;            // bitfield: VERTEX | FRAGMENT | LIGHT
    int domain_support;           // bitfield of ShaderDomain values
    String compiler_template;     // GLSL snippet with {port_id} placeholders
    PreviewPolicy preview_policy; // FULL | THUMBNAIL | NONE
};
```

## PortDefinition fields

```cpp
struct PortDefinition {
    String id;            // matches placeholder in compiler_template
    String name;          // display label
    ShaderType type;      // type enum value
    Variant default_value; // used when port is unconnected
    bool optional;        // if false, must be connected to compile
};
```

## compiler_template syntax

The template is a GLSL snippet where port IDs are wrapped in `{}`.
Input ports appear as values, output ports appear as new variable declarations.

```glsl
// Add node — inputs: {a}, {b} — outputs: {result}
float {result} = {a} + {b};
```

```glsl
// Texture sample — inputs: {tex}, {uv} — outputs: {rgba}, {rgb}, {r}, {g}, {b}, {a}
vec4 {rgba} = texture({tex}, {uv});
vec3 {rgb} = {rgba}.rgb;
float {r} = {rgba}.r;
float {g} = {rgba}.g;
float {b} = {rgba}.b;
float {a} = {rgba}.a;
```

If the template requires multiple lines, all output variables must be declared within it.
The emitter does not wrap the template in any block — it is emitted inline in the stage body.

## properties_schema

Defines editable values shown in the node inspector. These are not port connections.

```json
{
  "clamp_result": {
    "type": "bool",
    "default": false,
    "label": "Clamp"
  },
  "blend_mode": {
    "type": "enum",
    "values": ["multiply", "add", "screen", "overlay"],
    "default": "multiply",
    "label": "Blend Mode"
  }
}
```

The compiler template can reference properties with `{prop:property_name}`:

```glsl
// Lerp with optional clamp
float {result} = mix({a}, {b}, {t});
// {prop:clamp_result} → expands to either "" or "result = clamp(result, 0.0, 1.0);"
```

## stage_support and domain_support

Bitfield values (defined in `shader_domain.h`):

```cpp
// Stage flags
const int STAGE_VERTEX   = 1 << 0;
const int STAGE_FRAGMENT = 1 << 1;
const int STAGE_LIGHT    = 1 << 2;
const int STAGE_ANY      = STAGE_VERTEX | STAGE_FRAGMENT | STAGE_LIGHT;

// Domain flags
const int DOMAIN_SPATIAL      = 1 << 0;
const int DOMAIN_CANVAS_ITEM  = 1 << 1;
const int DOMAIN_PARTICLES    = 1 << 2;
const int DOMAIN_SKY          = 1 << 3;
const int DOMAIN_FOG          = 1 << 4;
const int DOMAIN_FULLSCREEN   = 1 << 5;
const int DOMAIN_ALL          = 0x3F;
```

A node available in all stages of spatial only:
```cpp
stage_support = STAGE_ANY;
domain_support = DOMAIN_SPATIAL;
```

A node only valid in the fragment stage across all domains:
```cpp
stage_support = STAGE_FRAGMENT;
domain_support = DOMAIN_ALL;
```

## Example: complete Add node definition

```cpp
ShaderNodeDefinition* add_def = memnew(ShaderNodeDefinition);
add_def->set_id("math/add");
add_def->set_display_name("Add");
add_def->set_category("Math");
add_def->set_keywords({"add", "sum", "plus", "+"});

PortDefinition in_a;
in_a.id = "a";
in_a.name = "A";
in_a.type = ShaderType::FLOAT;
in_a.default_value = 0.0f;
in_a.optional = false;

PortDefinition in_b;
in_b.id = "b";
in_b.name = "B";
in_b.type = ShaderType::FLOAT;
in_b.default_value = 0.0f;
in_b.optional = false;

PortDefinition out_result;
out_result.id = "result";
out_result.name = "Result";
out_result.type = ShaderType::FLOAT;
out_result.optional = false;

add_def->set_inputs({in_a, in_b});
add_def->set_outputs({out_result});
add_def->set_stage_support(STAGE_ANY);
add_def->set_domain_support(DOMAIN_ALL);
add_def->set_compiler_template("float {result} = {a} + {b};");
add_def->set_preview_policy(PreviewPolicy::THUMBNAIL);

NodeRegistry::get_singleton()->register_definition(add_def);
```

## Registering external node packages

Third-party addons can register their own node definitions at plugin load time:

```gdscript
# In the addon's plugin.gd _enter_tree():
var registry = NodeRegistry.get_singleton()
var my_def = ShaderNodeDefinition.new()
my_def.id = "myplugin/custom_noise"
# ... configure fields ...
registry.register_definition(my_def)
```

This is the full extensibility API for Phase E.
