## Unit tests for TypeSystem — type compatibility, casts, GLSL names.
extends TestCase


var T: Dictionary  # shorthand for SGSTypes.ShaderType values
var C: Dictionary  # shorthand for SGSTypes.CastType values


func before_all() -> void:
	# Build name→value maps for readable assertions.
	T = {}
	for key in SGSTypes.ShaderType.keys():
		T[key] = SGSTypes.ShaderType[key]
	C = {}
	for key in SGSTypes.CastType.keys():
		C[key] = SGSTypes.CastType[key]


# ---- get_base_type ----

func test_base_type_uv_is_vec2() -> void:
	assert_eq(TypeSystem.get_base_type(T.UV), T.VEC2)


func test_base_type_screen_uv_is_vec2() -> void:
	assert_eq(TypeSystem.get_base_type(T.SCREEN_UV), T.VEC2)


func test_base_type_normal_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.NORMAL), T.VEC3)


func test_base_type_world_normal_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.WORLD_NORMAL), T.VEC3)


func test_base_type_position_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.POSITION), T.VEC3)


func test_base_type_world_position_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.WORLD_POSITION), T.VEC3)


func test_base_type_view_direction_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.VIEW_DIRECTION), T.VEC3)


func test_base_type_light_direction_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.LIGHT_DIRECTION), T.VEC3)


func test_base_type_color_is_vec4() -> void:
	assert_eq(TypeSystem.get_base_type(T.COLOR), T.VEC4)


func test_base_type_time_is_float() -> void:
	assert_eq(TypeSystem.get_base_type(T.TIME), T.FLOAT)


func test_base_type_depth_is_float() -> void:
	assert_eq(TypeSystem.get_base_type(T.DEPTH), T.FLOAT)


func test_base_type_float_is_float() -> void:
	assert_eq(TypeSystem.get_base_type(T.FLOAT), T.FLOAT)


func test_base_type_vec3_is_vec3() -> void:
	assert_eq(TypeSystem.get_base_type(T.VEC3), T.VEC3)


# ---- get_component_count ----

func test_component_count_float() -> void:
	assert_eq(TypeSystem.get_component_count(T.FLOAT), 1)


func test_component_count_int() -> void:
	assert_eq(TypeSystem.get_component_count(T.INT), 1)


func test_component_count_bool() -> void:
	assert_eq(TypeSystem.get_component_count(T.BOOL), 1)


func test_component_count_vec2() -> void:
	assert_eq(TypeSystem.get_component_count(T.VEC2), 2)


func test_component_count_vec3() -> void:
	assert_eq(TypeSystem.get_component_count(T.VEC3), 3)


func test_component_count_vec4() -> void:
	assert_eq(TypeSystem.get_component_count(T.VEC4), 4)


func test_component_count_mat3() -> void:
	assert_eq(TypeSystem.get_component_count(T.MAT3), 9)


func test_component_count_mat4() -> void:
	assert_eq(TypeSystem.get_component_count(T.MAT4), 16)


func test_component_count_uv_delegates_to_vec2() -> void:
	assert_eq(TypeSystem.get_component_count(T.UV), 2)


func test_component_count_color_delegates_to_vec4() -> void:
	assert_eq(TypeSystem.get_component_count(T.COLOR), 4)


# ---- type_to_glsl ----

func test_glsl_void() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.VOID), "void")


func test_glsl_bool() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.BOOL), "bool")


func test_glsl_int() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.INT), "int")


func test_glsl_uint() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.UINT), "uint")


func test_glsl_float() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.FLOAT), "float")


func test_glsl_vec2() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.VEC2), "vec2")


func test_glsl_vec3() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.VEC3), "vec3")


func test_glsl_vec4() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.VEC4), "vec4")


func test_glsl_mat3() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.MAT3), "mat3")


func test_glsl_mat4() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.MAT4), "mat4")


func test_glsl_sampler2d() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.SAMPLER2D), "sampler2D")


func test_glsl_sampler_cube() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.SAMPLER_CUBE), "samplerCube")


func test_glsl_uv_resolves_to_vec2() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.UV), "vec2")


func test_glsl_color_resolves_to_vec4() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.COLOR), "vec4")


func test_glsl_normal_resolves_to_vec3() -> void:
	assert_eq(TypeSystem.type_to_glsl(T.NORMAL), "vec3")


# ---- get_cast_type — EXACT ----

func test_cast_float_to_float_exact() -> void:
	assert_eq(TypeSystem.get_cast_type(T.FLOAT, T.FLOAT), C.EXACT)


func test_cast_vec3_to_vec3_exact() -> void:
	assert_eq(TypeSystem.get_cast_type(T.VEC3, T.VEC3), C.EXACT)


func test_cast_same_type_always_exact() -> void:
	for type_val in SGSTypes.ShaderType.values():
		assert_eq(TypeSystem.get_cast_type(type_val, type_val), C.EXACT,
				"same-type cast should be EXACT for type %d" % type_val)


# ---- get_cast_type — IMPLICIT_SEMANTIC ----

func test_cast_uv_to_vec2_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.UV, T.VEC2), C.IMPLICIT_SEMANTIC)


func test_cast_screen_uv_to_vec2_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.SCREEN_UV, T.VEC2), C.IMPLICIT_SEMANTIC)


func test_cast_normal_to_vec3_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.NORMAL, T.VEC3), C.IMPLICIT_SEMANTIC)


func test_cast_world_normal_to_vec3_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.WORLD_NORMAL, T.VEC3), C.IMPLICIT_SEMANTIC)


func test_cast_color_to_vec4_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.COLOR, T.VEC4), C.IMPLICIT_SEMANTIC)


func test_cast_time_to_float_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.TIME, T.FLOAT), C.IMPLICIT_SEMANTIC)


func test_cast_uv_to_screen_uv_is_semantic() -> void:
	# Both have base VEC2 and neither is VEC2 itself
	assert_eq(TypeSystem.get_cast_type(T.UV, T.SCREEN_UV), C.IMPLICIT_SEMANTIC)


func test_cast_normal_to_world_normal_is_semantic() -> void:
	assert_eq(TypeSystem.get_cast_type(T.NORMAL, T.WORLD_NORMAL), C.IMPLICIT_SEMANTIC)


# ---- get_cast_type — IMPLICIT_SPLAT ----

func test_cast_float_to_vec2_is_splat() -> void:
	assert_eq(TypeSystem.get_cast_type(T.FLOAT, T.VEC2), C.IMPLICIT_SPLAT)


func test_cast_float_to_vec3_is_splat() -> void:
	assert_eq(TypeSystem.get_cast_type(T.FLOAT, T.VEC3), C.IMPLICIT_SPLAT)


func test_cast_float_to_vec4_is_splat() -> void:
	assert_eq(TypeSystem.get_cast_type(T.FLOAT, T.VEC4), C.IMPLICIT_SPLAT)


# ---- get_cast_type — IMPLICIT_TRUNCATE ----

func test_cast_vec4_to_vec3_is_truncate() -> void:
	assert_eq(TypeSystem.get_cast_type(T.VEC4, T.VEC3), C.IMPLICIT_TRUNCATE)


func test_cast_vec4_to_vec2_is_truncate() -> void:
	assert_eq(TypeSystem.get_cast_type(T.VEC4, T.VEC2), C.IMPLICIT_TRUNCATE)


func test_cast_vec3_to_vec2_is_truncate() -> void:
	assert_eq(TypeSystem.get_cast_type(T.VEC3, T.VEC2), C.IMPLICIT_TRUNCATE)


# ---- get_cast_type — INCOMPATIBLE ----

func test_cast_vec3_to_float_incompatible() -> void:
	assert_eq(TypeSystem.get_cast_type(T.VEC3, T.FLOAT), C.INCOMPATIBLE)


func test_cast_vec2_to_vec3_incompatible() -> void:
	assert_eq(TypeSystem.get_cast_type(T.VEC2, T.VEC3), C.INCOMPATIBLE)


func test_cast_float_to_int_incompatible() -> void:
	assert_eq(TypeSystem.get_cast_type(T.FLOAT, T.INT), C.INCOMPATIBLE)


func test_cast_sampler2d_to_float_incompatible() -> void:
	assert_eq(TypeSystem.get_cast_type(T.SAMPLER2D, T.FLOAT), C.INCOMPATIBLE)


# ---- are_compatible ----

func test_compatible_exact() -> void:
	assert_true(TypeSystem.are_compatible(T.FLOAT, T.FLOAT))


func test_compatible_splat() -> void:
	assert_true(TypeSystem.are_compatible(T.FLOAT, T.VEC3))


func test_compatible_truncate() -> void:
	assert_true(TypeSystem.are_compatible(T.VEC4, T.VEC2))


func test_compatible_semantic() -> void:
	assert_true(TypeSystem.are_compatible(T.UV, T.VEC2))


func test_incompatible_vec3_to_float() -> void:
	assert_false(TypeSystem.are_compatible(T.VEC3, T.FLOAT))


func test_incompatible_vec2_to_vec3() -> void:
	assert_false(TypeSystem.are_compatible(T.VEC2, T.VEC3))
