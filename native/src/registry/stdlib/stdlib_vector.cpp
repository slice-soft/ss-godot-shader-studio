#include "stdlib_vector.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_vector(NodeRegistry *registry) {
    BEGIN_DEF("vector/dot", "Dot Product", "Vector")
    KEYWORDS("dot", "dot product", "inner product")
    INPUT("a", "A", VEC3, Variant())
    INPUT("b", "B", VEC3, Variant())
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = dot({a}, {b});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("vector/cross", "Cross Product", "Vector")
    KEYWORDS("cross", "cross product")
    INPUT("a", "A", VEC3, Variant())
    INPUT("b", "B", VEC3, Variant())
    OUTPUT("result", "Result", VEC3)
    TEMPLATE("vec3 {result} = cross({a}, {b});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("vector/normalize", "Normalize", "Vector")
    KEYWORDS("normalize", "unit vector", "direction")
    INPUT("v", "V", VEC3, Variant())
    OUTPUT("result", "Result", VEC3)
    TEMPLATE("vec3 {result} = normalize({v});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("vector/length", "Length", "Vector")
    KEYWORDS("length", "magnitude", "distance from zero")
    INPUT("v", "V", VEC3, Variant())
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = length({v});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("vector/distance", "Distance", "Vector")
    KEYWORDS("distance", "dist", "length between")
    INPUT("a", "A", VEC3, Variant())
    INPUT("b", "B", VEC3, Variant())
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = distance({a}, {b});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("vector/reflect", "Reflect", "Vector")
    KEYWORDS("reflect", "reflection")
    INPUT("incident", "Incident", VEC3, Variant())
    INPUT("normal", "Normal", VEC3, Variant())
    OUTPUT("result", "Result", VEC3)
    TEMPLATE("vec3 {result} = reflect({incident}, {normal});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    BEGIN_DEF("vector/refract", "Refract", "Vector")
    KEYWORDS("refract", "refraction", "ior")
    INPUT("incident", "Incident", VEC3, Variant())
    INPUT("normal", "Normal", VEC3, Variant())
    INPUT("ior", "IOR", FLOAT, 1.0f)
    OUTPUT("result", "Result", VEC3)
    TEMPLATE("vec3 {result} = refract({incident}, {normal}, {ior});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
