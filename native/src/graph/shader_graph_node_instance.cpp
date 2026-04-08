#include "shader_graph_node_instance.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void ShaderGraphNodeInstance::set_property(const String &p_key, const Variant &p_value) {
    properties[p_key] = p_value;
}

Variant ShaderGraphNodeInstance::get_property(const String &p_key) const {
    if (properties.has(p_key)) {
        return properties[p_key];
    }
    return Variant();
}

void ShaderGraphNodeInstance::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_id", "id"), &ShaderGraphNodeInstance::set_id);
    ClassDB::bind_method(D_METHOD("get_id"), &ShaderGraphNodeInstance::get_id);

    ClassDB::bind_method(D_METHOD("set_definition_id", "definition_id"), &ShaderGraphNodeInstance::set_definition_id);
    ClassDB::bind_method(D_METHOD("get_definition_id"), &ShaderGraphNodeInstance::get_definition_id);

    ClassDB::bind_method(D_METHOD("set_title", "title"), &ShaderGraphNodeInstance::set_title);
    ClassDB::bind_method(D_METHOD("get_title"), &ShaderGraphNodeInstance::get_title);

    ClassDB::bind_method(D_METHOD("set_position", "position"), &ShaderGraphNodeInstance::set_position);
    ClassDB::bind_method(D_METHOD("get_position"), &ShaderGraphNodeInstance::get_position);

    ClassDB::bind_method(D_METHOD("set_properties", "properties"), &ShaderGraphNodeInstance::set_properties);
    ClassDB::bind_method(D_METHOD("get_properties"), &ShaderGraphNodeInstance::get_properties);

    ClassDB::bind_method(D_METHOD("set_stage_scope", "stage_scope"), &ShaderGraphNodeInstance::set_stage_scope);
    ClassDB::bind_method(D_METHOD("get_stage_scope"), &ShaderGraphNodeInstance::get_stage_scope);

    ClassDB::bind_method(D_METHOD("set_preview_enabled", "enabled"), &ShaderGraphNodeInstance::set_preview_enabled);
    ClassDB::bind_method(D_METHOD("get_preview_enabled"), &ShaderGraphNodeInstance::get_preview_enabled);

    ClassDB::bind_method(D_METHOD("set_property", "key", "value"), &ShaderGraphNodeInstance::set_property);
    ClassDB::bind_method(D_METHOD("get_property", "key"), &ShaderGraphNodeInstance::get_property);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "id"), "set_id", "get_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "definition_id"), "set_definition_id", "get_definition_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "title"), "set_title", "get_title");
    ADD_PROPERTY(PropertyInfo(Variant::VECTOR2, "position"), "set_position", "get_position");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "properties"), "set_properties", "get_properties");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "stage_scope"), "set_stage_scope", "get_stage_scope");
    ADD_PROPERTY(PropertyInfo(Variant::BOOL, "preview_enabled"), "set_preview_enabled", "get_preview_enabled");
}
