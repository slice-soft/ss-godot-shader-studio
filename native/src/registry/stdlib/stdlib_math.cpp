#include "stdlib_math.h"
#include "stdlib_helpers.h"

using namespace sgs;

void register_stdlib_math(NodeRegistry *registry) {
    // Add
    BEGIN_DEF("math/add", "Add", "Math")
    KEYWORDS("add", "sum", "plus", "+")
    INPUT("a", "A", FLOAT, 0.0f)
    INPUT("b", "B", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = {a} + {b};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Subtract
    BEGIN_DEF("math/subtract", "Subtract", "Math")
    KEYWORDS("subtract", "sub", "minus", "-")
    INPUT("a", "A", FLOAT, 0.0f)
    INPUT("b", "B", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = {a} - {b};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Multiply
    BEGIN_DEF("math/multiply", "Multiply", "Math")
    KEYWORDS("multiply", "mul", "times", "*", "product")
    INPUT("a", "A", FLOAT, 1.0f)
    INPUT("b", "B", FLOAT, 1.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = {a} * {b};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Divide
    BEGIN_DEF("math/divide", "Divide", "Math")
    KEYWORDS("divide", "div", "/", "quotient")
    INPUT("a", "A", FLOAT, 1.0f)
    INPUT("b", "B", FLOAT, 1.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = {a} / {b};")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Power
    BEGIN_DEF("math/power", "Power", "Math")
    KEYWORDS("power", "pow", "exponent", "^")
    INPUT("base", "Base", FLOAT, 1.0f)
    INPUT("exp", "Exp", FLOAT, 2.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = pow({base}, {exp});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Sqrt
    BEGIN_DEF("math/sqrt", "Square Root", "Math")
    KEYWORDS("sqrt", "square root", "root")
    INPUT("x", "X", FLOAT, 1.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = sqrt({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Abs
    BEGIN_DEF("math/abs", "Absolute", "Math")
    KEYWORDS("abs", "absolute", "magnitude")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = abs({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Negate
    BEGIN_DEF("math/negate", "Negate", "Math")
    KEYWORDS("negate", "negative", "flip sign")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = -({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Floor
    BEGIN_DEF("math/floor", "Floor", "Math")
    KEYWORDS("floor", "round down")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = floor({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Ceil
    BEGIN_DEF("math/ceil", "Ceil", "Math")
    KEYWORDS("ceil", "ceiling", "round up")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = ceil({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Round
    BEGIN_DEF("math/round", "Round", "Math")
    KEYWORDS("round", "nearest integer")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = round({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Fract
    BEGIN_DEF("math/fract", "Fract", "Math")
    KEYWORDS("fract", "fractional", "decimal part")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = fract({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Mod
    BEGIN_DEF("math/mod", "Mod", "Math")
    KEYWORDS("mod", "modulo", "remainder", "%")
    INPUT("x", "X", FLOAT, 0.0f)
    INPUT("y", "Y", FLOAT, 1.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = mod({x}, {y});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Min
    BEGIN_DEF("math/min", "Min", "Math")
    KEYWORDS("min", "minimum", "smaller")
    INPUT("a", "A", FLOAT, 0.0f)
    INPUT("b", "B", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = min({a}, {b});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Max
    BEGIN_DEF("math/max", "Max", "Math")
    KEYWORDS("max", "maximum", "larger")
    INPUT("a", "A", FLOAT, 0.0f)
    INPUT("b", "B", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = max({a}, {b});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)

    // Sign
    BEGIN_DEF("math/sign", "Sign", "Math")
    KEYWORDS("sign", "signum")
    INPUT("x", "X", FLOAT, 0.0f)
    OUTPUT("result", "Result", FLOAT)
    TEMPLATE("float {result} = sign({x});")
    STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
    END_DEF(registry)
}
