## Singleton catalog of all available ShaderNodeDefinitions.
## Registered as an Engine singleton by plugin.gd on enter_tree.
class_name NodeRegistry
extends Object

var _definitions: Dictionary = {}    # id (String) → ShaderNodeDefinition
var _by_category: Dictionary = {}    # category (String) → Array[String] (ids)


func register_definition(def: ShaderNodeDefinition) -> void:
	if _definitions.has(def.id):
		push_warning("NodeRegistry: overwriting definition for id: %s" % def.id)
	_definitions[def.id] = def
	if not _by_category.has(def.category):
		_by_category[def.category] = []
	_by_category[def.category].append(def.id)


func get_definition(id: String) -> ShaderNodeDefinition:
	return _definitions.get(id, null)


func get_all_in_category(category: String) -> Array:
	var result := []
	if not _by_category.has(category):
		return result
	for id in _by_category[category]:
		if _definitions.has(id):
			result.append(_definitions[id])
	return result


func search(query: String) -> Array:
	if query.is_empty():
		return get_all_definitions()
	var q := query.to_lower()
	var result := []
	for id in _definitions:
		var def: ShaderNodeDefinition = _definitions[id]
		var found := false
		if def.id.to_lower().contains(q):
			found = true
		elif def.display_name.to_lower().contains(q):
			found = true
		else:
			for kw in def.keywords:
				if str(kw).to_lower().contains(q):
					found = true
					break
		if found:
			result.append(def)
	return result


func get_categories() -> Array:
	var cats := _by_category.keys()
	cats.sort()
	return cats


func get_all_definitions() -> Array:
	return _definitions.values()
