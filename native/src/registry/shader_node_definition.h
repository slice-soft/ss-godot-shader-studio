#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>

#include "../types/port_definition.h"
#include "../graph/shader_domain.h"

#include <vector>

using namespace godot;

enum class PreviewPolicy {
    FULL,       // full preview in canvas
    THUMBNAIL,  // small thumbnail beside the node
    NONE,       // no preview
};

class ShaderNodeDefinition : public Resource {
    GDCLASS(ShaderNodeDefinition, Resource)

public:
    ShaderNodeDefinition() = default;

    // --- Identity ---
    void set_id(const String &p_id) { id = p_id; }
    String get_id() const { return id; }

    void set_display_name(const String &p_name) { display_name = p_name; }
    String get_display_name() const { return display_name; }

    void set_category(const String &p_cat) { category = p_cat; }
    String get_category() const { return category; }

    void set_keywords(const PackedStringArray &p_kw) { keywords = p_kw; }
    PackedStringArray get_keywords() const { return keywords; }

    // --- Ports (C++ side uses vector<PortDefinition>) ---
    void set_inputs_native(const std::vector<sgs::PortDefinition> &p_inputs) { inputs_native = p_inputs; }
    const std::vector<sgs::PortDefinition> &get_inputs_native() const { return inputs_native; }

    void set_outputs_native(const std::vector<sgs::PortDefinition> &p_outputs) { outputs_native = p_outputs; }
    const std::vector<sgs::PortDefinition> &get_outputs_native() const { return outputs_native; }

    // --- Properties schema (for inspector) ---
    void set_properties_schema(const Dictionary &p_schema) { properties_schema = p_schema; }
    Dictionary get_properties_schema() const { return properties_schema; }

    // --- Stage / domain support ---
    void set_stage_support(int p_flags) { stage_support = p_flags; }
    int get_stage_support() const { return stage_support; }

    void set_domain_support(int p_flags) { domain_support = p_flags; }
    int get_domain_support() const { return domain_support; }

    bool supports_stage(int p_stage_flag) const { return (stage_support & p_stage_flag) != 0; }
    bool supports_domain(int p_domain_flag) const { return (domain_support & p_domain_flag) != 0; }

    // --- Compiler template ---
    void set_compiler_template(const String &p_tpl) { compiler_template = p_tpl; }
    String get_compiler_template() const { return compiler_template; }

    // --- Preview ---
    void set_preview_policy(PreviewPolicy p_policy) { preview_policy = p_policy; }
    PreviewPolicy get_preview_policy() const { return preview_policy; }

protected:
    static void _bind_methods();

private:
    String id;
    String display_name;
    String category;
    PackedStringArray keywords;

    std::vector<sgs::PortDefinition> inputs_native;
    std::vector<sgs::PortDefinition> outputs_native;

    Dictionary properties_schema;

    int stage_support  = sgs::STAGE_ANY;
    int domain_support = sgs::DOMAIN_ALL;

    String compiler_template;
    PreviewPolicy preview_policy = PreviewPolicy::THUMBNAIL;
};
