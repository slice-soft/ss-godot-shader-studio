## A placed instance of a node definition inside a ShaderGraphDocument.
class_name ShaderGraphNodeInstance
extends Resource

var id: String = ""
var definition_id: String = ""
var title: String = ""
var position: Vector2 = Vector2.ZERO
var properties: Dictionary = {}
var stage_scope: String = "any"
var preview_enabled: bool = false


func get_id() -> String:            return id
func get_definition_id() -> String: return definition_id
func get_title() -> String:         return title
func get_position() -> Vector2:     return position
func get_properties() -> Dictionary: return properties
func get_stage_scope() -> String:   return stage_scope
func get_preview_enabled() -> bool: return preview_enabled

func set_id(v: String) -> void:            id = v
func set_definition_id(v: String) -> void: definition_id = v
func set_title(v: String) -> void:         title = v
func set_position(v: Vector2) -> void:     position = v
func set_properties(v: Dictionary) -> void: properties = v
func set_stage_scope(v: String) -> void:   stage_scope = v
func set_preview_enabled(v: bool) -> void: preview_enabled = v

func set_property(key: String, value: Variant) -> void:
	properties[key] = value

func get_property(key: String) -> Variant:
	return properties.get(key, null)
