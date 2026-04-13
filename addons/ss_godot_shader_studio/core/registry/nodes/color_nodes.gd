## Color and Image Effects node definitions.
class_name ColorNodes

const _H_DESATURATE := \
"""vec3 _sgs_desaturate(vec3 color, float amount) {
	float grey = dot(color, vec3(0.2126, 0.7152, 0.0722));
	return mix(color, vec3(grey), amount);
}"""

const _H_POSTERIZE := \
"""vec3 _sgs_posterize(vec3 color, float steps) {
	return floor(color * steps) / steps;
}"""

const _H_HUE_SHIFT := \
"""vec3 _sgs_hue_shift(vec3 color, float shift) {
	vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
	vec4 p = mix(vec4(color.bg, K.wz), vec4(color.gb, K.xy), step(color.b, color.g));
	vec4 q = mix(vec4(p.xyw, color.r), vec4(color.r, p.yzx), step(p.x, color.r));
	float d = q.x - min(q.w, q.y);
	vec3 hsv = vec3(abs(q.z + (q.w - q.y) / (6.0 * d + 1e-10)), d / (q.x + 1e-10), q.x);
	hsv.x = fract(hsv.x + shift);
	vec4 K2 = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
	vec3 p2 = abs(fract(vec3(hsv.x) + K2.xyz) * 6.0 - K2.www);
	return hsv.z * mix(K2.xxx, clamp(p2 - K2.xxx, 0.0, 1.0), hsv.y);
}"""

const _H_BLEND_SCREEN := \
"""vec3 _sgs_blend_screen(vec3 a, vec3 b) {
	return 1.0 - (1.0 - a) * (1.0 - b);
}"""

const _H_BLEND_OVERLAY := \
"""vec3 _sgs_blend_overlay(vec3 a, vec3 b) {
	return mix(2.0 * a * b, 1.0 - 2.0 * (1.0 - a) * (1.0 - b), step(vec3(0.5), a));
}"""

const _H_BLEND_SOFTLIGHT := \
"""vec3 _sgs_blend_softlight(vec3 a, vec3 b) {
	return mix(2.0*a*b + a*a*(1.0-2.0*b), sqrt(max(a, vec3(0.0)))*(2.0*b-1.0)+2.0*a*(1.0-b), step(vec3(0.5), b));
}"""


static func register(r: NodeRegistry) -> void:
	_register_color(r)
	_register_image_effects(r)


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


# ---- Color ----

static func _register_color(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("color/blend", "Blend", "Color",
		["blend","multiply color","color multiply"],
		[_p("a","A",T.COLOR), _p("b","B",T.COLOR)],
		[_p("result","Result",T.COLOR)],
		"vec4 {result} = {a} * {b};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/color_to_vec3", "Color to Vec3", "Color",
		["color to vec3","rgb","extract rgb"],
		[_p("color","Color",T.COLOR)],
		[_p("rgb","RGB",T.VEC3)],
		"vec3 {rgb} = {color}.rgb;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/vec3_to_color", "Vec3 to Color", "Color",
		["vec3 to color","make color","rgba from rgb"],
		[_p("rgb","RGB",T.VEC3), _p("a","Alpha",T.FLOAT,1.0)],
		[_p("color","Color",T.COLOR)],
		"vec4 {color} = vec4({rgb}, {a});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/hsv_to_rgb", "HSV to RGB", "Color",
		["hsv","hsv to rgb","hue saturation value"],
		[_p("hsv","HSV",T.VEC3)],
		[_p("rgb","RGB",T.VEC3)],
		"vec3 _hsv_c_{rgb} = vec3(abs({hsv}.x * 6.0 - 3.0) - 1.0, 2.0 - abs({hsv}.x * 6.0 - 2.0), 2.0 - abs({hsv}.x * 6.0 - 4.0));\nvec3 {rgb} = ((clamp(_hsv_c_{rgb}, 0.0, 1.0) - 1.0) * {hsv}.y + 1.0) * {hsv}.z;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("color/rgb_to_hsv", "RGB to HSV", "Color",
		["rgb to hsv","hue saturation value","colour space"],
		[_p("rgb","RGB",T.VEC3)],
		[_p("hsv","HSV",T.VEC3)],
		"vec4 _p_{hsv} = ({rgb}.g < {rgb}.b) ? vec4({rgb}.bg, -1.0, 2.0/3.0) : vec4({rgb}.gb, 0.0, -1.0/3.0);\nvec4 _q_{hsv} = ({rgb}.r < _p_{hsv}.x) ? vec4(_p_{hsv}.xyw, {rgb}.r) : vec4({rgb}.r, _p_{hsv}.yzx);\nfloat _d_{hsv} = _q_{hsv}.x - min(_q_{hsv}.w, _q_{hsv}.y);\nvec3 {hsv} = vec3(abs(_q_{hsv}.z + (_q_{hsv}.w - _q_{hsv}.y) / (6.0 * _d_{hsv} + 1e-10)), _d_{hsv} / (_q_{hsv}.x + 1e-10), _q_{hsv}.x);",
		S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Image Effects ----

static func _register_image_effects(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("image/blend_multiply", "Blend Multiply", "Image Effects",
		["blend multiply","multiply blend","darken","photoshop multiply"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, {a} * {b}, {opacity});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/blend_add", "Blend Add", "Image Effects",
		["blend add","additive blend","linear dodge"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, clamp({a} + {b}, 0.0, 1.0), {opacity});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/blend_screen", "Blend Screen", "Image Effects",
		["blend screen","screen blend","lighten","photoshop screen"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, _sgs_blend_screen({a}, {b}), {opacity});",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_BLEND_SCREEN]))

	r.register_definition(_def("image/blend_overlay", "Blend Overlay", "Image Effects",
		["blend overlay","overlay blend","contrast blend","photoshop overlay"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, _sgs_blend_overlay({a}, {b}), {opacity});",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_BLEND_OVERLAY]))

	r.register_definition(_def("image/blend_softlight", "Blend Soft Light", "Image Effects",
		["blend soft light","soft light","photoshop soft light"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, _sgs_blend_softlight({a}, {b}), {opacity});",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_BLEND_SOFTLIGHT]))

	r.register_definition(_def("image/blend_hardlight", "Blend Hard Light", "Image Effects",
		["blend hard light","hard light","photoshop hard light"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, _sgs_blend_overlay({b}, {a}), {opacity});",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_BLEND_OVERLAY]))

	r.register_definition(_def("image/blend_subtract", "Blend Subtract", "Image Effects",
		["blend subtract","subtract blend"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, clamp({a} - {b}, 0.0, 1.0), {opacity});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/blend_difference", "Blend Difference", "Image Effects",
		["blend difference","difference blend","absolute difference"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3), _p("opacity","Opacity",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = mix({a}, abs({a} - {b}), {opacity});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/desaturate", "Desaturate", "Image Effects",
		["desaturate","reduce saturation","drain color","grey out"],
		[_p("color","Color",T.VEC3), _p("amount","Amount",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = _sgs_desaturate({color}, clamp({amount}, 0.0, 1.0));",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_DESATURATE]))

	r.register_definition(_def("image/grayscale", "Grayscale", "Image Effects",
		["grayscale","greyscale","luma","luminance"],
		[_p("color","Color",T.VEC3)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = dot({color}, vec3(0.299, 0.587, 0.114));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/gamma_to_linear", "Gamma To Linear", "Image Effects",
		["gamma to linear","srgb to linear","gamma decode","linearize color"],
		[_p("color","Color",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = pow(max({color}, vec3(0.0)), vec3(2.2));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/linear_to_gamma", "Linear To Gamma", "Image Effects",
		["linear to gamma","linear to srgb","gamma encode"],
		[_p("color","Color",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = pow(max({color}, vec3(0.0)), vec3(1.0 / 2.2));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/posterize", "Posterize", "Image Effects",
		["posterize","quantize color","reduce steps","cel shade steps"],
		[_p("color","Color",T.VEC3), _p("steps","Steps",T.FLOAT,4.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = _sgs_posterize({color}, max({steps}, 1.0));",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_POSTERIZE]))

	r.register_definition(_def("image/simple_contrast", "Simple Contrast", "Image Effects",
		["contrast","simple contrast","brightness contrast"],
		[_p("color","Color",T.VEC3), _p("contrast","Contrast",T.FLOAT,1.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = ({color} - 0.5) * max({contrast}, 0.0) + 0.5;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/hue_shift", "Hue Shift", "Image Effects",
		["hue shift","rotate hue","hue rotation"],
		[_p("color","Color",T.VEC3), _p("shift","Shift",T.FLOAT,0.0)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = _sgs_hue_shift({color}, {shift});",
		S.STAGE_ANY, S.DOMAIN_ALL, [_H_HUE_SHIFT]))

	r.register_definition(_def("image/channel_mixer", "Channel Mixer", "Image Effects",
		["channel mixer","swizzle color","reorder channels","rgb mix"],
		[_p("color","Color",T.VEC3),
		 _p("r_weights","R Weights",T.VEC3), _p("g_weights","G Weights",T.VEC3), _p("b_weights","B Weights",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = vec3(dot({color}, {r_weights}), dot({color}, {g_weights}), dot({color}, {b_weights}));",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("image/color_mask", "Color Mask", "Image Effects",
		["color mask","isolate channel","channel mask"],
		[_p("color","Color",T.VEC3), _p("target","Target",T.VEC3), _p("threshold","Threshold",T.FLOAT,0.1)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = 1.0 - smoothstep(0.0, {threshold}, length({color} - {target}));",
		S.STAGE_ANY, S.DOMAIN_ALL))
