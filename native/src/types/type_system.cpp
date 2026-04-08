#include "type_system.h"

namespace sgs {

// ---- Semantic → base type mapping ----

ShaderType TypeSystem::get_base_type(ShaderType t) {
    switch (t) {
        case ShaderType::UV:
        case ShaderType::SCREEN_UV:
            return ShaderType::VEC2;

        case ShaderType::NORMAL:
        case ShaderType::WORLD_NORMAL:
        case ShaderType::POSITION:
        case ShaderType::WORLD_POSITION:
        case ShaderType::VIEW_DIRECTION:
        case ShaderType::LIGHT_DIRECTION:
            return ShaderType::VEC3;

        case ShaderType::COLOR:
            return ShaderType::VEC4;

        case ShaderType::TIME:
        case ShaderType::DEPTH:
            return ShaderType::FLOAT;

        default:
            return t;
    }
}

// ---- Component counts ----

int TypeSystem::get_component_count(ShaderType t) {
    ShaderType base = get_base_type(t);
    switch (base) {
        case ShaderType::BOOL:
        case ShaderType::INT:
        case ShaderType::UINT:
        case ShaderType::FLOAT:
            return 1;
        case ShaderType::VEC2:
            return 2;
        case ShaderType::VEC3:
            return 3;
        case ShaderType::VEC4:
            return 4;
        case ShaderType::MAT3:
            return 9;
        case ShaderType::MAT4:
            return 16;
        default:
            return 0;
    }
}

// ---- GLSL keyword ----

String TypeSystem::type_to_glsl(ShaderType t) {
    ShaderType base = get_base_type(t);
    switch (base) {
        case ShaderType::VOID:         return "void";
        case ShaderType::BOOL:         return "bool";
        case ShaderType::INT:          return "int";
        case ShaderType::UINT:         return "uint";
        case ShaderType::FLOAT:        return "float";
        case ShaderType::VEC2:         return "vec2";
        case ShaderType::VEC3:         return "vec3";
        case ShaderType::VEC4:         return "vec4";
        case ShaderType::MAT3:         return "mat3";
        case ShaderType::MAT4:         return "mat4";
        case ShaderType::SAMPLER2D:    return "sampler2D";
        case ShaderType::SAMPLER_CUBE: return "samplerCube";
        default:                       return "";
    }
}

// ---- Display name ----

String TypeSystem::type_to_display_name(ShaderType t) {
    switch (t) {
        case ShaderType::VOID:           return "Void";
        case ShaderType::BOOL:           return "Bool";
        case ShaderType::INT:            return "Int";
        case ShaderType::UINT:           return "UInt";
        case ShaderType::FLOAT:          return "Float";
        case ShaderType::VEC2:           return "Vec2";
        case ShaderType::VEC3:           return "Vec3";
        case ShaderType::VEC4:           return "Vec4";
        case ShaderType::COLOR:          return "Color";
        case ShaderType::MAT3:           return "Mat3";
        case ShaderType::MAT4:           return "Mat4";
        case ShaderType::SAMPLER2D:      return "Texture2D";
        case ShaderType::SAMPLER_CUBE:   return "TextureCube";
        case ShaderType::UV:             return "UV";
        case ShaderType::SCREEN_UV:      return "ScreenUV";
        case ShaderType::NORMAL:         return "Normal";
        case ShaderType::WORLD_NORMAL:   return "WorldNormal";
        case ShaderType::POSITION:       return "Position";
        case ShaderType::WORLD_POSITION: return "WorldPosition";
        case ShaderType::VIEW_DIRECTION: return "ViewDirection";
        case ShaderType::LIGHT_DIRECTION:return "LightDirection";
        case ShaderType::TIME:           return "Time";
        case ShaderType::DEPTH:          return "Depth";
        default:                         return "Unknown";
    }
}

// ---- Cast type ----

CastType TypeSystem::get_cast_type(ShaderType from, ShaderType to) {
    if (from == to) {
        return CastType::EXACT;
    }

    ShaderType from_base = get_base_type(from);
    ShaderType to_base   = get_base_type(to);

    // Semantic to its own base type
    if (from != from_base && from_base == to) {
        return CastType::IMPLICIT_SEMANTIC;
    }
    // Semantic to semantic with same base
    if (from_base == to_base && from_base != from && to_base != to) {
        return CastType::IMPLICIT_SEMANTIC;
    }

    // Normalise to base for the remaining rules
    ShaderType f = from_base;
    ShaderType t = to_base;

    if (f == t) {
        return CastType::IMPLICIT_SEMANTIC;
    }

    // float → vecN splat
    if (f == ShaderType::FLOAT) {
        if (t == ShaderType::VEC2 || t == ShaderType::VEC3 || t == ShaderType::VEC4) {
            return CastType::IMPLICIT_SPLAT;
        }
    }

    // vecN → vecM truncation (N > M)
    int fc = get_component_count(f);
    int tc = get_component_count(t);
    if (fc > 1 && tc > 1 && fc > tc) {
        return CastType::IMPLICIT_TRUNCATE;
    }

    return CastType::INCOMPATIBLE;
}

// ---- Compatibility ----

bool TypeSystem::are_compatible(ShaderType from, ShaderType to) {
    CastType c = get_cast_type(from, to);
    return c != CastType::INCOMPATIBLE;
}

} // namespace sgs
