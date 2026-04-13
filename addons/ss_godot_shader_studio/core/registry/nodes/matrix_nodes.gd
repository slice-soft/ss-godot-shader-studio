## Matrix transform and Constants node definitions.
class_name MatrixNodes

static func register(r: NodeRegistry) -> void:
	_register_matrix(r)
	_register_constants(r)


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


# ---- Matrix ----

static func _register_matrix(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("matrix/model", "Model Matrix", "Matrix",
		["model matrix","object to world","local to world","transform matrix"],
		[], [_p("mat","Matrix",T.MAT4)],
		"mat4 {mat} = MODEL_MATRIX;", S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("matrix/view", "View Matrix", "Matrix",
		["view matrix","world to view","camera matrix","camera space"],
		[], [_p("mat","Matrix",T.MAT4)],
		"mat4 {mat} = VIEW_MATRIX;", S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("matrix/projection", "Projection Matrix", "Matrix",
		["projection matrix","clip space","perspective matrix","camera projection"],
		[], [_p("mat","Matrix",T.MAT4)],
		"mat4 {mat} = PROJECTION_MATRIX;", S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("matrix/inv_view", "Inverse View Matrix", "Matrix",
		["inverse view matrix","view to world","world from view","inv view"],
		[], [_p("mat","Matrix",T.MAT4)],
		"mat4 {mat} = INV_VIEW_MATRIX;", S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("matrix/inv_projection", "Inverse Projection Matrix", "Matrix",
		["inverse projection matrix","unproject","inv projection"],
		[], [_p("mat","Matrix",T.MAT4)],
		"mat4 {mat} = INV_PROJECTION_MATRIX;", S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("matrix/model_normal", "Model Normal Matrix", "Matrix",
		["model normal matrix","normal matrix","inverse transpose model"],
		[], [_p("mat","Matrix",T.MAT3)],
		"mat3 {mat} = mat3(transpose(inverse(MODEL_MATRIX)));", S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("matrix/transpose", "Transpose", "Matrix",
		["transpose","matrix transpose","flip rows columns"],
		[_p("m","Matrix",T.MAT4)],
		[_p("result","Result",T.MAT4)],
		"mat4 {result} = transpose({m});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("matrix/inverse", "Inverse", "Matrix",
		["inverse","matrix inverse","invert matrix"],
		[_p("m","Matrix",T.MAT4)],
		[_p("result","Result",T.MAT4)],
		"mat4 {result} = inverse({m});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("matrix/determinant", "Determinant", "Matrix",
		["determinant","matrix determinant","det"],
		[_p("m","Matrix",T.MAT4)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = determinant({m});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("matrix/multiply", "Matrix Multiply", "Matrix",
		["matrix multiply","mat mul","matrix product","compose transform"],
		[_p("a","A",T.MAT4), _p("b","B",T.MAT4)],
		[_p("result","Result",T.MAT4)],
		"mat4 {result} = {a} * {b};", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Constants ----

static func _register_constants(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("const/pi", "Pi", "Constants",
		["pi","3.14","math pi","circle constant"],
		[], [_p("value","Value",T.FLOAT)],
		"float {value} = 3.14159265358979323846;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("const/tau", "Tau", "Constants",
		["tau","two pi","6.28","full circle constant"],
		[], [_p("value","Value",T.FLOAT)],
		"float {value} = 6.28318530717958647692;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("const/euler_e", "Euler's E", "Constants",
		["e","euler","2.718","euler number","natural base"],
		[], [_p("value","Value",T.FLOAT)],
		"float {value} = 2.71828182845904523536;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("const/golden_ratio", "Golden Ratio", "Constants",
		["golden ratio","phi","1.618","fibonacci ratio"],
		[], [_p("value","Value",T.FLOAT)],
		"float {value} = 1.61803398874989484820;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("const/sqrt2", "Sqrt 2", "Constants",
		["sqrt 2","square root of 2","diagonal","1.414"],
		[], [_p("value","Value",T.FLOAT)],
		"float {value} = 1.41421356237309504880;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("const/half_pi", "Half Pi", "Constants",
		["half pi","pi/2","quarter turn","90 degrees"],
		[], [_p("value","Value",T.FLOAT)],
		"float {value} = 1.57079632679489661923;", S.STAGE_ANY, S.DOMAIN_ALL))
