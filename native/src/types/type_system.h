#pragma once

#include <godot_cpp/variant/string.hpp>

#include "shader_type.h"

using namespace godot;

namespace sgs {

class TypeSystem {
public:
    TypeSystem() = delete;

    // Can a port of type `from` connect to a port expecting `to`?
    static bool are_compatible(ShaderType from, ShaderType to);

    // Determine the cast kind needed for an edge (from → to).
    static CastType get_cast_type(ShaderType from, ShaderType to);

    // If `t` is a semantic type (UV, NORMAL, …), return its underlying GLSL base type.
    // For non-semantic types returns `t` unchanged.
    static ShaderType get_base_type(ShaderType t);

    // GLSL keyword for a type, e.g. VEC3 → "vec3". Returns "" for VOID and unknowns.
    static String type_to_glsl(ShaderType t);

    // Number of scalar components (float = 1, vec3 = 3, mat4 = 16, …).
    static int get_component_count(ShaderType t);

    // Human-readable name for display in the editor UI.
    static String type_to_display_name(ShaderType t);
};

} // namespace sgs
