#include "stdlib_uv.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_uv(NodeRegistry *registry) {
    BEGIN_DEF("uv/panner", "Panner", "UV")
    KEYWORDS("panner", "scroll", "pan uv", "animate uv")
    INPUT("uv", "UV", UV, Variant())
    INPUT("speed", "Speed", VEC2, Variant())
    INPUT("time", "Time", TIME, 0.0f)
    OUTPUT("result", "Result", UV)
    TEMPLATE("vec2 {result} = {uv} + {speed} * {time};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("uv/rotator", "Rotator", "UV")
    KEYWORDS("rotator", "rotate uv", "spin uv")
    INPUT("uv", "UV", UV, Variant())
    INPUT("center", "Center", VEC2, Variant())
    INPUT("angle", "Angle", FLOAT, 0.0f)
    OUTPUT("result", "Result", UV)
    TEMPLATE(
        "float _cos_r_{result} = cos({angle});\n"
        "float _sin_r_{result} = sin({angle});\n"
        "vec2 _uv_c_{result} = {uv} - {center};\n"
        "vec2 {result} = vec2(_cos_r_{result} * _uv_c_{result}.x - _sin_r_{result} * _uv_c_{result}.y,"
        " _sin_r_{result} * _uv_c_{result}.x + _cos_r_{result} * _uv_c_{result}.y) + {center};"
    )
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("uv/tiling_offset", "Tiling & Offset", "UV")
    KEYWORDS("tiling", "offset", "uv tiling", "uv offset", "repeat")
    INPUT("uv", "UV", UV, Variant())
    INPUT("tiling", "Tiling", VEC2, Variant())
    INPUT("offset", "Offset", VEC2, Variant())
    OUTPUT("result", "Result", UV)
    TEMPLATE("vec2 {result} = {uv} * {tiling} + {offset};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
