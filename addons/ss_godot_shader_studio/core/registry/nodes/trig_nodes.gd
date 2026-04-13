## Trigonometry node definitions.
class_name TrigNodes

static func register(r: NodeRegistry) -> void:
	_register_trig(r)
	_register_trig_extended(r)


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


# ---- Trigonometry ----

static func _register_trig(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("trig/sin", "Sin", "Trigonometry",
		["sin","sine"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = sin({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/cos", "Cos", "Trigonometry",
		["cos","cosine"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = cos({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/tan", "Tan", "Trigonometry",
		["tan","tangent"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = tan({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/atan2", "Atan2", "Trigonometry",
		["atan2","atan","arctangent2"],
		[_p("y","Y",T.FLOAT,0.0), _p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = atan({y}, {x});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Trigonometry Extended ----

static func _register_trig_extended(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("trig/asin", "Arc Sin", "Trigonometry",
		["asin","arcsin","inverse sin","arcsine"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = asin(clamp({x}, -1.0, 1.0));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/acos", "Arc Cos", "Trigonometry",
		["acos","arccos","inverse cos","arccosine"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = acos(clamp({x}, -1.0, 1.0));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/atan", "Arc Tan", "Trigonometry",
		["atan","arctan","inverse tangent","arctangent"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = atan({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/sinh", "Sinh", "Trigonometry",
		["sinh","hyperbolic sine"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = sinh({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/cosh", "Cosh", "Trigonometry",
		["cosh","hyperbolic cosine"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = cosh({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/tanh", "Tanh", "Trigonometry",
		["tanh","hyperbolic tangent"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = tanh({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/deg2rad", "Degrees to Radians", "Trigonometry",
		["deg2rad","degrees to radians","to radians","convert degrees"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = radians({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/rad2deg", "Radians to Degrees", "Trigonometry",
		["rad2deg","radians to degrees","to degrees","convert radians"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = degrees({x});", S.STAGE_ANY, S.DOMAIN_ALL))
