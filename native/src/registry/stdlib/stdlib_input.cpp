#include "stdlib_input.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_input(NodeRegistry *registry) {
    BEGIN_DEF("input/time", "Time", "Input")
    KEYWORDS("time", "seconds", "elapsed time", "animation time")
    OUTPUT("time", "Time", TIME)
    TEMPLATE("float {time} = TIME;")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("input/screen_uv", "Screen UV", "Input")
    KEYWORDS("screen uv", "screen coordinates", "viewport uv")
    OUTPUT("uv", "UV", SCREEN_UV)
    TEMPLATE("vec2 {uv} = SCREEN_UV;")
    STAGE(STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_SPATIAL)
    END_DEF(registry)

    BEGIN_DEF("input/vertex_normal", "Vertex Normal", "Input")
    KEYWORDS("normal", "vertex normal", "surface normal", "object normal")
    OUTPUT("normal", "Normal", NORMAL)
    TEMPLATE("vec3 {normal} = NORMAL;")
    STAGE(STAGE_VERTEX | STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_SPATIAL)
    END_DEF(registry)

    BEGIN_DEF("input/world_position", "World Position", "Input")
    KEYWORDS("world position", "vertex position", "model matrix", "position")
    OUTPUT("pos", "Position", WORLD_POSITION)
    TEMPLATE("vec3 {pos} = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;")
    STAGE(STAGE_VERTEX) SGS_DOMAIN(DOMAIN_SPATIAL)
    END_DEF(registry)

    BEGIN_DEF("input/view_direction", "View Direction", "Input")
    KEYWORDS("view direction", "camera direction", "view vector", "eye direction")
    OUTPUT("dir", "Direction", VIEW_DIRECTION)
    TEMPLATE("vec3 {dir} = VIEW;")
    STAGE(STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_SPATIAL)
    END_DEF(registry)

    BEGIN_DEF("input/uv", "UV", "Input")
    KEYWORDS("uv", "texture coordinates", "uv0")
    OUTPUT("uv", "UV", UV)
    TEMPLATE("vec2 {uv} = UV;")
    STAGE(STAGE_VERTEX | STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_SPATIAL)
    END_DEF(registry)
}
