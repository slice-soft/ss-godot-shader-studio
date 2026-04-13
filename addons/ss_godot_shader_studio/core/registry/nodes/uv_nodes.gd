## UV and texture coordinate node definitions.
class_name UVNodes

static func register(r: NodeRegistry) -> void:
	_register_uv(r)
	_register_uv_extended(r)


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


# ---- UV ----

static func _register_uv(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("uv/panner", "Panner", "UV",
		["panner","scroll","pan uv","animate uv"],
		[_p("uv","UV",T.UV), _p("speed","Speed",T.VEC2), _p("time","Time",T.TIME,0.0)],
		[_p("result","Result",T.UV)],
		"vec2 {result} = {uv} + {speed} * {time};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/rotator", "Rotator", "UV",
		["rotator","rotate uv","spin uv"],
		[_p("uv","UV",T.UV), _p("center","Center",T.VEC2), _p("angle","Angle",T.FLOAT,0.0)],
		[_p("result","Result",T.UV)],
		"float _cos_r_{result} = cos({angle});\nfloat _sin_r_{result} = sin({angle});\nvec2 _uv_c_{result} = {uv} - {center};\nvec2 {result} = vec2(_cos_r_{result} * _uv_c_{result}.x - _sin_r_{result} * _uv_c_{result}.y, _sin_r_{result} * _uv_c_{result}.x + _cos_r_{result} * _uv_c_{result}.y) + {center};",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/tiling_offset", "Tiling & Offset", "UV",
		["tiling","offset","uv tiling","uv offset","repeat"],
		[_p("uv","UV",T.UV), _p("tiling","Tiling",T.VEC2), _p("offset","Offset",T.VEC2)],
		[_p("result","Result",T.UV)],
		"vec2 {result} = {uv} * {tiling} + {offset};", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- UV Extended ----

static func _register_uv_extended(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("uv/polar_coordinates", "Polar Coordinates", "UV",
		["polar","polar coordinates","angular uv","circular uv","radial uv"],
		[_p("uv","UV",T.UV), _p("center","Center",T.VEC2),
		 _p("radial_scale","Radial Scale",T.FLOAT,1.0), _p("length_scale","Length Scale",T.FLOAT,1.0)],
		[_p("result","Result",T.UV)],
		"vec2 _pc_d_{result} = {uv} - {center};\nfloat _pc_ang_{result} = atan(_pc_d_{result}.y, _pc_d_{result}.x) / 6.28318530718 + 0.5;\nfloat _pc_rad_{result} = length(_pc_d_{result}) * {radial_scale};\nvec2 {result} = vec2(_pc_ang_{result}, _pc_rad_{result}) * {length_scale};",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/flip_u", "Flip U", "UV",
		["flip u","mirror horizontal","mirror x uv","flip x uv"],
		[_p("uv","UV",T.UV)],
		[_p("result","Result",T.UV)],
		"vec2 {result} = vec2(1.0 - {uv}.x, {uv}.y);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/flip_v", "Flip V", "UV",
		["flip v","mirror vertical","mirror y uv","flip y uv"],
		[_p("uv","UV",T.UV)],
		[_p("result","Result",T.UV)],
		"vec2 {result} = vec2({uv}.x, 1.0 - {uv}.y);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/radial_shear", "Radial Shear", "UV",
		["radial shear","twist uv","spiral uv","swirl uv"],
		[_p("uv","UV",T.UV), _p("center","Center",T.VEC2), _p("strength","Strength",T.FLOAT,1.0)],
		[_p("result","Result",T.UV)],
		"vec2 _rs_d_{result} = {uv} - {center};\nfloat _rs_a_{result} = length(_rs_d_{result}) * {strength};\nfloat _rs_s_{result} = sin(_rs_a_{result});\nfloat _rs_c_{result} = cos(_rs_a_{result});\nvec2 {result} = vec2(_rs_c_{result}*_rs_d_{result}.x - _rs_s_{result}*_rs_d_{result}.y, _rs_s_{result}*_rs_d_{result}.x + _rs_c_{result}*_rs_d_{result}.y) + {center};",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("uv/parallax_offset", "Parallax Offset", "UV",
		["parallax","parallax offset","depth uv offset","height map parallax"],
		[_p("uv","UV",T.UV), _p("height","Height",T.FLOAT,0.0),
		 _p("amplitude","Amplitude",T.FLOAT,0.02), _p("view","View Dir",T.VEC3)],
		[_p("result","Result",T.UV)],
		"vec2 {result} = {uv} + ({view}.xy / max(abs({view}.z), 0.001)) * ({height} * {amplitude});",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("uv/spherical", "Spherical UV", "UV",
		["spherical uv","sphere map","matcap uv","environment uv"],
		[_p("normal","Normal",T.VEC3), _p("view","View Dir",T.VEC3)],
		[_p("result","Result",T.UV)],
		"vec3 _suv_r_{result} = reflect(-{view}, normalize({normal}));\nfloat _suv_m_{result} = 2.0 * sqrt(_suv_r_{result}.x*_suv_r_{result}.x + _suv_r_{result}.y*_suv_r_{result}.y + (_suv_r_{result}.z+1.0)*(_suv_r_{result}.z+1.0));\nvec2 {result} = _suv_r_{result}.xy / _suv_m_{result} + 0.5;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("uv/dither_uv", "Dither UV", "UV",
		["dither uv","pixel uv","pixelate uv","quantize uv"],
		[_p("uv","UV",T.UV), _p("steps","Steps",T.FLOAT,8.0)],
		[_p("result","Result",T.UV)],
		"vec2 {result} = floor({uv} * {steps}) / {steps};", S.STAGE_ANY, S.DOMAIN_ALL))
