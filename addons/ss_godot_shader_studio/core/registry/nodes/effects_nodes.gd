## Advanced visual effects node definitions (Fresnel, Noise, Triplanar, Dissolve, Dither).
class_name EffectsNodes

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


static func register(r: NodeRegistry) -> void:
	_register_effects(r)


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


static func _register_effects(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("effects/fresnel", "Fresnel", "Effects",
		["fresnel","rim","rim light","edge glow","schlick"],
		[_p("normal","Normal",T.VEC3), _p("view","View",T.VEC3), _p("power","Power",T.FLOAT,5.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = pow(1.0 - clamp(dot(normalize({view}), normalize({normal})), 0.0, 1.0), {power});",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("effects/normal_blend", "Normal Blend", "Effects",
		["normal blend","blend normals","normal map blend","udn"],
		[_p("a","A",T.VEC3), _p("b","B",T.VEC3)],
		[_p("result","Result",T.VEC3)],
		"vec3 {result} = normalize(vec3({a}.xy + {b}.xy, {a}.z));",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("effects/toon_ramp", "Toon Ramp", "Effects",
		["toon","ramp","posterize","cel shade","steps","quantize"],
		[_p("value","Value",T.FLOAT,0.5), _p("steps","Steps",T.FLOAT,3.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = floor({value} * max({steps}, 1.0)) / max({steps}, 1.0);",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("effects/value_noise", "Value Noise", "Effects",
		["noise","value noise","procedural noise","random","hash"],
		[_p("uv","UV",T.UV), _p("scale","Scale",T.FLOAT,4.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = _sgs_value_noise({uv} * {scale});",
		S.STAGE_ANY, S.DOMAIN_ALL,
		[_H_HASH, _H_VALUE_NOISE]))

	r.register_definition(_def("effects/triplanar", "Triplanar", "Effects",
		["triplanar","world projection","no-stretch","terrain texture"],
		[_p("tex","Texture",T.SAMPLER2D),
		 _p("world_pos","World Pos",T.VEC3),
		 _p("normal","Normal",T.VEC3),
		 _p("blend","Blend",T.FLOAT,8.0)],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3)],
		"vec4 {rgba} = _sgs_triplanar({tex}, {world_pos}, {normal}, {blend});\nvec3 {rgb} = {rgba}.rgb;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL,
		[_H_TRIPLANAR]))

	r.register_definition(_def("effects/dither", "Dither", "Effects",
		["dither","ordered dither","bayer","pixel art","alpha clip dither"],
		[_p("screen_pos","Screen Pos",T.VEC2), _p("value","Value",T.FLOAT,0.5)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = _sgs_dither({screen_pos}, {value});",
		S.STAGE_FRAGMENT, S.DOMAIN_ALL,
		[_H_DITHER]))

	r.register_definition(_def("effects/dissolve", "Dissolve", "Effects",
		["dissolve","burn","cutout","noise dissolve","appear","disappear"],
		[_p("uv","UV",T.UV), _p("scale","Scale",T.FLOAT,4.0), _p("threshold","Threshold",T.FLOAT,0.5)],
		[_p("mask","Mask",T.FLOAT)],
		"float _sgs_dn_{mask} = _sgs_value_noise({uv} * {scale});\nfloat {mask} = step({threshold}, _sgs_dn_{mask});",
		S.STAGE_ANY, S.DOMAIN_ALL,
		[_H_HASH, _H_VALUE_NOISE]))
