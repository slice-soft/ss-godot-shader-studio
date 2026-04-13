## Logical operator node definitions.
class_name LogicalNodes

static func register(r: NodeRegistry) -> void:
	_register_logical(r)


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


static func _register_logical(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("logical/compare", "Compare", "Logical",
		["compare","greater than","less than","equal compare"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0),
		 _p("true_val","True",T.FLOAT,1.0), _p("false_val","False",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = mix({false_val}, {true_val}, step({b}, {a}));",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("logical/if", "If", "Logical",
		["if","conditional","branch","if else","greater equal less"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0),
		 _p("gt","Greater",T.FLOAT,1.0), _p("eq","Equal",T.FLOAT,0.5), _p("lt","Less",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float _igt_{result} = step({b},{a}) * (1.0-step({a},{b}));\nfloat _ieq_{result} = step({a},{b}) * step({b},{a});\nfloat _ilt_{result} = step({a},{b}) * (1.0-step({b},{a}));\nfloat {result} = {gt}*_igt_{result} + {eq}*_ieq_{result} + {lt}*_ilt_{result};",
		S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("logical/select", "Select", "Logical",
		["select","ternary","mix bool","choose","switch value"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,1.0), _p("condition","Condition",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = mix({a}, {b}, step(0.5, {condition}));", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("logical/and", "And", "Logical",
		["and","logical and","&&","both true"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = step(0.5, {a}) * step(0.5, {b});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("logical/or", "Or", "Logical",
		["or","logical or","||","either true"],
		[_p("a","A",T.FLOAT,0.0), _p("b","B",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = min(step(0.5, {a}) + step(0.5, {b}), 1.0);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("logical/not", "Not", "Logical",
		["not","logical not","!","invert bool"],
		[_p("a","A",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = 1.0 - step(0.5, {a});", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("logical/compare_range", "Compare Range", "Logical",
		["compare range","in range","between","value in range"],
		[_p("x","X",T.FLOAT,0.5), _p("min_val","Min",T.FLOAT,0.0), _p("max_val","Max",T.FLOAT,1.0),
		 _p("true_val","True",T.FLOAT,1.0), _p("false_val","False",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float _in_{result} = step({min_val}, {x}) * (1.0 - step({max_val}, {x}));\nfloat {result} = mix({false_val}, {true_val}, _in_{result});",
		S.STAGE_ANY, S.DOMAIN_ALL))
