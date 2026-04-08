#pragma once

namespace sgs {

enum class ShaderType {
    // Primitives
    VOID = 0,
    BOOL,
    INT,
    UINT,
    FLOAT,
    // Vectors
    VEC2,
    VEC3,
    VEC4,
    COLOR,  // alias for vec4, displayed as colour picker
    // Matrices
    MAT3,
    MAT4,
    // Samplers
    SAMPLER2D,
    SAMPLER_CUBE,
    // Semantic types — map to a base type for GLSL, carry domain meaning
    UV,
    SCREEN_UV,
    NORMAL,
    WORLD_NORMAL,
    POSITION,
    WORLD_POSITION,
    VIEW_DIRECTION,
    LIGHT_DIRECTION,
    TIME,
    DEPTH,
    // Sentinel
    COUNT,
};

enum class CastType {
    EXACT,              // same type, no cast needed
    IMPLICIT_SPLAT,     // float → vecN (broadcast)
    IMPLICIT_TRUNCATE,  // vecN → vecM where M < N (lossy, warning)
    IMPLICIT_SEMANTIC,  // semantic → its base type (e.g. UV → vec2)
    INCOMPATIBLE,       // cannot connect
};

} // namespace sgs
