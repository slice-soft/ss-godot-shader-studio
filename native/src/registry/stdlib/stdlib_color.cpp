#include "stdlib_color.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_color(NodeRegistry *registry) {
    // Color blend (multiply)
    BEGIN_DEF("color/blend", "Blend", "Color")
    KEYWORDS("blend", "multiply color", "color multiply")
    INPUT("a", "A", COLOR, Variant())
    INPUT("b", "B", COLOR, Variant())
    OUTPUT("result", "Result", COLOR)
    TEMPLATE("vec4 {result} = {a} * {b};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Color to Vec3 (rgb)
    BEGIN_DEF("color/color_to_vec3", "Color to Vec3", "Color")
    KEYWORDS("color to vec3", "rgb", "extract rgb")
    INPUT("color", "Color", COLOR, Variant())
    OUTPUT("rgb", "RGB", VEC3)
    TEMPLATE("vec3 {rgb} = {color}.rgb;")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Vec3 to Color
    BEGIN_DEF("color/vec3_to_color", "Vec3 to Color", "Color")
    KEYWORDS("vec3 to color", "make color", "rgba from rgb")
    INPUT("rgb", "RGB", VEC3, Variant())
    INPUT("a", "Alpha", FLOAT, 1.0f)
    OUTPUT("color", "Color", COLOR)
    TEMPLATE("vec4 {color} = vec4({rgb}, {a});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // HSV to RGB
    BEGIN_DEF("color/hsv_to_rgb", "HSV to RGB", "Color")
    KEYWORDS("hsv", "hsv to rgb", "hue saturation value")
    INPUT("hsv", "HSV", VEC3, Variant())
    OUTPUT("rgb", "RGB", VEC3)
    TEMPLATE(
        "vec3 _hsv_c_{rgb} = vec3(abs({hsv}.x * 6.0 - 3.0) - 1.0, 2.0 - abs({hsv}.x * 6.0 - 2.0), 2.0 - abs({hsv}.x * 6.0 - 4.0));\n"
        "vec3 {rgb} = ((clamp(_hsv_c_{rgb}, 0.0, 1.0) - 1.0) * {hsv}.y + 1.0) * {hsv}.z;"
    )
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // RGB to HSV
    BEGIN_DEF("color/rgb_to_hsv", "RGB to HSV", "Color")
    KEYWORDS("rgb to hsv", "hue saturation value", "colour space")
    INPUT("rgb", "RGB", VEC3, Variant())
    OUTPUT("hsv", "HSV", VEC3)
    TEMPLATE(
        "vec4 _p_{hsv} = ({rgb}.g < {rgb}.b) ? vec4({rgb}.bg, -1.0, 2.0/3.0) : vec4({rgb}.gb, 0.0, -1.0/3.0);\n"
        "vec4 _q_{hsv} = ({rgb}.r < _p_{hsv}.x) ? vec4(_p_{hsv}.xyw, {rgb}.r) : vec4({rgb}.r, _p_{hsv}.yzx);\n"
        "float _d_{hsv} = _q_{hsv}.x - min(_q_{hsv}.w, _q_{hsv}.y);\n"
        "vec3 {hsv} = vec3(abs(_q_{hsv}.z + (_q_{hsv}.w - _q_{hsv}.y) / (6.0 * _d_{hsv} + 1e-10)), _d_{hsv} / (_q_{hsv}.x + 1e-10), _q_{hsv}.x);"
    )
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
