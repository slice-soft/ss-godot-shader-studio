#include "shader_graph_edge.h"

#include <godot_cpp/core/class_db.hpp>

using namespace godot;

void ShaderGraphEdge::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_id", "id"), &ShaderGraphEdge::set_id);
    ClassDB::bind_method(D_METHOD("get_id"), &ShaderGraphEdge::get_id);

    ClassDB::bind_method(D_METHOD("set_from_node_id", "id"), &ShaderGraphEdge::set_from_node_id);
    ClassDB::bind_method(D_METHOD("get_from_node_id"), &ShaderGraphEdge::get_from_node_id);

    ClassDB::bind_method(D_METHOD("set_from_port_id", "id"), &ShaderGraphEdge::set_from_port_id);
    ClassDB::bind_method(D_METHOD("get_from_port_id"), &ShaderGraphEdge::get_from_port_id);

    ClassDB::bind_method(D_METHOD("set_to_node_id", "id"), &ShaderGraphEdge::set_to_node_id);
    ClassDB::bind_method(D_METHOD("get_to_node_id"), &ShaderGraphEdge::get_to_node_id);

    ClassDB::bind_method(D_METHOD("set_to_port_id", "id"), &ShaderGraphEdge::set_to_port_id);
    ClassDB::bind_method(D_METHOD("get_to_port_id"), &ShaderGraphEdge::get_to_port_id);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "id"), "set_id", "get_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "from_node_id"), "set_from_node_id", "get_from_node_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "from_port_id"), "set_from_port_id", "get_from_port_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "to_node_id"), "set_to_node_id", "get_to_node_id");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "to_port_id"), "set_to_port_id", "get_to_port_id");
}
