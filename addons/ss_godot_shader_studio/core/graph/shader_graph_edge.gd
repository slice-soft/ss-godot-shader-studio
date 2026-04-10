## A directed connection between two node ports in a ShaderGraphDocument.
class_name ShaderGraphEdge
extends Resource

var id: String = ""
var from_node_id: String = ""
var from_port_id: String = ""
var to_node_id: String = ""
var to_port_id: String = ""


func get_id() -> String:         return id
func get_from_node_id() -> String: return from_node_id
func get_from_port_id() -> String: return from_port_id
func get_to_node_id() -> String:   return to_node_id
func get_to_port_id() -> String:   return to_port_id

func set_id(v: String) -> void:           id = v
func set_from_node_id(v: String) -> void: from_node_id = v
func set_from_port_id(v: String) -> void: from_port_id = v
func set_to_node_id(v: String) -> void:   to_node_id = v
func set_to_port_id(v: String) -> void:   to_port_id = v
