## Shared path and filename helpers for graph source assets and generated shaders.
class_name ShaderGraphPathUtils

const DEFAULT_GRAPH_DIR := "res://shader_assets/graphs"
const DEFAULT_SUBGRAPH_DIR := "res://shader_assets/subgraphs"
const DEFAULT_GENERATED_SHADER_DIR := "res://assets/shaders/generated"


static func expected_extension_for_domain(domain: String) -> String:
	return "gssubgraph" if domain == "subgraph" else "gshadergraph"


static func default_source_dir(domain: String, current_path: String = "") -> String:
	if not current_path.is_empty():
		return current_path.get_base_dir()
	return DEFAULT_SUBGRAPH_DIR if domain == "subgraph" else DEFAULT_GRAPH_DIR


static func default_source_path(domain: String, raw_name: String, current_path: String = "") -> String:
	var dir := default_source_dir(domain, current_path)
	var base := normalize_asset_basename(raw_name)
	if base.is_empty():
		base = "shader_subgraph" if domain == "subgraph" else "shader_graph"
	return dir.path_join("%s.%s" % [base, expected_extension_for_domain(domain)])


static func normalize_asset_basename(raw_name: String) -> String:
	var name := raw_name.strip_edges().to_lower()
	if name.is_empty():
		return ""

	var normalized := ""
	var prev_is_separator := false
	for ch in name:
		var is_letter := ch >= "a" and ch <= "z"
		var is_number := ch >= "0" and ch <= "9"
		if is_letter or is_number:
			normalized += ch
			prev_is_separator = false
		elif not prev_is_separator:
			normalized += "_"
			prev_is_separator = true

	normalized = normalized.strip_edges()
	while normalized.begins_with("_"):
		normalized = normalized.substr(1)
	while normalized.ends_with("_"):
		normalized = normalized.left(normalized.length() - 1)
	while normalized.contains("__"):
		normalized = normalized.replace("__", "_")

	return normalized


static func normalize_source_path(path: String, domain: String) -> String:
	if path.is_empty():
		return ""

	var base_dir := path.get_base_dir()
	if base_dir.is_empty():
		base_dir = "res://"

	var raw_file := path.get_file().get_basename()
	var normalized_name := normalize_asset_basename(raw_file)
	if normalized_name.is_empty():
		normalized_name = "shader_subgraph" if domain == "subgraph" else "shader_graph"

	return base_dir.path_join("%s.%s" % [normalized_name, expected_extension_for_domain(domain)])


static func generated_shader_path(source_path: String) -> String:
	if source_path.is_empty():
		return ""
	return "%s.generated.gdshader" % source_path.get_basename()


static func default_generated_shader_dir(current_dir: String = "") -> String:
	return current_dir if not current_dir.is_empty() else DEFAULT_GENERATED_SHADER_DIR


static func generated_shader_filename(source_path: String) -> String:
	return generated_shader_path(source_path).get_file()


static func generated_shader_path_for_dir(source_path: String, output_dir: String) -> String:
	if source_path.is_empty():
		return ""
	var dir := default_generated_shader_dir(output_dir)
	return dir.path_join(generated_shader_filename(source_path))


static func generated_uid_path(source_path: String) -> String:
	var shader_path := generated_shader_path(source_path)
	return "%s.uid" % shader_path if not shader_path.is_empty() else ""


static func generated_uid_path_for_dir(source_path: String, output_dir: String) -> String:
	var shader_path := generated_shader_path_for_dir(source_path, output_dir)
	return "%s.uid" % shader_path if not shader_path.is_empty() else ""


static func import_metadata_path(source_path: String) -> String:
	return "%s.import" % source_path if not source_path.is_empty() else ""


static func risky_save_reason(path: String) -> String:
	if path.is_empty():
		return ""
	if path.begins_with("res://addons/"):
		return "Guardar graphs dentro de addons mezcla assets fuente con codigo del plugin."
	if path.begins_with("res://.godot/"):
		return "La carpeta .godot es temporal del editor y no es una ubicacion valida para archivos fuente."
	return ""


static func guidance_for_path(path: String, domain: String, generated_shader_path_override: String = "") -> String:
	var recommended_dir := default_source_dir(domain)
	if path.is_empty():
		var pending_text := " | Shader generado: se pedira carpeta de salida antes de escribirlo" \
				if domain != "subgraph" else ""
		return "Sin guardar. Recomendado: %s%s" % [recommended_dir, pending_text]

	var source_kind := "Subgraph fuente" if domain == "subgraph" else "Graph fuente"
	var text := "%s: %s" % [source_kind, path]
	if domain != "subgraph":
		if generated_shader_path_override.is_empty():
			text += " | Shader generado: pendiente de carpeta de salida"
		else:
			text += " | Shader generado: %s" % generated_shader_path_override

	var warning := risky_save_reason(path)
	if not warning.is_empty():
		text += " | Advertencia: %s" % warning
	elif not path.begins_with(recommended_dir):
		text += " | Recomendado: %s" % recommended_dir

	return text


static func ensure_source_dir_exists(domain: String, current_path: String = "") -> void:
	var target_dir := default_source_dir(domain, current_path)
	if target_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))


static func ensure_generated_dir_exists(output_dir: String = "") -> void:
	var target_dir := default_generated_shader_dir(output_dir)
	if target_dir.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target_dir))
