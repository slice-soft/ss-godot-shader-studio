#include "stdlib_parameters.h"
#include "stdlib_helpers.h"

using namespace sgs;

// Parameter nodes emit a uniform declaration.
// The compiler_template uses the node's property "param_name" at emit time.
// For Phase A, the param name is embedded in the template as a placeholder
// resolved by the emitter using the node's properties.

void register_stdlib_parameters(NodeRegistry *registry) {
    BEGIN_DEF("parameter/float", "Float Parameter", "Parameters")
    KEYWORDS("float parameter", "uniform float", "shader property float")
    OUTPUT("value", "Value", FLOAT)
    TEMPLATE("// uniform float {param_name};\nfloat {value} = {param_name};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    PREVIEW(NONE)
    END_DEF(registry)

    BEGIN_DEF("parameter/vec4", "Vec4 Parameter", "Parameters")
    KEYWORDS("vec4 parameter", "uniform vec4", "shader property vec4")
    OUTPUT("value", "Value", VEC4)
    TEMPLATE("// uniform vec4 {param_name};\nvec4 {value} = {param_name};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    PREVIEW(NONE)
    END_DEF(registry)

    BEGIN_DEF("parameter/color", "Color Parameter", "Parameters")
    KEYWORDS("color parameter", "uniform color", "shader property color", "tint")
    OUTPUT("value", "Value", COLOR)
    TEMPLATE("// uniform vec4 {param_name};\nvec4 {value} = {param_name};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    PREVIEW(NONE)
    END_DEF(registry)

    BEGIN_DEF("parameter/texture2d", "Texture2D Parameter", "Parameters")
    KEYWORDS("texture parameter", "uniform sampler2d", "shader texture property")
    OUTPUT("value", "Value", SAMPLER2D)
    TEMPLATE("// uniform sampler2D {param_name};\n// sampler2D {value} = {param_name};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    PREVIEW(NONE)
    END_DEF(registry)
}
