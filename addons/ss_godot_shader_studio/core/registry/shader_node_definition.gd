## Describes a reusable node type: ports, compiler template, stage/domain support.
## Port entries: {"id": String, "name": String, "type": int, "default": Variant, "optional": bool}
class_name ShaderNodeDefinition
extends Resource

var id: String = ""
var display_name: String = ""
var category: String = ""
var keywords: Array = []

var inputs: Array = []   # Array of port dicts
var outputs: Array = []  # Array of port dicts

var properties_schema: Dictionary = {}
var stage_support: int = SGSTypes.STAGE_ANY
var domain_support: int = SGSTypes.DOMAIN_ALL
var compiler_template: String = ""
## GLSL helper functions emitted before shader stages (deduped by full string).
var helper_functions: Array[String] = []
## Auto-injected uniform (e.g. hint_screen_texture). Keys: name, type, glsl_hint, default_value.
var auto_uniform: Dictionary = {}


func get_id() -> String:           return id
func get_display_name() -> String: return display_name
func get_category() -> String:     return category
func get_keywords() -> Array:      return keywords
func get_compiler_template() -> String: return compiler_template
func get_stage_support() -> int:   return stage_support
func get_domain_support() -> int:  return domain_support

func supports_stage(flag: int) -> bool:  return (stage_support & flag) != 0
func supports_domain(flag: int) -> bool: return (domain_support & flag) != 0

## Returns an ordered list of input port id strings.
func get_input_ids() -> Array:
	var ids := []
	for p in inputs:
		ids.append(p["id"])
	return ids

## Returns an ordered list of output port id strings.
func get_output_ids() -> Array:
	var ids := []
	for p in outputs:
		ids.append(p["id"])
	return ids

## Returns the type (SGSTypes.ShaderType) of an input port, or VOID if not found.
func get_input_type(port_id: String) -> int:
	for p in inputs:
		if p["id"] == port_id:
			return p["type"]
	return SGSTypes.ShaderType.VOID

## Returns the type (SGSTypes.ShaderType) of an output port, or VOID if not found.
func get_output_type(port_id: String) -> int:
	for p in outputs:
		if p["id"] == port_id:
			return p["type"]
	return SGSTypes.ShaderType.VOID
