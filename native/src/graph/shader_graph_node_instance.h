#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/vector2.hpp>
#include <godot_cpp/variant/dictionary.hpp>

using namespace godot;

class ShaderGraphNodeInstance : public Resource {
    GDCLASS(ShaderGraphNodeInstance, Resource)

public:
    ShaderGraphNodeInstance() = default;

    void set_id(const String &p_id) { id = p_id; }
    String get_id() const { return id; }

    void set_definition_id(const String &p_id) { definition_id = p_id; }
    String get_definition_id() const { return definition_id; }

    void set_title(const String &p_title) { title = p_title; }
    String get_title() const { return title; }

    void set_position(const Vector2 &p_pos) { position = p_pos; }
    Vector2 get_position() const { return position; }

    void set_properties(const Dictionary &p_props) { properties = p_props; }
    Dictionary get_properties() const { return properties; }

    void set_stage_scope(const String &p_scope) { stage_scope = p_scope; }
    String get_stage_scope() const { return stage_scope; }

    void set_preview_enabled(bool p_enabled) { preview_enabled = p_enabled; }
    bool get_preview_enabled() const { return preview_enabled; }

    // Convenience: read/write a single property value
    void set_property(const String &p_key, const Variant &p_value);
    Variant get_property(const String &p_key) const;

protected:
    static void _bind_methods();

private:
    String id;
    String definition_id;
    String title;
    Vector2 position;
    Dictionary properties;
    String stage_scope = "any";
    bool preview_enabled = false;
};
