extends TestCase


var registry: NodeRegistry


func before_all() -> void:
	registry = NodeRegistry.new()
	StdlibRegistration.register_all(registry)


func after_all() -> void:
	registry.free()


func test_register_all_exposes_extended_builtin_nodes() -> void:
	for def_id in [
		"math/add",
		"logical/select",
		"matrix/model",
		"image/hue_shift",
		"parameter/vec3",
		"parameter/sampler_cube",
		"input/particles_random",
		"output/fullscreen",
	]:
		assert_not_null(registry.get_definition(def_id), def_id)


func test_search_matches_keywords_and_display_names() -> void:
	assert_true(_search_has_id("contrast", "image/simple_contrast"))
	assert_true(_search_has_id("cubemap", "parameter/sampler_cube"))
	assert_true(_search_has_id("screen effect", "output/fullscreen"))


func test_categories_are_sorted_and_include_new_groups() -> void:
	var cats: Array = registry.get_categories()
	var sorted := cats.duplicate()
	sorted.sort()

	assert_eq(cats, sorted)
	assert_array_has(cats, "Image Effects")
	assert_array_has(cats, "Logical")
	assert_array_has(cats, "Matrix")


func test_extended_parameter_nodes_keep_expected_output_types() -> void:
	var int_def := registry.get_definition("parameter/int")
	var toggle_def := registry.get_definition("parameter/toggle")
	var cube_def := registry.get_definition("parameter/sampler_cube")

	assert_not_null(int_def)
	assert_not_null(toggle_def)
	assert_not_null(cube_def)
	assert_eq(int_def.get_output_type("value"), SGSTypes.ShaderType.INT)
	assert_eq(toggle_def.get_output_type("value"), SGSTypes.ShaderType.FLOAT)
	assert_eq(cube_def.get_output_type("value"), SGSTypes.ShaderType.SAMPLER_CUBE)


func _search_has_id(query: String, def_id: String) -> bool:
	for entry in registry.search(query):
		var def := entry as ShaderNodeDefinition
		if def != null and def.get_id() == def_id:
			return true
	return false
