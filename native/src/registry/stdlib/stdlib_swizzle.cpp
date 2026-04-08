#include "stdlib_swizzle.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_swizzle(NodeRegistry *registry) {
    // Split vec4 into components
    BEGIN_DEF("swizzle/split_vec4", "Split Vec4", "Swizzle")
    KEYWORDS("split", "swizzle", "components", "xyzw", "rgba")
    INPUT("v", "V", VEC4, Variant())
    OUTPUT("x", "X", FLOAT)
    OUTPUT("y", "Y", FLOAT)
    OUTPUT("z", "Z", FLOAT)
    OUTPUT("w", "W", FLOAT)
    TEMPLATE("float {x} = {v}.x;\nfloat {y} = {v}.y;\nfloat {z} = {v}.z;\nfloat {w} = {v}.w;")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Split vec3 into components
    BEGIN_DEF("swizzle/split_vec3", "Split Vec3", "Swizzle")
    KEYWORDS("split", "swizzle", "xyz", "components")
    INPUT("v", "V", VEC3, Variant())
    OUTPUT("x", "X", FLOAT)
    OUTPUT("y", "Y", FLOAT)
    OUTPUT("z", "Z", FLOAT)
    TEMPLATE("float {x} = {v}.x;\nfloat {y} = {v}.y;\nfloat {z} = {v}.z;")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Split vec2 into components
    BEGIN_DEF("swizzle/split_vec2", "Split Vec2", "Swizzle")
    KEYWORDS("split", "swizzle", "xy", "uv", "components")
    INPUT("v", "V", VEC2, Variant())
    OUTPUT("x", "X", FLOAT)
    OUTPUT("y", "Y", FLOAT)
    TEMPLATE("float {x} = {v}.x;\nfloat {y} = {v}.y;")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Append floats into vec2
    BEGIN_DEF("swizzle/append_vec2", "Append Vec2", "Swizzle")
    KEYWORDS("append", "combine", "make vec2", "xy")
    INPUT("x", "X", FLOAT, 0.0f)
    INPUT("y", "Y", FLOAT, 0.0f)
    OUTPUT("result", "Result", VEC2)
    TEMPLATE("vec2 {result} = vec2({x}, {y});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Append floats into vec3
    BEGIN_DEF("swizzle/append_vec3", "Append Vec3", "Swizzle")
    KEYWORDS("append", "combine", "make vec3", "xyz")
    INPUT("x", "X", FLOAT, 0.0f)
    INPUT("y", "Y", FLOAT, 0.0f)
    INPUT("z", "Z", FLOAT, 0.0f)
    OUTPUT("result", "Result", VEC3)
    TEMPLATE("vec3 {result} = vec3({x}, {y}, {z});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Append floats into vec4
    BEGIN_DEF("swizzle/append_vec4", "Append Vec4", "Swizzle")
    KEYWORDS("append", "combine", "make vec4", "xyzw", "rgba")
    INPUT("x", "X", FLOAT, 0.0f)
    INPUT("y", "Y", FLOAT, 0.0f)
    INPUT("z", "Z", FLOAT, 0.0f)
    INPUT("w", "W", FLOAT, 1.0f)
    OUTPUT("result", "Result", VEC4)
    TEMPLATE("vec4 {result} = vec4({x}, {y}, {z}, {w});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
