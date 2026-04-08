#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include "shader_node_definition.h"

#include <unordered_map>
#include <string>
#include <vector>

using namespace godot;

class NodeRegistry : public Object {
    GDCLASS(NodeRegistry, Object)

public:
    NodeRegistry() = default;

    // Register a definition. Takes ownership (stored as Ref).
    void register_definition(ShaderNodeDefinition *p_def);

    // Look up by id. Returns nullptr if not found.
    ShaderNodeDefinition *get_definition(const String &p_id) const;

    // Returns all definitions in a category.
    Array get_all_in_category(const String &p_category) const;

    // Simple substring search over id, display_name, and keywords.
    Array search(const String &p_query) const;

    // All registered category names (sorted).
    PackedStringArray get_categories() const;

    // All registered definitions.
    Array get_all_definitions() const;

    // Godot singleton accessor
    static NodeRegistry *get_singleton();

protected:
    static void _bind_methods();

private:
    // id → definition
    std::unordered_map<std::string, Ref<ShaderNodeDefinition>> _definitions;
    // category → list of ids in registration order
    std::unordered_map<std::string, std::vector<std::string>> _by_category;

    static NodeRegistry *_singleton;
};
