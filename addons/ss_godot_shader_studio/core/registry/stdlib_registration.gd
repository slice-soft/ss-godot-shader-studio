## Registers all built-in node definitions into a NodeRegistry.
class_name StdlibRegistration

# ---- GLSL helper functions (deduped by full string in IRBuilder) ----

const _H_HASH := \
"""float _sgs_hash(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}"""

const _H_VALUE_NOISE := \
"""float _sgs_value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float a = _sgs_hash(i);
	float b = _sgs_hash(i + vec2(1.0, 0.0));
	float c = _sgs_hash(i + vec2(0.0, 1.0));
	float d = _sgs_hash(i + vec2(1.0, 1.0));
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}"""

const _H_TRIPLANAR := \
"""vec4 _sgs_triplanar(sampler2D tex, vec3 pos, vec3 normal, float blend) {
	vec3 w = pow(abs(normal), vec3(blend));
	w /= (w.x + w.y + w.z) + 1e-6;
	vec4 cx = texture(tex, pos.yz);
	vec4 cy = texture(tex, pos.xz);
	vec4 cz = texture(tex, pos.xy);
	return cx * w.x + cy * w.y + cz * w.z;
}"""

const _H_DITHER := \
"""float _sgs_dither(vec2 screen_pos, float value) {
	float t = mod(dot(floor(screen_pos), vec2(127.1, 311.7)) * 43758.5453, 1.0);
	return step(t, value);
}"""


static func register_all(registry: NodeRegistry) -> void:
	_register_math(registry)
	_register_trig(registry)
	_register_vector(registry)
	_register_float_ops(registry)
	_register_swizzle(registry)
	_register_color(registry)
	_register_uv(registry)
	_register_texture(registry)
	_register_input(registry)
	_register_parameters(registry)
	_register_output(registry)
	_register_utility(registry)
	_register_effects(registry)
	_register_input_canvas_item(registry)
	_register_input_particles(registry)
	_register_input_sky(registry)
	_register_input_fog(registry)


# ---- Helpers ----

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


static func _port(id: String, name: String, type: int,
		default: Variant = null, optional: bool = false) -> Dictionary:
	return {"id": id, "name": name, "type": type, "default": default, "optional": optional}


# ---- Math ----

static func _register_math(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("math/add", "Add", "Math",
		["add","sum","plus","+"],
		[_port("a","A",T.FLOAT,0.0), _port("b","B",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = {a} + {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/subtract", "Subtract", "Math",
		["subtract","sub","minus","-"],
		[_port("a","A",T.FLOAT,0.0), _port("b","B",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = {a} - {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/multiply", "Multiply", "Math",
		["multiply","mul","times","*","product"],
		[_port("a","A",T.FLOAT,1.0), _port("b","B",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = {a} * {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/divide", "Divide", "Math",
		["divide","div","/","quotient"],
		[_port("a","A",T.FLOAT,1.0), _port("b","B",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = {a} / {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/power", "Power", "Math",
		["power","pow","exponent","^"],
		[_port("base","Base",T.FLOAT,1.0), _port("exp","Exp",T.FLOAT,2.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = pow({base}, {exp});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/sqrt", "Square Root", "Math",
		["sqrt","square root","root"],
		[_port("x","X",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = sqrt({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/abs", "Absolute", "Math",
		["abs","absolute","magnitude"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = abs({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/negate", "Negate", "Math",
		["negate","negative","flip sign"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = -({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/floor", "Floor", "Math",
		["floor","round down"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = floor({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/ceil", "Ceil", "Math",
		["ceil","ceiling","round up"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = ceil({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/round", "Round", "Math",
		["round","nearest integer"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = round({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/fract", "Fract", "Math",
		["fract","fractional","decimal part"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = fract({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/mod", "Mod", "Math",
		["mod","modulo","remainder","%"],
		[_port("x","X",T.FLOAT,0.0), _port("y","Y",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = mod({x}, {y});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/min", "Min", "Math",
		["min","minimum","smaller"],
		[_port("a","A",T.FLOAT,0.0), _port("b","B",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = min({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/max", "Max", "Math",
		["max","maximum","larger"],
		[_port("a","A",T.FLOAT,0.0), _port("b","B",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = max({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("math/sign", "Sign", "Math",
		["sign","signum"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = sign({x});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Trigonometry ----

static func _register_trig(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("trig/sin", "Sin", "Trigonometry",
		["sin","sine"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = sin({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/cos", "Cos", "Trigonometry",
		["cos","cosine"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = cos({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/tan", "Tan", "Trigonometry",
		["tan","tangent"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = tan({x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("trig/atan2", "Atan2", "Trigonometry",
		["atan2","atan","arctangent2"],
		[_port("y","Y",T.FLOAT,0.0), _port("x","X",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = atan({y}, {x});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Vector ----

static func _register_vector(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("vector/dot", "Dot Product", "Vector",
		["dot","dot product","inner product"],
		[_port("a","A",T.VEC3), _port("b","B",T.VEC3)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = dot({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/cross", "Cross Product", "Vector",
		["cross","cross product"],
		[_port("a","A",T.VEC3), _port("b","B",T.VEC3)],
		[_port("result","Result",T.VEC3)],
		"vec3 {result} = cross({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/normalize", "Normalize", "Vector",
		["normalize","unit vector","direction"],
		[_port("v","V",T.VEC3)],
		[_port("result","Result",T.VEC3)],
		"vec3 {result} = normalize({v});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/length", "Length", "Vector",
		["length","magnitude","distance from zero"],
		[_port("v","V",T.VEC3)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = length({v});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/distance", "Distance", "Vector",
		["distance","dist","length between"],
		[_port("a","A",T.VEC3), _port("b","B",T.VEC3)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = distance({a}, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/reflect", "Reflect", "Vector",
		["reflect","reflection"],
		[_port("incident","Incident",T.VEC3), _port("normal","Normal",T.VEC3)],
		[_port("result","Result",T.VEC3)],
		"vec3 {result} = reflect({incident}, {normal});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("vector/refract", "Refract", "Vector",
		["refract","refraction","ior"],
		[_port("incident","Incident",T.VEC3), _port("normal","Normal",T.VEC3), _port("ior","IOR",T.FLOAT,1.0)],
		[_port("result","Result",T.VEC3)],
		"vec3 {result} = refract({incident}, {normal}, {ior});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Float ops ----

static func _register_float_ops(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("float/lerp", "Lerp", "Float",
		["lerp","mix","linear interpolate","blend"],
		[_port("a","A",T.FLOAT,0.0), _port("b","B",T.FLOAT,1.0), _port("t","T",T.FLOAT,0.5)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = mix({a}, {b}, {t});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/clamp", "Clamp", "Float",
		["clamp","limit","saturate"],
		[_port("x","X",T.FLOAT,0.0), _port("min_val","Min",T.FLOAT,0.0), _port("max_val","Max",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = clamp({x}, {min_val}, {max_val});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/smoothstep", "Smoothstep", "Float",
		["smoothstep","smooth step","easing"],
		[_port("edge0","Edge0",T.FLOAT,0.0), _port("edge1","Edge1",T.FLOAT,1.0), _port("x","X",T.FLOAT,0.5)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = smoothstep({edge0}, {edge1}, {x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/step", "Step", "Float",
		["step","threshold","heaviside"],
		[_port("edge","Edge",T.FLOAT,0.5), _port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = step({edge}, {x});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/saturate", "Saturate", "Float",
		["saturate","clamp01","clamp 0 1"],
		[_port("x","X",T.FLOAT,0.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = clamp({x}, 0.0, 1.0);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("float/remap", "Remap", "Float",
		["remap","remap range","map range"],
		[_port("x","X",T.FLOAT,0.0), _port("in_min","In Min",T.FLOAT,0.0), _port("in_max","In Max",T.FLOAT,1.0),
		 _port("out_min","Out Min",T.FLOAT,0.0), _port("out_max","Out Max",T.FLOAT,1.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = {out_min} + ({x} - {in_min}) / ({in_max} - {in_min}) * ({out_max} - {out_min});",
		S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Swizzle ----

static func _register_swizzle(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("swizzle/split_vec4", "Split Vec4", "Swizzle",
		["split","swizzle","components","xyzw","rgba"],
		[_port("v","V",T.VEC4)],
		[_port("x","X",T.FLOAT), _port("y","Y",T.FLOAT), _port("z","Z",T.FLOAT), _port("w","W",T.FLOAT)],
		"float {x} = {v}.x;\nfloat {y} = {v}.y;\nfloat {z} = {v}.z;\nfloat {w} = {v}.w;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/split_vec3", "Split Vec3", "Swizzle",
		["split","swizzle","xyz","components"],
		[_port("v","V",T.VEC3)],
		[_port("x","X",T.FLOAT), _port("y","Y",T.FLOAT), _port("z","Z",T.FLOAT)],
		"float {x} = {v}.x;\nfloat {y} = {v}.y;\nfloat {z} = {v}.z;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/split_vec2", "Split Vec2", "Swizzle",
		["split","swizzle","xy","uv","components"],
		[_port("v","V",T.VEC2)],
		[_port("x","X",T.FLOAT), _port("y","Y",T.FLOAT)],
		"float {x} = {v}.x;\nfloat {y} = {v}.y;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/append_vec2", "Append Vec2", "Swizzle",
		["append","combine","make vec2","xy"],
		[_port("x","X",T.FLOAT,0.0), _port("y","Y",T.FLOAT,0.0)],
		[_port("result","Result",T.VEC2)],
		"vec2 {result} = vec2({x}, {y});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/append_vec3", "Append Vec3", "Swizzle",
		["append","combine","make vec3","xyz"],
		[_port("x","X",T.FLOAT,0.0), _port("y","Y",T.FLOAT,0.0), _port("z","Z",T.FLOAT,0.0)],
		[_port("result","Result",T.VEC3)],
		"vec3 {result} = vec3({x}, {y}, {z});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("swizzle/append_vec4", "Append Vec4", "Swizzle",
		["append","combine","make vec4","xyzw","rgba"],
		[_port("x","X",T.FLOAT,0.0), _port("y","Y",T.FLOAT,0.0), _port("z","Z",T.FLOAT,0.0), _port("w","W",T.FLOAT,1.0)],
		[_port("result","Result",T.VEC4)],
		"vec4 {result} = vec4({x}, {y}, {z}, {w});", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Color ----

static func _register_color(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("color/blend", "Blend", "Color",
		["blend","multiply color","color multiply"],
		[_port("a","A",T.COLOR), _port("b","B",T.COLOR)],
		[_port("result","Result",T.COLOR)],
		"vec4 {result} = {a} * {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/color_to_vec3", "Color to Vec3", "Color",
		["color to vec3","rgb","extract rgb"],
		[_port("color","Color",T.COLOR)],
		[_port("rgb","RGB",T.VEC3)],
		"vec3 {rgb} = {color}.rgb;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/vec3_to_color", "Vec3 to Color", "Color",
		["vec3 to color","make color","rgba from rgb"],
		[_port("rgb","RGB",T.VEC3), _port("a","Alpha",T.FLOAT,1.0)],
		[_port("color","Color",T.COLOR)],
		"vec4 {color} = vec4({rgb}, {a});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/hsv_to_rgb", "HSV to RGB", "Color",
		["hsv","hsv to rgb","hue saturation value"],
		[_port("hsv","HSV",T.VEC3)],
		[_port("rgb","RGB",T.VEC3)],
		"vec3 _hsv_c_{rgb} = vec3(abs({hsv}.x * 6.0 - 3.0) - 1.0, 2.0 - abs({hsv}.x * 6.0 - 2.0), 2.0 - abs({hsv}.x * 6.0 - 4.0));\nvec3 {rgb} = ((clamp(_hsv_c_{rgb}, 0.0, 1.0) - 1.0) * {hsv}.y + 1.0) * {hsv}.z;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/rgb_to_hsv", "RGB to HSV", "Color",
		["rgb to hsv","hue saturation value","colour space"],
		[_port("rgb","RGB",T.VEC3)],
		[_port("hsv","HSV",T.VEC3)],
		"vec4 _p_{hsv} = ({rgb}.g < {rgb}.b) ? vec4({rgb}.bg, -1.0, 2.0/3.0) : vec4({rgb}.gb, 0.0, -1.0/3.0);\nvec4 _q_{hsv} = ({rgb}.r < _p_{hsv}.x) ? vec4(_p_{hsv}.xyw, {rgb}.r) : vec4({rgb}.r, _p_{hsv}.yzx);\nfloat _d_{hsv} = _q_{hsv}.x - min(_q_{hsv}.w, _q_{hsv}.y);\nvec3 {hsv} = vec3(abs(_q_{hsv}.z + (_q_{hsv}.w - _q_{hsv}.y) / (6.0 * _d_{hsv} + 1e-10)), _d_{hsv} / (_q_{hsv}.x + 1e-10), _q_{hsv}.x);",
		S.STAGE_ANY, S.DOMAIN_ALL))


# ---- UV ----

static func _register_uv(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("uv/panner", "Panner", "UV",
		["panner","scroll","pan uv","animate uv"],
		[_port("uv","UV",T.UV), _port("speed","Speed",T.VEC2), _port("time","Time",T.TIME,0.0)],
		[_port("result","Result",T.UV)],
		"vec2 {result} = {uv} + {speed} * {time};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/rotator", "Rotator", "UV",
		["rotator","rotate uv","spin uv"],
		[_port("uv","UV",T.UV), _port("center","Center",T.VEC2), _port("angle","Angle",T.FLOAT,0.0)],
		[_port("result","Result",T.UV)],
		"float _cos_r_{result} = cos({angle});\nfloat _sin_r_{result} = sin({angle});\nvec2 _uv_c_{result} = {uv} - {center};\nvec2 {result} = vec2(_cos_r_{result} * _uv_c_{result}.x - _sin_r_{result} * _uv_c_{result}.y, _sin_r_{result} * _uv_c_{result}.x + _cos_r_{result} * _uv_c_{result}.y) + {center};",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/tiling_offset", "Tiling & Offset", "UV",
		["tiling","offset","uv tiling","uv offset","repeat"],
		[_port("uv","UV",T.UV), _port("tiling","Tiling",T.VEC2), _port("offset","Offset",T.VEC2)],
		[_port("result","Result",T.UV)],
		"vec2 {result} = {uv} * {tiling} + {offset};", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Texture ----

static func _register_texture(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("texture/sample_2d", "Sample Texture 2D", "Texture",
		["texture","sample","tex2d","sample2d","texture2d"],
		[_port("tex","Texture",T.SAMPLER2D), _port("uv","UV",T.UV)],
		[_port("rgba","RGBA",T.COLOR), _port("rgb","RGB",T.VEC3),
		 _port("r","R",T.FLOAT), _port("g","G",T.FLOAT), _port("b","B",T.FLOAT), _port("a","A",T.FLOAT)],
		"vec4 {rgba} = texture({tex}, {uv});\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_FRAGMENT, S.DOMAIN_ALL))

	r.register_definition(_def("texture/sample_cube", "Sample Texture Cube", "Texture",
		["cubemap","cube texture","skybox sample","environment sample"],
		[_port("tex","Texture",T.SAMPLER_CUBE), _port("dir","Direction",T.VEC3)],
		[_port("rgba","RGBA",T.COLOR), _port("rgb","RGB",T.VEC3)],
		"vec4 {rgba} = texture({tex}, {dir});\nvec3 {rgb} = {rgba}.rgb;",
		S.STAGE_FRAGMENT, S.DOMAIN_ALL))


# ---- Input ----

static func _register_input(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	r.register_definition(_def("input/time", "Time", "Input",
		["time","seconds","elapsed time","animation time"],
		[],
		[_port("time","Time",T.TIME)],
		"float {time} = TIME;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("input/screen_uv", "Screen UV", "Input",
		["screen uv","screen coordinates","viewport uv"],
		[],
		[_port("uv","UV",T.SCREEN_UV)],
		"vec2 {uv} = SCREEN_UV;", S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	r.register_definition(_def("input/vertex_normal", "Vertex Normal", "Input",
		["normal","vertex normal","surface normal","object normal"],
		[],
		[_port("normal","Normal",T.NORMAL)],
		"vec3 {normal} = NORMAL;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("input/world_position", "World Position", "Input",
		["world position","vertex position","model matrix","position"],
		[],
		[_port("pos","Position",T.WORLD_POSITION)],
		"vec3 {pos} = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;",
		S.STAGE_VERTEX, S.DOMAIN_SPATIAL))

	r.register_definition(_def("input/view_direction", "View Direction", "Input",
		["view direction","camera direction","view vector","eye direction"],
		[],
		[_port("dir","Direction",T.VIEW_DIRECTION)],
		"vec3 {dir} = VIEW;", S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("input/uv", "UV", "Input",
		["uv","texture coordinates","uv0"],
		[],
		[_port("uv","UV",T.UV)],
		"vec2 {uv} = UV;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/uv2", "UV2", "Input",
		["uv2","second uv","lightmap uv","uv channel 2"],
		[],
		[_port("uv2","UV2",T.UV)],
		"vec2 {uv2} = UV2;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM))

	r.register_definition(_def("input/vertex_color", "Vertex Color", "Input",
		["vertex color","color attribute","paint color"],
		[],
		[_port("color","Color",T.COLOR)],
		"vec4 {color} = COLOR;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM))

	r.register_definition(_def("input/frag_coord", "Fragment Coordinate", "Input",
		["fragcoord","fragment coordinate","pixel position","screen pixel"],
		[],
		[_port("pos","Position",T.VEC2)],
		"vec2 {pos} = FRAGCOORD.xy;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	var screen_auto_uni := {
		"name": "_sgs_screen_tex",
		"type": T.SAMPLER2D,
		"glsl_hint": " : hint_screen_texture, repeat_disable, filter_linear",
		"default_value": ""
	}
	r.register_definition(_def("input/screen_texture", "Screen Texture", "Input",
		["screen texture","screen grab","viewport texture","background"],
		[],
		[_port("rgba","RGBA",T.COLOR), _port("rgb","RGB",T.VEC3),
		 _port("r","R",T.FLOAT), _port("g","G",T.FLOAT), _port("b","B",T.FLOAT), _port("a","A",T.FLOAT)],
		"vec4 {rgba} = texture(_sgs_screen_tex, SCREEN_UV);\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN,
		[], screen_auto_uni))

	var depth_auto_uni := {
		"name": "_sgs_depth_tex",
		"type": T.SAMPLER2D,
		"glsl_hint": " : hint_depth_texture, repeat_disable, filter_nearest",
		"default_value": ""
	}
	r.register_definition(_def("input/depth_texture", "Depth Texture", "Input",
		["depth","depth texture","depth buffer","z-depth"],
		[],
		[_port("depth","Depth",T.FLOAT)],
		"float {depth} = texture(_sgs_depth_tex, SCREEN_UV).r;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL,
		[], depth_auto_uni))


# ---- Parameters ----

static func _register_parameters(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	# Parameter nodes are transparent to the IR: the output var_name IS the uniform
	# name, and the IR builder emits the uniform declaration separately. No code body
	# is emitted for these nodes — downstream nodes reference the uniform directly.
	r.register_definition(_def("parameter/float", "Float Parameter", "Parameters",
		["float parameter","uniform float","shader property float"],
		[],
		[_port("value","Value",T.FLOAT)],
		"",  # emitted as uniform; no body code
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/vec4", "Vec4 Parameter", "Parameters",
		["vec4 parameter","uniform vec4","shader property vec4"],
		[],
		[_port("value","Value",T.VEC4)],
		"",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/color", "Color Parameter", "Parameters",
		["color parameter","uniform color","shader property color","tint"],
		[],
		[_port("value","Value",T.COLOR)],
		"",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/texture2d", "Texture2D Parameter", "Parameters",
		["texture parameter","uniform sampler2d","shader texture property"],
		[],
		[_port("value","Value",T.SAMPLER2D)],
		"",
		S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Output ----

static func _register_output(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	# Spatial (PBR)
	var d := ShaderNodeDefinition.new()
	d.id           = "output/spatial"
	d.display_name = "Spatial Output"
	d.category     = "Output"
	d.keywords     = ["output","spatial output","material output","pbr output"]
	d.inputs       = [
		_port("albedo",     "Albedo",     T.VEC3,  null, true),
		_port("roughness",  "Roughness",  T.FLOAT, 0.5,  true),
		_port("metallic",   "Metallic",   T.FLOAT, 0.0,  true),
		_port("emission",   "Emission",   T.VEC3,  null, true),
		_port("normal_map", "Normal Map", T.VEC3,  null, true),
		_port("alpha",      "Alpha",      T.FLOAT, 1.0,  true),
		_port("ao",         "AO",         T.FLOAT, 1.0,  true),
	]
	d.outputs           = []
	d.compiler_template = "ALBEDO = {albedo};\nROUGHNESS = {roughness};\nMETALLIC = {metallic};\nEMISSION = {emission};\nNORMAL_MAP = {normal_map};\nALPHA = {alpha};\nAO = {ao};"
	d.stage_support     = S.STAGE_FRAGMENT
	d.domain_support    = S.DOMAIN_SPATIAL
	r.register_definition(d)

	# Vertex Offset (spatial vertex stage)
	r.register_definition(_def("output/vertex_offset", "Vertex Offset", "Output",
		["vertex offset","displace","vertex displacement","mesh deformation","wave"],
		[_port("offset","Offset",T.VEC3, null, true)],
		[],
		"VERTEX += {offset};",
		S.STAGE_VERTEX, S.DOMAIN_SPATIAL))

	# Canvas Item
	var ci := ShaderNodeDefinition.new()
	ci.id           = "output/canvas_item"
	ci.display_name = "Canvas Item Output"
	ci.category     = "Output"
	ci.keywords     = ["output","canvas item","2d output","sprite output","canvas output"]
	ci.inputs       = [
		_port("color",            "Color",        T.COLOR, null, true),
		_port("normal_map",       "Normal Map",   T.VEC3,  null, true),
		_port("normal_map_depth", "Normal Depth", T.FLOAT, 1.0,  true),
	]
	ci.outputs           = []
	ci.compiler_template = "COLOR = {color};\nNORMAL_MAP = {normal_map};\nNORMAL_MAP_DEPTH = {normal_map_depth};"
	ci.stage_support     = S.STAGE_FRAGMENT
	ci.domain_support    = S.DOMAIN_CANVAS_ITEM
	r.register_definition(ci)

	# Fullscreen / Postprocess (compiles to canvas_item)
	var fs := ShaderNodeDefinition.new()
	fs.id           = "output/fullscreen"
	fs.display_name = "Fullscreen Output"
	fs.category     = "Output"
	fs.keywords     = ["output","fullscreen","postprocess","post-process","screen effect","vfx"]
	fs.inputs       = [
		_port("color", "Color", T.COLOR, null, true),
	]
	fs.outputs           = []
	fs.compiler_template = "COLOR = {color};"
	fs.stage_support     = S.STAGE_FRAGMENT
	fs.domain_support    = S.DOMAIN_FULLSCREEN
	r.register_definition(fs)

	# Particles
	var pt := ShaderNodeDefinition.new()
	pt.id           = "output/particles"
	pt.display_name = "Particles Output"
	pt.category     = "Output"
	pt.keywords     = ["output","particles output","particle","gpu particles"]
	pt.inputs       = [
		_port("velocity",  "Velocity",  T.VEC3,  null, true),
		_port("color",     "Color",     T.COLOR, null, true),
		_port("custom",    "Custom",    T.COLOR, null, true),
		_port("active",    "Active",    T.FLOAT, 1.0,  true),
	]
	pt.outputs           = []
	pt.compiler_template = "VELOCITY = {velocity};\nCOLOR = {color};\nCUSTOM = {custom};\nACTIVE = bool({active} > 0.5);"
	pt.stage_support     = S.STAGE_FRAGMENT  # → process() function
	pt.domain_support    = S.DOMAIN_PARTICLES
	r.register_definition(pt)

	# Sky
	var sky := ShaderNodeDefinition.new()
	sky.id           = "output/sky"
	sky.display_name = "Sky Output"
	sky.category     = "Output"
	sky.keywords     = ["output","sky output","sky shader","background","atmosphere","procedural sky"]
	sky.inputs       = [
		_port("color", "Color", T.VEC3,  null, true),
		_port("alpha", "Alpha", T.FLOAT, 1.0,  true),
		_port("fog",   "Fog",   T.COLOR, null, true),
	]
	sky.outputs           = []
	sky.compiler_template = "COLOR = {color};\nALPHA = {alpha};\nFOG = {fog};"
	sky.stage_support     = S.STAGE_FRAGMENT  # → sky() function
	sky.domain_support    = S.DOMAIN_SKY
	r.register_definition(sky)

	# Fog
	var fog := ShaderNodeDefinition.new()
	fog.id           = "output/fog"
	fog.display_name = "Fog Output"
	fog.category     = "Output"
	fog.keywords     = ["output","fog output","volumetric fog","fog shader"]
	fog.inputs       = [
		_port("albedo",   "Albedo",   T.VEC3,  null, true),
		_port("density",  "Density",  T.FLOAT, 1.0,  true),
		_port("emission", "Emission", T.VEC3,  null, true),
	]
	fog.outputs           = []
	fog.compiler_template = "ALBEDO = {albedo};\nDENSITY = {density};\nEMISSION = {emission};"
	fog.stage_support     = S.STAGE_FRAGMENT  # → fog() function
	fog.domain_support    = S.DOMAIN_FOG
	r.register_definition(fog)


# ---- Utility ----

static func _register_utility(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes
	# Reroute is a visual pass-through node. The IR builder treats it as transparent:
	# the output var_name is directly wired to whatever feeds the input, emitting no code.
	# Port types are FLOAT as a placeholder; type checking is skipped for reroute edges.
	r.register_definition(_def("utility/reroute", "Reroute", "Utility",
		["reroute","relay","wire","route","dot"],
		[_port("in", "In", T.FLOAT)],
		[_port("out", "Out", T.FLOAT)],
		"",  # pass-through — no code emitted
		S.STAGE_ANY, S.DOMAIN_ALL))

	# Custom Function: user writes an inline GLSL expression in the 'body' property.
	# Use {a} {b} {c} {d} to reference inputs. The IR builder wraps it in
	# "float {result} = <body>;" — standard substitution handles the rest.
	r.register_definition(_def("utility/custom_function", "Custom Function", "Utility",
		["custom","function","glsl","inline","code","expression","formula"],
		[
			_port("a", "A", T.FLOAT, null, true),
			_port("b", "B", T.FLOAT, null, true),
			_port("c", "C", T.FLOAT, null, true),
			_port("d", "D", T.FLOAT, null, true),
		],
		[_port("result", "Result", T.FLOAT)],
		"",  # template built dynamically in IR builder from 'body' property
		S.STAGE_ANY, S.DOMAIN_ALL))

	# Subgraph nodes — used inside .gssubgraph files to define inputs/outputs.
	r.register_definition(_def("subgraph/input", "Subgraph Input", "Subgraph",
		["subgraph input","graph input","expose input"],
		[],
		[_port("value", "Value", T.FLOAT)],
		"",  # transparent — mapped to parent input in IR expansion
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("subgraph/output", "Subgraph Output", "Subgraph",
		["subgraph output","graph output","expose output"],
		[_port("value", "Value", T.FLOAT)],
		[],
		"",  # transparent — captured as parent output in IR expansion
		S.STAGE_ANY, S.DOMAIN_ALL))

	# Utility/subgraph — embedded subgraph node in the parent graph.
	# 4 optional float inputs (a,b,c,d) matching subgraph/input nodes by input_name.
	# 2 float outputs (out1, out2) matching subgraph/output nodes by output_name.
	r.register_definition(_def("utility/subgraph", "Subgraph", "Utility",
		["subgraph","function graph","reuse","embed"],
		[
			_port("a",   "A",   T.FLOAT, null, true),
			_port("b",   "B",   T.FLOAT, null, true),
			_port("c",   "C",   T.FLOAT, null, true),
			_port("d",   "D",   T.FLOAT, null, true),
		],
		[
			_port("out1", "Out1", T.FLOAT),
			_port("out2", "Out2", T.FLOAT),
		],
		"",  # expanded inline by IR builder
		S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Effects (advanced nodes) ----

static func _register_effects(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	# Fresnel — view-dependent rim effect
	r.register_definition(_def("effects/fresnel", "Fresnel", "Effects",
		["fresnel","rim","rim light","edge glow","schlick"],
		[_port("normal","Normal",T.VEC3), _port("view","View",T.VEC3), _port("power","Power",T.FLOAT,5.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = pow(1.0 - clamp(dot(normalize({view}), normalize({normal})), 0.0, 1.0), {power});",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	# Normal Blend — UDN blend two tangent-space normals
	r.register_definition(_def("effects/normal_blend", "Normal Blend", "Effects",
		["normal blend","blend normals","normal map blend","udn"],
		[_port("a","A",T.VEC3), _port("b","B",T.VEC3)],
		[_port("result","Result",T.VEC3)],
		"vec3 {result} = normalize(vec3({a}.xy + {b}.xy, {a}.z));",
		S.STAGE_ANY, S.DOMAIN_ALL))

	# Toon Ramp — posterize to N steps
	r.register_definition(_def("effects/toon_ramp", "Toon Ramp", "Effects",
		["toon","ramp","posterize","cel shade","steps","quantize"],
		[_port("value","Value",T.FLOAT,0.5), _port("steps","Steps",T.FLOAT,3.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = floor({value} * max({steps}, 1.0)) / max({steps}, 1.0);",
		S.STAGE_ANY, S.DOMAIN_ALL))

	# Value Noise — 2D smooth value noise with hash helpers
	r.register_definition(_def("effects/value_noise", "Value Noise", "Effects",
		["noise","value noise","procedural noise","random","hash"],
		[_port("uv","UV",T.UV), _port("scale","Scale",T.FLOAT,4.0)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = _sgs_value_noise({uv} * {scale});",
		S.STAGE_ANY, S.DOMAIN_ALL,
		[_H_HASH, _H_VALUE_NOISE]))

	# Triplanar — texture projection from 3 world-space axes
	r.register_definition(_def("effects/triplanar", "Triplanar", "Effects",
		["triplanar","world projection","no-stretch","terrain texture"],
		[_port("tex","Texture",T.SAMPLER2D),
		 _port("world_pos","World Pos",T.VEC3),
		 _port("normal","Normal",T.VEC3),
		 _port("blend","Blend",T.FLOAT,8.0)],
		[_port("rgba","RGBA",T.COLOR), _port("rgb","RGB",T.VEC3)],
		"vec4 {rgba} = _sgs_triplanar({tex}, {world_pos}, {normal}, {blend});\nvec3 {rgb} = {rgba}.rgb;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL,
		[_H_TRIPLANAR]))

	# Dither — ordered dithering (0 or 1 output)
	r.register_definition(_def("effects/dither", "Dither", "Effects",
		["dither","ordered dither","bayer","pixel art","alpha clip dither"],
		[_port("screen_pos","Screen Pos",T.VEC2), _port("value","Value",T.FLOAT,0.5)],
		[_port("result","Result",T.FLOAT)],
		"float {result} = _sgs_dither({screen_pos}, {value});",
		S.STAGE_FRAGMENT, S.DOMAIN_ALL,
		[_H_DITHER]))

	# Dissolve — noise-based cutout dissolve mask
	r.register_definition(_def("effects/dissolve", "Dissolve", "Effects",
		["dissolve","burn","cutout","noise dissolve","appear","disappear"],
		[_port("uv","UV",T.UV), _port("scale","Scale",T.FLOAT,4.0), _port("threshold","Threshold",T.FLOAT,0.5)],
		[_port("mask","Mask",T.FLOAT)],
		"float _sgs_dn_{mask} = _sgs_value_noise({uv} * {scale});\nfloat {mask} = step({threshold}, _sgs_dn_{mask});",
		S.STAGE_ANY, S.DOMAIN_ALL,
		[_H_HASH, _H_VALUE_NOISE]))


# ---- Canvas Item inputs ----

static func _register_input_canvas_item(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/canvas_texture", "Canvas Texture", "Input",
		["canvas texture","sprite texture","2d texture","texture()"],
		[],
		[_port("rgba","RGBA",T.COLOR), _port("rgb","RGB",T.VEC3),
		 _port("r","R",T.FLOAT), _port("g","G",T.FLOAT), _port("b","B",T.FLOAT), _port("a","A",T.FLOAT)],
		"vec4 {rgba} = texture(TEXTURE, UV);\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_FRAGMENT, S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	r.register_definition(_def("input/canvas_vertex", "Canvas Vertex", "Input",
		["canvas vertex","vertex position 2d","vertex 2d"],
		[],
		[_port("vertex","Vertex",T.VEC2)],
		"vec2 {vertex} = VERTEX;",
		S.STAGE_VERTEX, S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))


# ---- Particles inputs ----

static func _register_input_particles(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/particles_velocity", "Particles Velocity", "Input",
		["particles velocity","particle velocity","speed","direction"],
		[],
		[_port("velocity","Velocity",T.VEC3)],
		"vec3 {velocity} = VELOCITY;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_color", "Particles Color", "Input",
		["particles color","particle color","start color"],
		[],
		[_port("color","Color",T.COLOR)],
		"vec4 {color} = COLOR;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_index", "Particle Index", "Input",
		["particle index","particle id","particle number"],
		[],
		[_port("index","Index",T.FLOAT)],
		"float {index} = float(INDEX);",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_lifetime", "Particle Lifetime", "Input",
		["particle lifetime","life","age","ttl"],
		[],
		[_port("lifetime","Lifetime",T.FLOAT), _port("life","Life (0-1)",T.FLOAT)],
		"float {lifetime} = LIFETIME;\nfloat {life} = LIFETIME > 0.0 ? clamp(CUSTOM.y * LIFETIME, 0.0, 1.0) : 0.0;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_random", "Particle Random", "Input",
		["particle random","random","seed","stochastic"],
		[],
		[_port("rand","Random",T.FLOAT)],
		"float {rand} = CUSTOM.x;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))


# ---- Sky inputs ----

static func _register_input_sky(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/sky_eyedir", "Eye Direction", "Input",
		["eye direction","ray direction","sky direction","eyedir","view ray"],
		[],
		[_port("dir","Direction",T.VEC3)],
		"vec3 {dir} = EYEDIR;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_light_direction", "Sun Direction", "Input",
		["sun direction","light direction","sky light","directional light"],
		[],
		[_port("dir","Direction",T.VEC3)],
		"vec3 {dir} = LIGHT0_DIRECTION;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_light_color", "Sun Color", "Input",
		["sun color","light color","sky light color","directional color"],
		[],
		[_port("color","Color",T.VEC3)],
		"vec3 {color} = LIGHT0_COLOR;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_light_energy", "Sun Energy", "Input",
		["sun energy","light energy","sky light energy","intensity"],
		[],
		[_port("energy","Energy",T.FLOAT)],
		"float {energy} = LIGHT0_ENERGY;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_position", "Camera Position", "Input",
		["sky position","camera position","world position sky","observer"],
		[],
		[_port("pos","Position",T.VEC3)],
		"vec3 {pos} = POSITION;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))


# ---- Fog inputs ----

static func _register_input_fog(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/fog_world_position", "World Position (Fog)", "Input",
		["fog world position","voxel position","fog position"],
		[],
		[_port("pos","Position",T.VEC3)],
		"vec3 {pos} = WORLD_POSITION;",
		S.STAGE_FRAGMENT, S.DOMAIN_FOG))

	r.register_definition(_def("input/fog_view_direction", "View Direction (Fog)", "Input",
		["fog view direction","fog camera direction","fog view vector"],
		[],
		[_port("dir","Direction",T.VEC3)],
		"vec3 {dir} = VIEW_DIRECTION;",
		S.STAGE_FRAGMENT, S.DOMAIN_FOG))

	r.register_definition(_def("input/fog_sky_color", "Sky Color (Fog)", "Input",
		["fog sky color","background color","ambient fog color"],
		[],
		[_port("color","Color",T.COLOR)],
		"vec4 {color} = SKY_COLOR;",
		S.STAGE_FRAGMENT, S.DOMAIN_FOG))
