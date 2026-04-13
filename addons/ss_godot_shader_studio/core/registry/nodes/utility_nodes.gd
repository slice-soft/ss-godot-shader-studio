## Utility and subgraph node definitions.
class_name UtilityNodes

static func register(r: NodeRegistry) -> void:
	_register_utility(r)


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


static func _register_utility(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	# Reroute — visual pass-through, no code emitted
	r.register_definition(_def("utility/reroute", "Reroute", "Utility",
		["reroute","relay","wire","route","dot"],
		[_p("in", "In", T.FLOAT)],
		[_p("out", "Out", T.FLOAT)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	# Custom Function — user writes inline GLSL body
	r.register_definition(_def("utility/custom_function", "Custom Function", "Utility",
		["custom","function","glsl","inline","code","expression","formula"],
		[
			_p("a", "A", T.FLOAT, null, true),
			_p("b", "B", T.FLOAT, null, true),
			_p("c", "C", T.FLOAT, null, true),
			_p("d", "D", T.FLOAT, null, true),
		],
		[_p("result", "Result", T.FLOAT)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	# Subgraph boundary nodes (used inside .gssubgraph files)
	r.register_definition(_def("subgraph/input", "Subgraph Input", "Subgraph",
		["subgraph input","graph input","expose input"],
		[], [_p("value", "Value", T.FLOAT)],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("subgraph/output", "Subgraph Output", "Subgraph",
		["subgraph output","graph output","expose output"],
		[_p("value", "Value", T.FLOAT)], [],
		"", S.STAGE_ANY, S.DOMAIN_ALL))

	# Embedded subgraph node in the parent graph
	r.register_definition(_def("utility/subgraph", "Subgraph", "Utility",
		["subgraph","function graph","reuse","embed"],
		[
			_p("a",   "A",   T.FLOAT, null, true),
			_p("b",   "B",   T.FLOAT, null, true),
			_p("c",   "C",   T.FLOAT, null, true),
			_p("d",   "D",   T.FLOAT, null, true),
		],
		[
			_p("out1", "Out1", T.FLOAT),
			_p("out2", "Out2", T.FLOAT),
		],
		"", S.STAGE_ANY, S.DOMAIN_ALL))
