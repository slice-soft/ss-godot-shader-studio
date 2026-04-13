## Math and Float operator node definitions.
class_name MathNodes

static func register(r: NodeRegistry) -> void:
	_register_math(r)
	_register_math_extended(r)
	_register_float_ops(r)


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


# ---- Math ----

static func _register_math(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("math/add", "Add", "Math",
		["add","sum","plus","+"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {a} + {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/subtract", "Subtract", "Math",
		["subtract","sub","minus","-"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {a} - {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/multiply", "Multiply", "Math",
		["multiply","mul","times","*","product"],
		[_p("a","A",T.FLOAT,1.0), _p("b","B",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {a} * {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/divide", "Divide", "Math",
		["divide","div","/","quotient"],
		[_p("a","A",T.FLOAT,1.0), _p("b","B",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {a} / {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/power", "Power", "Math",
		["power","pow","exponent","^"],
		[_p("base","Base",T.FLOAT,1.0), _p("exp","Exp",T.FLOAT,2.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = pow({base}, {exp});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/sqrt", "Square Root", "Math",
		["sqrt","square root","root"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = sqrt({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/abs", "Absolute", "Math",
		["abs","absolute","magnitude"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = abs({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/negate", "Negate", "Math",
		["negate","negative","flip sign"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = -({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/floor", "Floor", "Math",
		["floor","round down"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = floor({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/ceil", "Ceil", "Math",
		["ceil","ceiling","round up"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = ceil({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/round", "Round", "Math",
		["round","nearest integer"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = round({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/fract", "Fract", "Math",
		["fract","fractional","decimal part"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = fract({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/mod", "Mod", "Math",
		["mod","modulo","remainder","%"],
		[_p("x","X",T.FLOAT,0.0), _p("y","Y",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = mod({x}, {y});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/min", "Min", "Math",
		["min","minimum","smaller"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = min({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/max", "Max", "Math",
		["max","maximum","larger"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = max({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/sign", "Sign", "Math",
		["sign","signum"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = sign({x});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Math Extended ----

static func _register_math_extended(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("math/exp", "Exp", "Math",
		["exp","exponential","e to the x"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = exp({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/exp2", "Exp2", "Math",
		["exp2","power of 2","2 to the x"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = exp2({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/log", "Log", "Math",
		["log","natural log","ln","logarithm"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = log({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/log2", "Log2", "Math",
		["log2","log base 2","binary log"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = log2({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/one_minus", "One Minus", "Math",
		["one minus","invert","complement","1-x"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = 1.0 - {x};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/rsqrt", "Reciprocal Sqrt", "Math",
		["rsqrt","reciprocal sqrt","inversesqrt","1/sqrt"],
		[_p("x","X",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = inversesqrt({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/trunc", "Truncate", "Math",
		["trunc","truncate","integer part","towards zero"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = trunc({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/scale_and_offset", "Scale And Offset", "Math",
		["scale and offset","mad","multiply add","linear transform"],
		[_p("x","X",T.FLOAT,0.0), _p("scale","Scale",T.FLOAT,1.0), _p("offset","Offset",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {x} * {scale} + {offset};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/ddx", "DDX", "Math",
		["ddx","dfdx","partial x derivative","screen derivative x"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = dFdx({x});", S.STAGE_FRAGMENT, S.DOMAIN_ALL))

	r.register_definition(_def("math/ddy", "DDY", "Math",
		["ddy","dfdy","partial y derivative","screen derivative y"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = dFdy({x});", S.STAGE_FRAGMENT, S.DOMAIN_ALL))

	r.register_definition(_def("math/fwidth", "FWidth", "Math",
		["fwidth","filter width","pixel width","derivative magnitude"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = fwidth({x});", S.STAGE_FRAGMENT, S.DOMAIN_ALL))

	r.register_definition(_def("math/lerp_unclamped", "Lerp Unclamped", "Math",
		["lerp unclamped","mix unclamped","extrapolate","unclamped blend"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,1.0), _p("t","T",T.FLOAT,0.5)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {a} + ({b} - {a}) * {t};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/ping_pong", "Ping Pong", "Math",
		["ping pong","bounce","triangle wave","back and forth"],
		[_p("x","X",T.FLOAT,0.0), _p("length","Length",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float _pp_t_{result} = mod({x}, {length} * 2.0);\nfloat {result} = {length} - abs(_pp_t_{result} - {length});",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/remap_clamp", "Remap Clamped", "Math",
		["remap clamped","safe remap","clamped map range"],
		[_p("x","X",T.FLOAT,0.0), _p("in_min","In Min",T.FLOAT,0.0), _p("in_max","In Max",T.FLOAT,1.0),
		 _p("out_min","Out Min",T.FLOAT,0.0), _p("out_max","Out Max",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {out_min} + clamp(({x} - {in_min}) / ({in_max} - {in_min}), 0.0, 1.0) * ({out_max} - {out_min});",
		S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Float Ops ----

static func _register_float_ops(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("float/lerp", "Lerp", "Float",
		["lerp","mix","linear interpolate","blend"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,1.0), _p("t","T",T.FLOAT,0.5)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = mix({a}, {b}, {t});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/clamp", "Clamp", "Float",
		["clamp","limit","saturate"],
		[_p("x","X",T.FLOAT,0.0), _p("min_val","Min",T.FLOAT,0.0), _p("max_val","Max",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = clamp({x}, {min_val}, {max_val});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/smoothstep", "Smoothstep", "Float",
		["smoothstep","smooth step","easing"],
		[_p("edge0","Edge0",T.FLOAT,0.0), _p("edge1","Edge1",T.FLOAT,1.0), _p("x","X",T.FLOAT,0.5)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = smoothstep({edge0}, {edge1}, {x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/step", "Step", "Float",
		["step","threshold","heaviside"],
		[_p("edge","Edge",T.FLOAT,0.5), _p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = step({edge}, {x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/saturate", "Saturate", "Float",
		["saturate","clamp01","clamp 0 1"],
		[_p("x","X",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = clamp({x}, 0.0, 1.0);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/remap", "Remap", "Float",
		["remap","remap range","map range"],
		[_p("x","X",T.FLOAT,0.0), _p("in_min","In Min",T.FLOAT,0.0), _p("in_max","In Max",T.FLOAT,1.0),
		 _p("out_min","Out Min",T.FLOAT,0.0), _p("out_max","Out Max",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = {out_min} + ({x} - {in_min}) / ({in_max} - {in_min}) * ({out_max} - {out_min});",
		S.STAGE_ANY, S.DOMAIN_ALL))
