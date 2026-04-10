## Drives the full pipeline: validation → IR → emit → .gdshader source.
## compile_gd() returns a Dictionary compatible with the existing editor panel code.
class_name ShaderGraphCompiler

const COMPILER_VERSION := "0.3.0-gdscript"


func compile_gd(doc: ShaderGraphDocument, source_path: String = "") -> Dictionary:
	if not Engine.has_singleton("NodeRegistry"):
		return {"success": false, "shader_code": "", "issues": []}
	var registry := Engine.get_singleton("NodeRegistry") as NodeRegistry

	# ---- Validation ----
	var validator := ValidationEngine.new()
	var val_result: Dictionary = validator.validate(doc, registry)
	if not val_result["success"]:
		return {"success": false, "shader_code": "", "issues": val_result["issues"]}

	# ---- IR ----
	var ir := IRBuilder.build(doc, registry)

	# ---- Emit ----
	var domain := doc.get_shader_domain()
	var shader_type_line: String
	var body: String

	match domain:
		"spatial":
			shader_type_line = "shader_type spatial;\n\n"
			body = _emit_spatial(ir)
		"canvas_item":
			shader_type_line = "shader_type canvas_item;\n\n"
			body = _emit_canvas_item(ir)
		"particles":
			shader_type_line = "shader_type particles;\n\n"
			body = _emit_particles(ir)
		"sky":
			shader_type_line = "shader_type sky;\n\n"
			body = _emit_sky(ir)
		"fog":
			shader_type_line = "shader_type fog;\n\n"
			body = _emit_fog(ir)
		"fullscreen":
			shader_type_line = "shader_type canvas_item;\n\n"
			body = _emit_canvas_item(ir)
		"subgraph":
			return {
				"success": false, "shader_code": "",
				"issues": [{"severity": 2, "node_id": "", "port_id": "",
					"message": "Subgraph files cannot be compiled directly.",
					"code": "E101"}]
			}
		_:
			return {
				"success": false, "shader_code": "",
				"issues": [{"severity": 2, "node_id": "", "port_id": "",
					"message": "Unsupported shader domain: '%s'." % domain,
					"code": "E100"}]
			}

	var header := _make_banner(source_path if not source_path.is_empty() else doc.get_name())
	var shader_code := header + shader_type_line + body
	return {"success": true, "shader_code": shader_code, "issues": val_result["issues"]}


# ---- Shared helpers ----

func _emit_uniforms(ir: Dictionary) -> String:
	var code := ""
	var uniforms: Array = ir["uniforms"].duplicate()
	uniforms.sort_custom(func(a, b): return a["name"] < b["name"])
	for u in uniforms:
		var type_str := TypeSystem.type_to_glsl(u["type"])
		code += "uniform %s %s%s" % [type_str, u["name"], u.get("glsl_hint", "")]
		var dv: String = u.get("default_value", "")
		if not dv.is_empty():
			code += " = %s" % dv
		code += ";\n"
	if not uniforms.is_empty():
		code += "\n"
	return code


func _emit_helpers(ir: Dictionary) -> String:
	var code := ""
	for hf: String in ir["helper_functions"]:
		code += hf + "\n\n"
	return code


func _emit_nodes(nodes: Array) -> String:
	var out := ""
	for ir_node in nodes:
		var line: String = _substitute(
			ir_node["compiler_template"],
			ir_node["resolved_inputs"],
			ir_node["output_vars"],
			ir_node["properties"])
		out += "\t" + line.replace("\n", "\n\t") + "\n"
	return out


func _substitute(tpl: String, inputs: Dictionary,
		outputs: Dictionary, props: Dictionary) -> String:
	var result := tpl
	for port_id in outputs:
		result = result.replace("{%s}" % port_id, outputs[port_id]["var_name"])
	for port_id in inputs:
		result = result.replace("{%s}" % port_id, inputs[port_id]["var_name"])
	for key in props:
		result = result.replace("{prop:%s}" % key, str(props[key]))
	return result


func _make_banner(source_name: String) -> String:
	return (
		"// ============================================================\n"
		+ "// GENERATED FILE — DO NOT EDIT MANUALLY\n"
		+ "// Source: %s\n" % source_name
		+ "// Compiled by: Godot Shader Studio %s\n" % COMPILER_VERSION
		+ "// ============================================================\n"
	)


# ---- Spatial emit ----

func _emit_spatial(ir: Dictionary) -> String:
	var code := ""
	code += _emit_uniforms(ir)
	code += _emit_helpers(ir)

	var vertex_nodes: Array = ir["vertex_nodes"]
	if not vertex_nodes.is_empty():
		code += "void vertex() {\n"
		code += _emit_nodes(vertex_nodes)
		code += "}\n\n"

	code += "void fragment() {\n"
	code += _emit_nodes(ir["fragment_nodes"])
	code += "}\n"

	return code


# ---- Canvas Item emit ----

func _emit_canvas_item(ir: Dictionary) -> String:
	var code := ""
	code += _emit_uniforms(ir)
	code += _emit_helpers(ir)

	var vertex_nodes: Array = ir["vertex_nodes"]
	if not vertex_nodes.is_empty():
		code += "void vertex() {\n"
		code += _emit_nodes(vertex_nodes)
		code += "}\n\n"

	code += "void fragment() {\n"
	code += _emit_nodes(ir["fragment_nodes"])
	code += "}\n"

	return code


# ---- Particles emit ----
# vertex_nodes → start() (initialization), fragment_nodes → process() (per-frame)

func _emit_particles(ir: Dictionary) -> String:
	var code := ""
	code += _emit_uniforms(ir)
	code += _emit_helpers(ir)

	var vertex_nodes: Array = ir["vertex_nodes"]
	if not vertex_nodes.is_empty():
		code += "void start() {\n"
		code += _emit_nodes(vertex_nodes)
		code += "}\n\n"

	code += "void process() {\n"
	code += _emit_nodes(ir["fragment_nodes"])
	code += "}\n"

	return code


# ---- Sky emit ----
# All nodes go into sky() function

func _emit_sky(ir: Dictionary) -> String:
	var code := ""
	code += _emit_uniforms(ir)
	code += _emit_helpers(ir)

	code += "void sky() {\n"
	code += _emit_nodes(ir["vertex_nodes"])
	code += _emit_nodes(ir["fragment_nodes"])
	code += "}\n"

	return code


# ---- Fog emit ----
# All nodes go into fog() function

func _emit_fog(ir: Dictionary) -> String:
	var code := ""
	code += _emit_uniforms(ir)
	code += _emit_helpers(ir)

	code += "void fog() {\n"
	code += _emit_nodes(ir["vertex_nodes"])
	code += _emit_nodes(ir["fragment_nodes"])
	code += "}\n"

	return code
