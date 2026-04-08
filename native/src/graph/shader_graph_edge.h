#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

class ShaderGraphEdge : public Resource {
    GDCLASS(ShaderGraphEdge, Resource)

public:
    ShaderGraphEdge() = default;

    void set_id(const String &p_id) { id = p_id; }
    String get_id() const { return id; }

    void set_from_node_id(const String &p_id) { from_node_id = p_id; }
    String get_from_node_id() const { return from_node_id; }

    void set_from_port_id(const String &p_id) { from_port_id = p_id; }
    String get_from_port_id() const { return from_port_id; }

    void set_to_node_id(const String &p_id) { to_node_id = p_id; }
    String get_to_node_id() const { return to_node_id; }

    void set_to_port_id(const String &p_id) { to_port_id = p_id; }
    String get_to_port_id() const { return to_port_id; }

protected:
    static void _bind_methods();

private:
    String id;
    String from_node_id;
    String from_port_id;
    String to_node_id;
    String to_port_id;
};
