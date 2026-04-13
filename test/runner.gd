## Test runner — discovers and executes all TestCase subclasses.
## Run with:  godot --headless --editor --path . --script test/runner.gd
extends SceneTree


func _initialize() -> void:
	print("=" .repeat(60))
	print("  Godot Shader Studio — Test Suite")
	print("=" .repeat(60))

	if not Engine.is_editor_hint():
		push_error("Run the test suite with --headless --editor to enable editor integration coverage.")
		quit(1)
		return

	# Let editor plugins finish bootstrapping so editor-owned singletons exist first.
	await process_frame

	# Register the NodeRegistry singleton that the compiler requires when the plugin
	# has not already done so as part of editor startup.
	var _registry = Engine.get_singleton("NodeRegistry") if Engine.has_singleton("NodeRegistry") else null
	var _owns_registry := false
	if _registry == null:
		_registry = NodeRegistry.new()
		StdlibRegistration.register_all(_registry)
		Engine.register_singleton("NodeRegistry", _registry)
		_owns_registry = true

	var total_pass := 0
	var total_fail := 0
	var suite_count := 0

	var suite_load_result := _collect_suites()
	if suite_load_result.get("success", false) == false:
		push_error(suite_load_result.get("message", "Failed to load test suites"))
		if _owns_registry:
			Engine.unregister_singleton("NodeRegistry")
			_registry.free()
		quit(1)
		return

	var suites: Array = suite_load_result.get("suites", [])

	for suite_raw in suites:
		var suite := suite_raw as TestCase
		suite_count += 1
		print("\n[SUITE] %s" % suite.suite_name())
		await suite.run_all()
		var p: int = suite.get_pass_count()
		var f: int = suite.get_fail_count()
		total_pass += p
		total_fail += f
		var status := "PASS" if f == 0 else "FAIL"
		print("  → %d passed, %d failed  [%s]" % [p, f, status])

	print("\n" + "=" .repeat(60))
	print("  %d suites  |  %d passed  |  %d failed" % [suite_count, total_pass, total_fail])
	print("=" .repeat(60))

	if _owns_registry:
		Engine.unregister_singleton("NodeRegistry")
		_registry.free()

	if total_fail > 0:
		quit(1)
	else:
		print("  ALL TESTS PASSED")
		quit(0)


func _collect_suites() -> Dictionary:
	var suite_paths := [
		"res://test/unit/test_type_system.gd",
		"res://test/unit/test_graph_document.gd",
		"res://test/unit/test_node_registry.gd",
		"res://test/unit/test_validation_engine.gd",
		"res://test/unit/test_ir_builder.gd",
		"res://test/unit/test_compiler.gd",
		"res://test/unit/test_subgraph_contracts.gd",
		"res://test/unit/test_shader_graph_path_utils.gd",
		"res://test/integration/test_shader_editor_panel_integration.gd",
		"res://test/integration/test_graph_canvas_integration.gd",
		"res://test/integration/test_shader_preview_integration.gd",
	]

	var suites: Array = []
	for path in suite_paths:
		var script := load(path)
		if script == null:
			return {
				"success": false,
				"message": "Could not load test suite script: %s" % path,
				"suites": [],
			}
		var instance = script.new()
		if not (instance is TestCase):
			return {
				"success": false,
				"message": "Loaded script is not a TestCase: %s" % path,
				"suites": [],
			}
		suites.append(instance)

	return {
		"success": true,
		"suites": suites,
	}
