## Test runner — discovers and executes all TestCase subclasses.
## Run with:  godot --headless --path . --script test/runner.gd
extends SceneTree


func _initialize() -> void:
	print("=" .repeat(60))
	print("  Godot Shader Studio — Test Suite")
	print("=" .repeat(60))

	# Register the NodeRegistry singleton that the compiler requires.
	var _registry := NodeRegistry.new()
	StdlibRegistration.register_all(_registry)
	Engine.register_singleton("NodeRegistry", _registry)

	var total_pass := 0
	var total_fail := 0
	var suite_count := 0

	var suites: Array = _collect_suites()

	for suite_raw in suites:
		var suite := suite_raw as TestCase
		suite_count += 1
		print("\n[SUITE] %s" % suite.suite_name())
		suite.run_all()
		var p: int = suite.get_pass_count()
		var f: int = suite.get_fail_count()
		total_pass += p
		total_fail += f
		var status := "PASS" if f == 0 else "FAIL"
		print("  → %d passed, %d failed  [%s]" % [p, f, status])

	print("\n" + "=" .repeat(60))
	print("  %d suites  |  %d passed  |  %d failed" % [suite_count, total_pass, total_fail])
	print("=" .repeat(60))

	Engine.unregister_singleton("NodeRegistry")

	if total_fail > 0:
		quit(1)
	else:
		print("  ALL TESTS PASSED")
		quit(0)


func _collect_suites() -> Array:
	return [
		preload("res://test/unit/test_type_system.gd").new(),
		preload("res://test/unit/test_graph_document.gd").new(),
		preload("res://test/unit/test_validation_engine.gd").new(),
		preload("res://test/unit/test_ir_builder.gd").new(),
		preload("res://test/unit/test_compiler.gd").new(),
	]
