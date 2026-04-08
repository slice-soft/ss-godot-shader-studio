#include "stdlib_trig.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_trig(NodeRegistry *registry) {
    BEGIN_DEF("trig/sin", "Sin", "Trigonometry")
    KEYWORDS("sin", "sine")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = sin({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("trig/cos", "Cos", "Trigonometry")
    KEYWORDS("cos", "cosine")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = cos({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("trig/tan", "Tan", "Trigonometry")
    KEYWORDS("tan", "tangent")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = tan({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("trig/atan2", "Atan2", "Trigonometry")
    KEYWORDS("atan2", "atan", "arctangent2")
    INPUT("y", "Y", FLOAT, 0.0f)
    INPUT("x", "X", FLOAT, 1.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = atan({y}, {x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
