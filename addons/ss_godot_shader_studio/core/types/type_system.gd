## Static type utilities: compatibility checks, GLSL names, component counts.
class_name TypeSystem


static func get_base_type(t: int) -> int:
	match t:
		SGSTypes.ShaderType.UV, SGSTypes.ShaderType.SCREEN_UV:
			return SGSTypes.ShaderType.VEC2
		SGSTypes.ShaderType.NORMAL, SGSTypes.ShaderType.WORLD_NORMAL, \
		SGSTypes.ShaderType.POSITION, SGSTypes.ShaderType.WORLD_POSITION, \
		SGSTypes.ShaderType.VIEW_DIRECTION, SGSTypes.ShaderType.LIGHT_DIRECTION:
			return SGSTypes.ShaderType.VEC3
		SGSTypes.ShaderType.COLOR:
			return SGSTypes.ShaderType.VEC4
		SGSTypes.ShaderType.TIME, SGSTypes.ShaderType.DEPTH:
			return SGSTypes.ShaderType.FLOAT
		_:
			return t


static func get_component_count(t: int) -> int:
	var base := get_base_type(t)
	match base:
		SGSTypes.ShaderType.BOOL, SGSTypes.ShaderType.INT, \
		SGSTypes.ShaderType.UINT, SGSTypes.ShaderType.FLOAT:
			return 1
		SGSTypes.ShaderType.VEC2:
			return 2
		SGSTypes.ShaderType.VEC3:
			return 3
		SGSTypes.ShaderType.VEC4:
			return 4
		SGSTypes.ShaderType.MAT3:
			return 9
		SGSTypes.ShaderType.MAT4:
			return 16
		_:
			return 0


static func type_to_glsl(t: int) -> String:
	var base := get_base_type(t)
	match base:
		SGSTypes.ShaderType.VOID:         return "void"
		SGSTypes.ShaderType.BOOL:         return "bool"
		SGSTypes.ShaderType.INT:          return "int"
		SGSTypes.ShaderType.UINT:         return "uint"
		SGSTypes.ShaderType.FLOAT:        return "float"
		SGSTypes.ShaderType.VEC2:         return "vec2"
		SGSTypes.ShaderType.VEC3:         return "vec3"
		SGSTypes.ShaderType.VEC4:         return "vec4"
		SGSTypes.ShaderType.MAT3:         return "mat3"
		SGSTypes.ShaderType.MAT4:         return "mat4"
		SGSTypes.ShaderType.SAMPLER2D:    return "sampler2D"
		SGSTypes.ShaderType.SAMPLER_CUBE: return "samplerCube"
		_:                                return ""


static func type_to_display_name(t: int) -> String:
	match t:
		SGSTypes.ShaderType.VOID:            return "Void"
		SGSTypes.ShaderType.BOOL:            return "Bool"
		SGSTypes.ShaderType.INT:             return "Int"
		SGSTypes.ShaderType.UINT:            return "UInt"
		SGSTypes.ShaderType.FLOAT:           return "Float"
		SGSTypes.ShaderType.VEC2:            return "Vec2"
		SGSTypes.ShaderType.VEC3:            return "Vec3"
		SGSTypes.ShaderType.VEC4:            return "Vec4"
		SGSTypes.ShaderType.COLOR:           return "Color"
		SGSTypes.ShaderType.MAT3:            return "Mat3"
		SGSTypes.ShaderType.MAT4:            return "Mat4"
		SGSTypes.ShaderType.SAMPLER2D:       return "Texture2D"
		SGSTypes.ShaderType.SAMPLER_CUBE:    return "TextureCube"
		SGSTypes.ShaderType.UV:              return "UV"
		SGSTypes.ShaderType.SCREEN_UV:       return "ScreenUV"
		SGSTypes.ShaderType.NORMAL:          return "Normal"
		SGSTypes.ShaderType.WORLD_NORMAL:    return "WorldNormal"
		SGSTypes.ShaderType.POSITION:        return "Position"
		SGSTypes.ShaderType.WORLD_POSITION:  return "WorldPosition"
		SGSTypes.ShaderType.VIEW_DIRECTION:  return "ViewDirection"
		SGSTypes.ShaderType.LIGHT_DIRECTION: return "LightDirection"
		SGSTypes.ShaderType.TIME:            return "Time"
		SGSTypes.ShaderType.DEPTH:           return "Depth"
		_:                                   return "Unknown"


static func get_cast_type(from: int, to: int) -> int:
	if from == to:
		return SGSTypes.CastType.EXACT

	var from_base := get_base_type(from)
	var to_base   := get_base_type(to)

	# Semantic → its own base type
	if from != from_base and from_base == to:
		return SGSTypes.CastType.IMPLICIT_SEMANTIC
	# Two semantics with the same base
	if from_base == to_base and from_base != from and to_base != to:
		return SGSTypes.CastType.IMPLICIT_SEMANTIC

	var f := from_base
	var t2 := to_base

	if f == t2:
		return SGSTypes.CastType.IMPLICIT_SEMANTIC

	# float → vecN splat
	if f == SGSTypes.ShaderType.FLOAT:
		if t2 in [SGSTypes.ShaderType.VEC2, SGSTypes.ShaderType.VEC3, SGSTypes.ShaderType.VEC4]:
			return SGSTypes.CastType.IMPLICIT_SPLAT

	# vecN → vecM truncation (N > M)
	var fc := get_component_count(f)
	var tc := get_component_count(t2)
	if fc > 1 and tc > 1 and fc > tc:
		return SGSTypes.CastType.IMPLICIT_TRUNCATE

	return SGSTypes.CastType.INCOMPATIBLE


static func are_compatible(from: int, to: int) -> bool:
	return get_cast_type(from, to) != SGSTypes.CastType.INCOMPATIBLE
