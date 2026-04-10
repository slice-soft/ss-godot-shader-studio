# Node Definition Spec

A `ShaderNodeDefinition` describes a reusable node type. It is registered in the `NodeRegistry` at startup and referenced by `definition_id` in graph documents.

## Fields

```gdscript
class_name ShaderNodeDefinition extends Resource

var id: String                    # e.g. "math/add"
var display_name: String          # e.g. "Add"
var category: String              # e.g. "Math"
var keywords: Array               # for search: ["add", "sum", "plus"]
var inputs: Array                 # Array of port Dictionaries
var outputs: Array                # Array of port Dictionaries
var properties_schema: Dictionary # editable properties on the node
var stage_support: int            # SGSTypes stage flags (STAGE_ANY, STAGE_VERTEX, etc.)
var domain_support: int           # SGSTypes domain flags (DOMAIN_ALL, DOMAIN_SPATIAL, etc.)
var compiler_template: String     # GLSL snippet with {port_id} placeholders
```

## Port Dictionary fields

Each entry in `inputs` and `outputs` is a Dictionary:

```gdscript
{
    "id":       String,    # matches placeholder in compiler_template
    "name":     String,    # display label
    "type":     int,       # SGSTypes.ShaderType value
    "default":  Variant,   # used when port is unconnected (optional)
    "optional": bool,      # if false, must be connected to compile
}
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
float {result} = mix({a}, {b}, {t});
// {prop:clamp_result} expands at compile time to "" or "result = clamp(result, 0.0, 1.0);"
```

## stage_support and domain_support

Bitfield values defined in `SGSTypes`:

```gdscript
# Stage flags
SGSTypes.STAGE_VERTEX   = 1 << 0
SGSTypes.STAGE_FRAGMENT = 1 << 1
SGSTypes.STAGE_LIGHT    = 1 << 2
SGSTypes.STAGE_ANY      = STAGE_VERTEX | STAGE_FRAGMENT | STAGE_LIGHT

# Domain flags
SGSTypes.DOMAIN_SPATIAL = 1 << 0
SGSTypes.DOMAIN_ALL     = 0x3F
```

A node available in all stages of spatial only:
```gdscript
stage_support  = SGSTypes.STAGE_ANY
domain_support = SGSTypes.DOMAIN_SPATIAL
```

A node only valid in the fragment stage across all domains:
```gdscript
stage_support  = SGSTypes.STAGE_FRAGMENT
domain_support = SGSTypes.DOMAIN_ALL
```

## Example: complete Add node definition

```gdscript
var add_def := ShaderNodeDefinition.new()
add_def.id           = "math/add"
add_def.display_name = "Add"
add_def.category     = "Math"
add_def.keywords     = ["add", "sum", "plus", "+"]
add_def.inputs = [
    {"id": "a", "name": "A", "type": SGSTypes.ShaderType.FLOAT, "default": 0.0, "optional": false},
    {"id": "b", "name": "B", "type": SGSTypes.ShaderType.FLOAT, "default": 0.0, "optional": false},
]
add_def.outputs = [
    {"id": "result", "name": "Result", "type": SGSTypes.ShaderType.FLOAT},
]
add_def.stage_support    = SGSTypes.STAGE_ANY
add_def.domain_support   = SGSTypes.DOMAIN_ALL
add_def.compiler_template = "float {result} = {a} + {b};"
registry.register_definition(add_def)
```

## Registering external node packages

Third-party addons can register their own node definitions at plugin load time:

```gdscript
# In the addon's plugin.gd _enter_tree():
var registry = Engine.get_singleton("NodeRegistry") as NodeRegistry
var my_def := ShaderNodeDefinition.new()
my_def.id = "myplugin/custom_noise"
# ... configure fields ...
registry.register_definition(my_def)
```

This is the full extensibility API — no C++ required, no recompilation needed.
