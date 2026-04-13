## Vector operator node definitions.
class_name VectorNodes

static func register(r: NodeRegistry) -> void:
	_register_vector(r)
	_register_vector_extended(r)
	_register_swizzle(r)


static func _def(id: String, name: String, cat: String,
		keywords: Array, inputs: Array, outputs: Array,
		template: String, stage: int, domain: int,
		helpers: Array[String] = [], auto_uni: Dictionary = {}) -> ShaderNodeDefinition:
	var d := ShaderNodeDefinition.new()
	d.id               = id
	d.display_name     = name
	d.category         = cat
	d.keywords         = keywords
	d.inputs           = inputs
	d.outputs          = outputs
	d.compiler_template = template
	d.stage_support    = stage
	d.domain_support   = domain
	d.helper_functions = helpers
	d.auto_uniform     = auto_uni
	return d


static func _p(id: String, name: String, type: int,
		default: Variant = null, optional: bool = false) -> Dictionary:
	return {"id": id, "name": name, "type": type, "default": default, "optional": optional}


# ---- Vector ----

static func _register_vector(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("vector/dot", "Dot Product", "Vector",
		["dot","dot product","inner product"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = dot({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/cross", "Cross Product", "Vector",
		["cross","cross product"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = cross({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/normalize", "Normalize", "Vector",
		["normalize","unit vector","direction"],
		[_p("v","V",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = normalize({v});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/length", "Length", "Vector",
		["length","magnitude","distance from zero"],
		[_p("v","V",T.VEC3)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = length({v});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/distance", "Distance", "Vector",
		["distance","dist","length between"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = distance({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/reflect", "Reflect", "Vector",
		["reflect","reflection"],
		[_p("incident","Incident",T.VEC3), _p("normal","Normal",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = reflect({incident}, {normal});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/refract", "Refract", "Vector",
		["refract","refraction","ior"],
		[_p("incident","Incident",T.VEC3), _p("normal","Normal",T.VEC3), _p("ior","IOR",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = refract({incident}, {normal}, {ior});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Vector Extended ----

static func _register_vector_extended(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("vector/face_forward", "Face Forward", "Vector",
		["faceforward","face forward","flip normal","orient normal"],
		[_p("n","N",T.VEC3), _p("incident","Incident",T.VEC3), _p("nref","NRef",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = faceforward({n}, {incident}, {nref});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/length_sq", "Length Squared", "Vector",
		["length squared","magnitude squared","dot self","sq length"],
		[_p("v","V",T.VEC3)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = dot({v}, {v});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/negate", "Negate Vector", "Vector",
		["negate vector","flip vector","negative vector","invert direction"],
		[_p("v","V",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = -({v});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/transform_direction", "Transform Direction", "Vector",
		["transform direction","matrix direction","rotate vector","mat4 vec3"],
		[_p("m","Matrix",T.MAT4), _p("v","Direction",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = ({m} * vec4({v}, 0.0)).xyz;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/transform_point", "Transform Point", "Vector",
		["transform point","matrix point","world point","mat4 position"],
		[_p("m","Matrix",T.MAT4), _p("v","Point",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = ({m} * vec4({v}, 1.0)).xyz;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/project", "Project", "Vector",
		["project","projection onto","vector projection"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = {b} * (dot({a}, {b}) / max(dot({b}, {b}), 1e-10));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/lerp", "Lerp Vector", "Vector",
		["lerp vector","mix vector","blend vector","interpolate direction"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("t","T",T.FLOAT,0.5)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, {b}, {t});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Swizzle ----

static func _register_swizzle(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("swizzle/split_vec4", "Split Vec4", "Swizzle",
		["split","swizzle","components","xyzw","rgba"],
		[_p("v","V",T.VEC4)],
		[_p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT), _p("w","W",T.FLOAT)],
		"float {x} = {v}.x;\nfloat {y} = {v}.y;\nfloat {z} = {v}.z;\nfloat {w} = {v}.w;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/split_vec3", "Split Vec3", "Swizzle",
		["split","swizzle","xyz","components"],
		[_p("v","V",T.VEC3)],
		[_p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT)],
		"float {x} = {v}.x;\nfloat {y} = {v}.y;\nfloat {z} = {v}.z;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/split_vec2", "Split Vec2", "Swizzle",
		["split","swizzle","xy","uv","components"],
		[_p("v","V",T.VEC2)],
		[_p("x","X",T.FLOAT), _p("y","Y",T.FLOAT)],
		"float {x} = {v}.x;\nfloat {y} = {v}.y;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/append_vec2", "Append Vec2", "Swizzle",
		["append","combine","make vec2","xy"],
		[_p("x","X",T.FLOAT,0.0), _p("y","Y",T.FLOAT,0.0)],
		[_p("result","Result",T.VEC2)],
		"vec2 {result} = vec2({x}, {y});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/append_vec3", "Append Vec3", "Swizzle",
		["append","combine","make vec3","xyz"],
		[_p("x","X",T.FLOAT,0.0), _p("y","Y",T.FLOAT,0.0), _p("z","Z",T.FLOAT,0.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = vec3({x}, {y}, {z});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/append_vec4", "Append Vec4", "Swizzle",
		["append","combine","make vec4","xyzw","rgba"],
		[_p("x","X",T.FLOAT,0.0), _p("y","Y",T.FLOAT,0.0), _p("z","Z",T.FLOAT,0.0), _p("w","W",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC4)],
		"vec4 {result} = vec4({x}, {y}, {z}, {w});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/vec3_append_w", "Vec3 + W", "Swizzle",
		["vec3 append w","vec3 to vec4","add w channel","promote vec3"],
		[_p("v","V",T.VEC3), _p("w","W",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC4)],
		"vec4 {result} = vec4({v}, {w});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/vec2_append_z", "Vec2 + Z", "Swizzle",
		["vec2 append z","vec2 to vec3","add z channel","promote vec2"],
		[_p("v","V",T.VEC2), _p("z","Z",T.FLOAT,0.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = vec3({v}, {z});", S.STAGE_ANY, S.DOMAIN_ALL))
