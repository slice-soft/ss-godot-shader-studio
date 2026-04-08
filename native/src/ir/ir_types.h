#pragma once

#include <godot_cpp/variant/string.hpp>
#include "../types/shader_type.h"

using namespace godot;

namespace sgs {

// A resolved value: the GLSL variable name assigned to a port output
struct IRValue {
    String var_name;   // e.g. "_t3"
    ShaderType type;
};

// A uniform declaration collected from parameter nodes
struct IRUniform {
    String name;           // e.g. "AlbedoColor"
    ShaderType type;
    String glsl_hint;      // e.g. ": source_color"
    String default_value;  // GLSL literal, e.g. "vec4(1.0)"
};

// A varying needed to pass data from vertex to fragment
struct IRVarying {
    String name;       // e.g. "_vary_world_pos"
    ShaderType type;
};

} // namespace sgs
