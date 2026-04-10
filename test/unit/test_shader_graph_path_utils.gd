extends TestCase

const ShaderGraphPathUtils = preload("res://addons/ss_godot_shader_studio/core/graph/shader_graph_path_utils.gd")


func test_normalize_asset_basename_uses_snake_case() -> void:
	assert_eq(
		ShaderGraphPathUtils.normalize_asset_basename("Screen Green Final"),
		"screen_green_final")


func test_normalize_source_path_enforces_subgraph_extension() -> void:
	assert_eq(
		ShaderGraphPathUtils.normalize_source_path("res://graphs/My Fancy Node.gshadergraph", "subgraph"),
		"res://graphs/my_fancy_node.gssubgraph")


func test_generated_shader_path_tracks_source_basename() -> void:
	assert_eq(
		ShaderGraphPathUtils.generated_shader_path("res://shader_assets/graphs/screen_green.gshadergraph"),
		"res://shader_assets/graphs/screen_green.generated.gdshader")


func test_generated_shader_path_for_dir_uses_selected_output_folder() -> void:
	assert_eq(
		ShaderGraphPathUtils.generated_shader_path_for_dir(
			"res://shader_assets/graphs/screen_green.gshadergraph",
			"res://shaders/runtime"),
		"res://shaders/runtime/screen_green.generated.gdshader")


func test_guidance_mentions_pending_generated_output_until_folder_is_selected() -> void:
	assert_contains(
		ShaderGraphPathUtils.guidance_for_path(
			"res://shader_assets/graphs/screen_green.gshadergraph",
			"spatial"),
		"Shader generado: pendiente de carpeta de salida")
