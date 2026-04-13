## Shader uniform / parameter node definitions.
class_name ParameterNodes

static func register(r: NodeRegistry) -> void:
	_register_parameters(r)
	_register_parameters_extended(r)


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


# Parameter nodes are transparent to the IR: the output var_name IS the uniform
# name, and the IR builder emits the uniform declaration separately.
# No code body is emitted — downstream nodes reference the uniform directly.

static func _register_parameters(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("parameter/float", "Float Parameter", "Parameters",
		["float parameter","uniform float","shader property float"],
		[], [_p("value","Value",T.FLOAT)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/vec4", "Vec4 Parameter", "Parameters",
		["vec4 parameter","uniform vec4","shader property vec4"],
		[], [_p("value","Value",T.VEC4)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/color", "Color Parameter", "Parameters",
		["color parameter","uniform color","shader property color","tint"],
		[], [_p("value","Value",T.COLOR)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/texture2d", "Texture2D Parameter", "Parameters",
		["texture parameter","uniform sampler2d","shader texture property"],
		[], [_p("value","Value",T.SAMPLER2D)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))


static func _register_parameters_extended(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("parameter/vec2", "Vec2 Parameter", "Parameters",
		["vec2 parameter","uniform vec2","shader property vec2","vector 2 param"],
		[], [_p("value","Value",T.VEC2)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/vec3", "Vec3 Parameter", "Parameters",
		["vec3 parameter","uniform vec3","shader property vec3","vector 3 param"],
		[], [_p("value","Value",T.VEC3)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/int", "Int Parameter", "Parameters",
		["int parameter","uniform int","integer property","int param"],
		[], [_p("value","Value",T.INT)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/toggle", "Toggle Parameter", "Parameters",
		["toggle","bool parameter","switch uniform","on off param"],
		[], [_p("value","Value",T.FLOAT)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("parameter/sampler_cube", "Cubemap Parameter", "Parameters",
		["cubemap parameter","uniform sampler cube","environment map param","hdri param"],
		[], [_p("value","Value",T.SAMPLER_CUBE)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))
