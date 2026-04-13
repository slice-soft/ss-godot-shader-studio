## Texture sampling node definitions.
class_name TextureNodes

static func register(r: NodeRegistry) -> void:
	_register_texture(r)
	_register_texture_extended(r)


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


# ---- Texture ----

static func _register_texture(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("texture/sample_2d", "Sample Texture 2D", "Texture",
		["texture","sample","tex2d","sample2d","texture2d"],
		[_p("tex","Texture",T.SAMPLER2D), _p("uv","UV",T.UV)],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3),
		 _p("r","R",T.FLOAT), _p("g","G",T.FLOAT), _p("b","B",T.FLOAT), _p("a","A",T.FLOAT)],
		"vec4 {rgba} = texture({tex}, {uv});\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_FRAGMENT, S.DOMAIN_ALL))

	r.register_definition(_def("texture/sample_cube", "Sample Texture Cube", "Texture",
		["cubemap","cube texture","skybox sample","environment sample"],
		[_p("tex","Texture",T.SAMPLER_CUBE), _p("dir","Direction",T.VEC3)],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3)],
		"vec4 {rgba} = texture({tex}, {dir});\nvec3 {rgb} = {rgba}.rgb;",
		S.STAGE_FRAGMENT, S.DOMAIN_ALL))


# ---- Texture Extended ----

static func _register_texture_extended(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("texture/sample_normal", "Sample Normal Map", "Texture",
		["normal map","sample normal","tangent normal","normal texture"],
		[_p("tex","Texture",T.SAMPLER2D), _p("uv","UV",T.UV), _p("strength","Strength",T.FLOAT,1.0)],
		[_p("normal","Normal",T.VEC3)],
		"vec3 _sn_raw_{normal} = texture({tex}, {uv}).rgb * 2.0 - 1.0;\nvec3 {normal} = normalize(vec3(_sn_raw_{normal}.xy * {strength}, _sn_raw_{normal}.z));",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("texture/sample_lod", "Sample Texture LOD", "Texture",
		["texture lod","sample lod","mip level","explicit mip"],
		[_p("tex","Texture",T.SAMPLER2D), _p("uv","UV",T.UV), _p("lod","LOD",T.FLOAT,0.0)],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3),
		 _p("r","R",T.FLOAT), _p("g","G",T.FLOAT), _p("b","B",T.FLOAT), _p("a","A",T.FLOAT)],
		"vec4 {rgba} = textureLod({tex}, {uv}, {lod});\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("texture/texture_size", "Texture Size", "Texture",
		["texture size","texture resolution","texel size","texture dimensions"],
		[_p("tex","Texture",T.SAMPLER2D)],
		[_p("width","Width",T.FLOAT), _p("height","Height",T.FLOAT)],
		"ivec2 _tsz_{width} = textureSize({tex}, 0);\nfloat {width} = float(_tsz_{width}.x);\nfloat {height} = float(_tsz_{width}.y);",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("texture/texel_size", "Texel Size", "Texture",
		["texel size","1/texture size","uv step","pixel size uv"],
		[_p("tex","Texture",T.SAMPLER2D)],
		[_p("size","Size",T.VEC2)],
		"ivec2 _ts_iv_{size} = textureSize({tex}, 0);\nvec2 {size} = vec2(1.0 / float(_ts_iv_{size}.x), 1.0 / float(_ts_iv_{size}.y));",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("texture/sample_cube_lod", "Sample Cubemap LOD", "Texture",
		["cubemap lod","cube texture lod","environment lod","sample cube mip"],
		[_p("tex","Texture",T.SAMPLER_CUBE), _p("dir","Direction",T.VEC3), _p("lod","LOD",T.FLOAT,0.0)],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3)],
		"vec4 {rgba} = textureLod({tex}, {dir}, {lod});\nvec3 {rgb} = {rgba}.rgb;",
		S.STAGE_ANY, S.DOMAIN_ALL))
