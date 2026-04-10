extends TestCase

const PREVIEW_SCENE = preload("res://addons/ss_godot_shader_studio/preview/shader_preview.tscn")

var _tree: SceneTree
var _preview: SubViewportContainer


func before_all() -> void:
	_tree = Engine.get_main_loop() as SceneTree


func setup() -> void:
	_preview = PREVIEW_SCENE.instantiate()
	_tree.root.add_child(_preview)
	await _tree.process_frame


func teardown() -> void:
	_free_node(_preview)
	_preview = null


func test_spatial_shader_uses_3d_preview() -> void:
	_preview.apply_shader("shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(1.0);\n}\n")

	assert_true(_preview._node3d.visible)
	assert_false(_preview._container_2d.visible)
	assert_not_null(_preview._mesh.material_override)
	assert_null(_preview._color_rect.material)


func test_canvas_item_shader_uses_2d_preview() -> void:
	_preview.apply_shader("shader_type canvas_item;\nvoid fragment() {\n\tCOLOR = vec4(1.0);\n}\n")

	assert_true(_preview._node3d.visible)
	assert_true(_preview._container_2d.visible)
	assert_not_null(_preview._color_rect.material)


func test_unsupported_shader_hides_preview() -> void:
	_preview.apply_shader("shader_type sky;\nvoid sky() {\n\tCOLOR = vec3(0.0);\n}\n")

	assert_false(_preview._node3d.visible)
	assert_false(_preview._container_2d.visible)


func test_empty_shader_resets_preview_state() -> void:
	_preview.apply_shader("shader_type spatial;\nvoid fragment() {\n\tALBEDO = vec3(0.2);\n}\n")
	_preview.apply_shader("")

	assert_true(_preview._node3d.visible)
	assert_false(_preview._container_2d.visible)
	assert_null(_preview._mesh.material_override)
	assert_null(_preview._color_rect.material)


func _free_node(node: Node) -> void:
	if not is_instance_valid(node):
		return
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	node.free()
