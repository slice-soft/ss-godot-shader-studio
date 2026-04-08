#include "stdlib_registration.h"

#include "stdlib_math.h"
#include "stdlib_trig.h"
#include "stdlib_vector.h"
#include "stdlib_float_ops.h"
#include "stdlib_swizzle.h"
#include "stdlib_color.h"
#include "stdlib_uv.h"
#include "stdlib_texture.h"
#include "stdlib_input.h"
#include "stdlib_parameters.h"
#include "stdlib_output.h"

void register_stdlib(NodeRegistry *registry) {
    register_stdlib_math(registry);
    register_stdlib_trig(registry);
    register_stdlib_vector(registry);
    register_stdlib_float_ops(registry);
    register_stdlib_swizzle(registry);
    register_stdlib_color(registry);
    register_stdlib_uv(registry);
    register_stdlib_texture(registry);
    register_stdlib_input(registry);
    register_stdlib_parameters(registry);
    register_stdlib_output(registry);
}
