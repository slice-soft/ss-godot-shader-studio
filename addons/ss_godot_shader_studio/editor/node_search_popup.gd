@tool
extends PopupPanel

signal node_chosen(def_id: String, graph_pos: Vector2)

var _graph_pos: Vector2
var _definitions: Array = []

@onready var _search: LineEdit = $VBoxContainer/LineEdit
@onready var _list: ItemList   = $VBoxContainer/ItemList


func _ready() -> void:
	_search.text_changed.connect(_on_search_changed)
	_list.item_activated.connect(_on_item_activated)


func open_at(screen_pos: Vector2i, graph_pos: Vector2) -> void:
	_graph_pos = graph_pos
	_search.text = ""
	popup(Rect2i(screen_pos, Vector2i(300, 400)))
	_refresh_list("")
	_search.grab_focus()


func _refresh_list(query: String) -> void:
	_list.clear()
	_definitions.clear()
	var registry = Engine.get_singleton("NodeRegistry")
	if registry == null:
		return
	var results: Array = registry.search(query)
	for def in results:
		_definitions.append(def)
		_list.add_item("%s  [%s]" % [def.get_display_name(), def.get_category()])


func _on_search_changed(text: String) -> void:
	_refresh_list(text)


func _on_item_activated(index: int) -> void:
	if index >= _definitions.size():
		return
	var def = _definitions[index]
	hide()
	node_chosen.emit(def.get_id(), _graph_pos)
