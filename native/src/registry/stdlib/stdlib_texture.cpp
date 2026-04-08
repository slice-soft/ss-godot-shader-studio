#include "stdlib_texture.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_texture(NodeRegistry *registry) {
    BEGIN_DEF("texture/sample_2d", "Sample Texture 2D", "Texture")
    KEYWORDS("texture", "sample", "tex2d", "sample2d", "texture2d")
    INPUT("tex", "Texture", SAMPLER2D, Variant())
    INPUT("uv", "UV", UV, Variant())
    OUTPUT("rgba", "RGBA", COLOR)
    OUTPUT("rgb", "RGB", VEC3)
    OUTPUT("r", "R", FLOAT)
    OUTPUT("g", "G", FLOAT)
    OUTPUT("b", "B", FLOAT)
    OUTPUT("a", "A", FLOAT)
    TEMPLATE(
        "vec4 {rgba} = texture({tex}, {uv});\n"
        "vec3 {rgb} = {rgba}.rgb;\n"
        "float {r} = {rgba}.r;\n"
        "float {g} = {rgba}.g;\n"
        "float {b} = {rgba}.b;\n"
        "float {a} = {rgba}.a;"
    )
    STAGE(STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("texture/sample_cube", "Sample Texture Cube", "Texture")
    KEYWORDS("cubemap", "cube texture", "skybox sample", "environment sample")
    INPUT("tex", "Texture", SAMPLER_CUBE, Variant())
    INPUT("dir", "Direction", VEC3, Variant())
    OUTPUT("rgba", "RGBA", COLOR)
    OUTPUT("rgb", "RGB", VEC3)
    TEMPLATE(
        "vec4 {rgba} = texture({tex}, {dir});\n"
        "vec3 {rgb} = {rgba}.rgb;"
    )
    STAGE(STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
