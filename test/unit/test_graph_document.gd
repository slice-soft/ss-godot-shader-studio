## Unit tests for ShaderGraphDocument — node/edge CRUD and counter behaviour.
extends TestCase


var doc: ShaderGraphDocument


func setup() -> void:
	doc = ShaderGraphDocument.new()
	doc.set_name("TestDoc")
	doc.set_shader_domain("spatial")


# ---- Identity ----

func test_default_name() -> void:
	var fresh := ShaderGraphDocument.new()
	# Access property directly — Object::get_name() is a C++ built-in that returns ""
	# for fresh instances and cannot be overridden cleanly in GDScript.
	assert_eq(fresh.name, "Untitled")


func test_set_name() -> void:
	assert_eq(doc.get_name(), "TestDoc")


func test_set_shader_domain() -> void:
	assert_eq(doc.get_shader_domain(), "spatial")


# ---- add_node / get_node / get_all_nodes ----

func test_add_node_returns_id() -> void:
	var id := doc.add_node("math/add", Vector2.ZERO)
	assert_false(id.is_empty())


func test_add_node_increments_counter() -> void:
	var id1 := doc.add_node("math/add", Vector2.ZERO)
	var id2 := doc.add_node("math/multiply", Vector2.ZERO)
	assert_ne(id1, id2)


func test_get_node_returns_correct_instance() -> void:
	var id := doc.add_node("math/add", Vector2(10, 20))
	var node := doc.get_node(id)
	assert_not_null(node)
	assert_eq(node.definition_id, "math/add")
	assert_eq(node.position, Vector2(10, 20))


func test_get_node_unknown_returns_null() -> void:
	assert_null(doc.get_node("nonexistent"))


func test_get_all_nodes_count() -> void:
	doc.add_node("math/add", Vector2.ZERO)
	doc.add_node("math/multiply", Vector2.ZERO)
	assert_eq(doc.get_all_nodes().size(), 2)


# ---- remove_node ----

func test_remove_node_removes_from_list() -> void:
	var id := doc.add_node("math/add", Vector2.ZERO)
	doc.remove_node(id)
	assert_null(doc.get_node(id))
	assert_eq(doc.get_all_nodes().size(), 0)


func test_remove_node_also_removes_edges() -> void:
	var a_id := doc.add_node("math/add", Vector2.ZERO)
	var b_id := doc.add_node("math/multiply", Vector2.ZERO)
	doc.add_edge(a_id, "result", b_id, "a")
	assert_eq(doc.get_all_edges().size(), 1)
	doc.remove_node(a_id)
	assert_eq(doc.get_all_edges().size(), 0)


# ---- add_edge / get_all_edges ----

func test_add_edge_returns_id() -> void:
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	var eid := doc.add_edge(a, "result", b, "a")
	assert_false(eid.is_empty())


func test_duplicate_connection_to_same_port_rejected() -> void:
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	doc.add_edge(a, "result", b, "a")
	var eid2 := doc.add_edge(a, "result", b, "a")
	assert_eq(eid2, "")  # empty → rejected
	assert_eq(doc.get_all_edges().size(), 1)


func test_different_ports_accepted() -> void:
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	doc.add_edge(a, "result", b, "a")
	doc.add_edge(a, "result", b, "b")
	assert_eq(doc.get_all_edges().size(), 2)


# ---- remove_edge ----

func test_remove_edge() -> void:
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	var eid := doc.add_edge(a, "result", b, "a")
	doc.remove_edge(eid)
	assert_eq(doc.get_all_edges().size(), 0)


# ---- get_edges_from / get_edges_to ----

func test_get_edges_from() -> void:
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	var c := doc.add_node("output/spatial", Vector2.ZERO)
	doc.add_edge(a, "result", b, "a")
	doc.add_edge(a, "result", c, "roughness")
	assert_eq(doc.get_edges_from(a).size(), 2)
	assert_eq(doc.get_edges_from(b).size(), 0)


func test_get_edges_to() -> void:
	var a := doc.add_node("math/add", Vector2.ZERO)
	var b := doc.add_node("math/multiply", Vector2.ZERO)
	doc.add_edge(a, "result", b, "a")
	assert_eq(doc.get_edges_to(b).size(), 1)
	assert_eq(doc.get_edges_to(a).size(), 0)


# ---- Frames ----

func test_add_frame_returns_id() -> void:
	var fid := doc.add_frame("My Frame", Vector2.ZERO, Vector2(200, 100))
	assert_false(fid.is_empty())


func test_get_frame_returns_correct_data() -> void:
	var fid := doc.add_frame("Test Frame", Vector2(5, 10), Vector2(300, 200))
	var f := doc.get_frame(fid)
	assert_eq(f["title"], "Test Frame")
	assert_eq(f["position"], Vector2(5, 10))
	assert_eq(f["size"], Vector2(300, 200))


func test_remove_frame() -> void:
	var fid := doc.add_frame("Frame", Vector2.ZERO, Vector2(100, 100))
	doc.remove_frame(fid)
	assert_true(doc.get_frame(fid).is_empty())
	assert_eq(doc.get_all_frames().size(), 0)


# ---- Counter persistence across set_nodes ----

func test_counter_synced_after_set_nodes() -> void:
	# Manually insert nodes with high IDs; new add_node should not collide.
	var node := ShaderGraphNodeInstance.new()
	node.id = "node_99"
	node.definition_id = "math/add"
	doc.set_nodes([node])
	var new_id := doc.add_node("math/add", Vector2.ZERO)
	assert_ne(new_id, "node_99")
	# Counter should be ≥ 100
	assert_true(new_id.trim_prefix("node_").to_int() > 99)
