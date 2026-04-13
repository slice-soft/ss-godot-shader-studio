@tool
extends PopupPanel

signal node_chosen(def_id: String, graph_pos: Vector2)

var _graph_pos: Vector2
var _item_to_def: Dictionary = {}
var _domain_filter: int = SGSTypes.DOMAIN_ALL
var _stage_filter: int  = SGSTypes.STAGE_ANY

@onready var _search: LineEdit = $VBoxContainer/LineEdit
@onready var _tree: Tree       = $VBoxContainer/Tree


func _ready() -> void:
	_search.text_changed.connect(_on_search_changed)
	_search.gui_input.connect(_on_search_key)
	_tree.item_activated.connect(_on_item_activated)


func open_at(screen_pos: Vector2i, graph_pos: Vector2,
		domain_filter: int = SGSTypes.DOMAIN_ALL,
		stage_filter: int = SGSTypes.STAGE_ANY) -> void:
	_graph_pos     = graph_pos
	_domain_filter = domain_filter
	_stage_filter  = stage_filter
	_search.text = ""
	popup(Rect2i(screen_pos, Vector2i(420, 600)))
	_refresh_tree("")
	_search.grab_focus()


func _refresh_tree(query: String) -> void:
	_tree.clear()
	_item_to_def.clear()
	var registry = Engine.get_singleton("NodeRegistry")
	if registry == null:
		return

	var results: Array = registry.search(query)
	# Filter to nodes that are valid for the current domain and active stages.
	results = results.filter(func(def: ShaderNodeDefinition) -> bool:
		return def.supports_domain(_domain_filter) and def.supports_stage(_stage_filter)
	)
	var searching := query.strip_edges() != ""

	# Group by category preserving sort order
	var cats: Array[String] = []
	var by_cat: Dictionary = {}
	for def in results:
		var cat: String = def.get_category()
		if not by_cat.has(cat):
			cats.append(cat)
			by_cat[cat] = []
		by_cat[cat].append(def)
	cats.sort()

	var root := _tree.create_item()

	for cat in cats:
		var cat_item := _tree.create_item(root)
		cat_item.set_text(0, cat)
		cat_item.set_selectable(0, false)
		cat_item.set_collapsed(not searching)

		for def in by_cat[cat]:
			var node_item := _tree.create_item(cat_item)
			node_item.set_text(0, "  " + def.get_display_name())
			_item_to_def[node_item] = def

	# Auto-select first node when searching
	if searching:
		_select_first_node()


func _select_first_node() -> void:
	var node_item := _first_result_item()
	if node_item != null:
		node_item.select(0)


func _first_result_item() -> TreeItem:
	var root := _tree.get_root()
	if root == null:
		return null
	var cat_item := root.get_first_child()
	while cat_item != null:
		var node_item := cat_item.get_first_child()
		if node_item != null:
			return node_item
		cat_item = cat_item.get_next()
	return null


func _on_search_changed(text: String) -> void:
	_refresh_tree(text)


func _on_search_key(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_DOWN:
			_tree.grab_focus()
		KEY_ENTER, KEY_KP_ENTER:
			_try_activate_selected()


func _on_item_activated() -> void:
	_try_activate_selected()


func _try_activate_selected() -> void:
	var item := _tree.get_selected()
	if item == null:
		item = _first_result_item()
	if item == null or not _item_to_def.has(item):
		return
	var def = _item_to_def[item]
	hide()
	node_chosen.emit(def.get_id(), _graph_pos)
