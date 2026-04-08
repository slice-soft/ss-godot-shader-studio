#include "shader_node_definition.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void ShaderNodeDefinition::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_id", "id"), &ShaderNodeDefinition::set_id);
    ClassDB::bind_method(D_METHOD("get_id"), &ShaderNodeDefinition::get_id);

    ClassDB::bind_method(D_METHOD("set_display_name", "name"), &ShaderNodeDefinition::set_display_name);
    ClassDB::bind_method(D_METHOD("get_display_name"), &ShaderNodeDefinition::get_display_name);

    ClassDB::bind_method(D_METHOD("set_category", "category"), &ShaderNodeDefinition::set_category);
    ClassDB::bind_method(D_METHOD("get_category"), &ShaderNodeDefinition::get_category);

    ClassDB::bind_method(D_METHOD("set_keywords", "keywords"), &ShaderNodeDefinition::set_keywords);
    ClassDB::bind_method(D_METHOD("get_keywords"), &ShaderNodeDefinition::get_keywords);

    ClassDB::bind_method(D_METHOD("set_properties_schema", "schema"), &ShaderNodeDefinition::set_properties_schema);
    ClassDB::bind_method(D_METHOD("get_properties_schema"), &ShaderNodeDefinition::get_properties_schema);

    ClassDB::bind_method(D_METHOD("set_stage_support", "flags"), &ShaderNodeDefinition::set_stage_support);
    ClassDB::bind_method(D_METHOD("get_stage_support"), &ShaderNodeDefinition::get_stage_support);

    ClassDB::bind_method(D_METHOD("set_domain_support", "flags"), &ShaderNodeDefinition::set_domain_support);
    ClassDB::bind_method(D_METHOD("get_domain_support"), &ShaderNodeDefinition::get_domain_support);

    ClassDB::bind_method(D_METHOD("set_compiler_template", "tpl"), &ShaderNodeDefinition::set_compiler_template);
    ClassDB::bind_method(D_METHOD("get_compiler_template"), &ShaderNodeDefinition::get_compiler_template);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "id"), "set_id", "get_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "display_name"), "set_display_name", "get_display_name");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "category"), "set_category", "get_category");
    ADD_PROPERTY(PropertyInfo(Variant::PACKED_STRING_ARRAY, "keywords"), "set_keywords", "get_keywords");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "properties_schema"), "set_properties_schema", "get_properties_schema");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "stage_support"), "set_stage_support", "get_stage_support");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "domain_support"), "set_domain_support", "get_domain_support");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "compiler_template"), "set_compiler_template", "get_compiler_template");
}
