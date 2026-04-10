## Central enum and constant definitions for the shader graph system.
## Import via class_name — use SGSTypes.ShaderType.FLOAT etc.
class_name SGSTypes

enum ShaderType {
	VOID         = 0,
	BOOL         = 1,
	INT          = 2,
	UINT         = 3,
	FLOAT        = 4,
	VEC2         = 5,
	VEC3         = 6,
	VEC4         = 7,
	COLOR        = 8,   # alias for vec4, shown as colour picker
	MAT3         = 9,
	MAT4         = 10,
	SAMPLER2D    = 11,
	SAMPLER_CUBE = 12,
	UV           = 13,
	SCREEN_UV    = 14,
	NORMAL       = 15,
	WORLD_NORMAL = 16,
	POSITION     = 17,
	WORLD_POSITION  = 18,
	VIEW_DIRECTION  = 19,
	LIGHT_DIRECTION = 20,
	TIME         = 21,
	DEPTH        = 22,
}

enum CastType {
	EXACT             = 0,
	IMPLICIT_SPLAT    = 1,  # float → vecN (broadcast)
	IMPLICIT_TRUNCATE = 2,  # vecN → vecM where M < N (lossy)
	IMPLICIT_SEMANTIC = 3,  # semantic → its base type
	INCOMPATIBLE      = 4,
	IMPLICIT_VEC3_TO_COLOR = 5,  # vec3 RGB → COLOR (vec4 with alpha=1.0)
}

# Stage support bitfield flags
const STAGE_VERTEX   : int = 1
const STAGE_FRAGMENT : int = 2
const STAGE_LIGHT    : int = 4
const STAGE_ANY      : int = 7  # VERTEX | FRAGMENT | LIGHT

# Domain support bitfield flags
const DOMAIN_SPATIAL     : int = 1
const DOMAIN_CANVAS_ITEM : int = 2
const DOMAIN_PARTICLES   : int = 4
const DOMAIN_SKY         : int = 8
const DOMAIN_FOG         : int = 16
const DOMAIN_FULLSCREEN  : int = 32
const DOMAIN_ALL         : int = 63
