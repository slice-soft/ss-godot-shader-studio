## Shader output node definitions for all domains.
class_name OutputNodes

static func register(r: NodeRegistry) -> void:
	_register_output(r)


static func _p(id: String, name: String, type: int,
		default: Variant = null, optional: bool = false) -> Dictionary:
	return {"id": id, "name": name, "type": type, "default": default, "optional": optional}


static func _register_output(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	# --- Spatial (PBR) ---
	var spatial := ShaderNodeDefinition.new()
	spatial.id           = "output/spatial"
	spatial.display_name = "Spatial Output"
	spatial.category     = "Output"
	spatial.keywords     = ["output","spatial output","material output","pbr output"]
	spatial.inputs       = [
		_p("albedo",     "Albedo",     T.VEC3,  null, true),
		_p("roughness",  "Roughness",  T.FLOAT, 0.5,  true),
		_p("metallic",   "Metallic",   T.FLOAT, 0.0,  true),
		_p("emission",   "Emission",   T.VEC3,  null, true),
		_p("normal_map", "Normal Map", T.VEC3,  null, true),
		_p("alpha",      "Alpha",      T.FLOAT, 1.0,  true),
		_p("ao",         "AO",         T.FLOAT, 1.0,  true),
	]
	spatial.outputs           = []
	spatial.compiler_template = "ALBEDO = {albedo};\nROUGHNESS = {roughness};\nMETALLIC = {metallic};\nEMISSION = {emission};\nNORMAL_MAP = {normal_map};\nALPHA = {alpha};\nAO = {ao};"
	spatial.stage_support     = S.STAGE_FRAGMENT
	spatial.domain_support    = S.DOMAIN_SPATIAL
	r.register_definition(spatial)

	# --- Vertex Offset ---
	var vert := ShaderNodeDefinition.new()
	vert.id           = "output/vertex_offset"
	vert.display_name = "Vertex Offset"
	vert.category     = "Output"
	vert.keywords     = ["vertex offset","displace","vertex displacement","mesh deformation","wave"]
	vert.inputs       = [_p("offset","Offset",T.VEC3, null, true)]
	vert.outputs           = []
	vert.compiler_template = "VERTEX += {offset};"
	vert.stage_support     = S.STAGE_VERTEX
	vert.domain_support    = S.DOMAIN_SPATIAL
	r.register_definition(vert)

	# --- Canvas Item ---
	var ci := ShaderNodeDefinition.new()
	ci.id           = "output/canvas_item"
	ci.display_name = "Canvas Item Output"
	ci.category     = "Output"
	ci.keywords     = ["output","canvas item","2d output","sprite output","canvas output"]
	ci.inputs       = [
		_p("color",            "Color",        T.COLOR, null, true),
		_p("normal_map",       "Normal Map",   T.VEC3,  null, true),
		_p("normal_map_depth", "Normal Depth", T.FLOAT, 1.0,  true),
	]
	ci.outputs           = []
	ci.compiler_template = "COLOR = {color};\nNORMAL_MAP = {normal_map};\nNORMAL_MAP_DEPTH = {normal_map_depth};"
	ci.stage_support     = S.STAGE_FRAGMENT
	ci.domain_support    = S.DOMAIN_CANVAS_ITEM
	r.register_definition(ci)

	# --- Fullscreen / Postprocess ---
	var fs := ShaderNodeDefinition.new()
	fs.id           = "output/fullscreen"
	fs.display_name = "Fullscreen Output"
	fs.category     = "Output"
	fs.keywords     = ["output","fullscreen","postprocess","post-process","screen effect","vfx"]
	fs.inputs       = [_p("color", "Color", T.COLOR, null, true)]
	fs.outputs           = []
	fs.compiler_template = "COLOR = {color};"
	fs.stage_support     = S.STAGE_FRAGMENT
	fs.domain_support    = S.DOMAIN_FULLSCREEN
	r.register_definition(fs)

	# --- Particles ---
	var pt := ShaderNodeDefinition.new()
	pt.id           = "output/particles"
	pt.display_name = "Particles Output"
	pt.category     = "Output"
	pt.keywords     = ["output","particles output","particle","gpu particles"]
	pt.inputs       = [
		_p("velocity",  "Velocity",  T.VEC3,  null, true),
		_p("color",     "Color",     T.COLOR, null, true),
		_p("custom",    "Custom",    T.COLOR, null, true),
		_p("active",    "Active",    T.FLOAT, 1.0,  true),
	]
	pt.outputs           = []
	pt.compiler_template = "VELOCITY = {velocity};\nCOLOR = {color};\nCUSTOM = {custom};\nACTIVE = bool({active} > 0.5);"
	pt.stage_support     = S.STAGE_FRAGMENT
	pt.domain_support    = S.DOMAIN_PARTICLES
	r.register_definition(pt)

	# --- Sky ---
	var sky := ShaderNodeDefinition.new()
	sky.id           = "output/sky"
	sky.display_name = "Sky Output"
	sky.category     = "Output"
	sky.keywords     = ["output","sky output","sky shader","background","atmosphere","procedural sky"]
	sky.inputs       = [
		_p("color", "Color", T.VEC3,  null, true),
		_p("alpha", "Alpha", T.FLOAT, 1.0,  true),
		_p("fog",   "Fog",   T.COLOR, null, true),
	]
	sky.outputs           = []
	sky.compiler_template = "COLOR = {color};\nALPHA = {alpha};\nFOG = {fog};"
	sky.stage_support     = S.STAGE_FRAGMENT
	sky.domain_support    = S.DOMAIN_SKY
	r.register_definition(sky)

	# --- Fog ---
	var fog := ShaderNodeDefinition.new()
	fog.id           = "output/fog"
	fog.display_name = "Fog Output"
	fog.category     = "Output"
	fog.keywords     = ["output","fog output","volumetric fog","fog shader"]
	fog.inputs       = [
		_p("albedo",   "Albedo",   T.VEC3,  null, true),
		_p("density",  "Density",  T.FLOAT, 1.0,  true),
		_p("emission", "Emission", T.VEC3,  null, true),
	]
	fog.outputs           = []
	fog.compiler_template = "ALBEDO = {albedo};\nDENSITY = {density};\nEMISSION = {emission};"
	fog.stage_support     = S.STAGE_FRAGMENT
	fog.domain_support    = S.DOMAIN_FOG
	r.register_definition(fog)
