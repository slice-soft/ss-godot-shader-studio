#pragma once

namespace sgs {

enum class ShaderDomain {
    SPATIAL      = 0,
    CANVAS_ITEM  = 1,
    PARTICLES    = 2,
    SKY          = 3,
    FOG          = 4,
    FULLSCREEN   = 5,
};

// Domain bitfield flags (used in ShaderNodeDefinition::domain_support)
constexpr int DOMAIN_SPATIAL      = 1 << 0;
constexpr int DOMAIN_CANVAS_ITEM  = 1 << 1;
constexpr int DOMAIN_PARTICLES    = 1 << 2;
constexpr int DOMAIN_SKY          = 1 << 3;
constexpr int DOMAIN_FOG          = 1 << 4;
constexpr int DOMAIN_FULLSCREEN   = 1 << 5;
constexpr int DOMAIN_ALL          = 0x3F;

// Stage bitfield flags (used in ShaderNodeDefinition::stage_support)
constexpr int STAGE_VERTEX   = 1 << 0;
constexpr int STAGE_FRAGMENT = 1 << 1;
constexpr int STAGE_LIGHT    = 1 << 2;
constexpr int STAGE_ANY      = STAGE_VERTEX | STAGE_FRAGMENT | STAGE_LIGHT;

} // namespace sgs
