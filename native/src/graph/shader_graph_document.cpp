#include "shader_graph_document.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

ShaderGraphDocument::ShaderGraphDocument() {
    stage_config["has_vertex"]   = true;
    stage_config["has_fragment"] = true;
    stage_config["has_light"]    = false;
}

// ---- ID generation ----

String ShaderGraphDocument::_generate_node_id() {
    return String("node_") + String::num_int64(++_node_counter);
}

String ShaderGraphDocument::_generate_edge_id() {
    return String("edge_") + String::num_int64(++_edge_counter);
}

// ---- Node management ----

String ShaderGraphDocument::add_node(const String &p_definition_id, const Vector2 &p_position) {
    Ref<ShaderGraphNodeInstance> node;
    node.instantiate();
    node->set_id(_generate_node_id());
    node->set_definition_id(p_definition_id);
    node->set_title(p_definition_id);  // caller can rename after creation
    node->set_position(p_position);
    nodes.push_back(node);
    return node->get_id();
}

void ShaderGraphDocument::remove_node(const String &p_node_id) {
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (node.is_valid() && node->get_id() == p_node_id) {
            nodes.remove_at(i);
            break;
        }
    }
    // Also remove all edges connected to this node
    for (int i = edges.size() - 1; i >= 0; i--) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (edge.is_valid() &&
            (edge->get_from_node_id() == p_node_id || edge->get_to_node_id() == p_node_id)) {
            edges.remove_at(i);
        }
    }
}

Ref<ShaderGraphNodeInstance> ShaderGraphDocument::get_node(const String &p_node_id) const {
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (node.is_valid() && node->get_id() == p_node_id) {
            return node;
        }
    }
    return Ref<ShaderGraphNodeInstance>();
}

Array ShaderGraphDocument::get_all_nodes() const {
    return nodes;
}

// ---- Edge management ----

String ShaderGraphDocument::add_edge(const String &p_from_node, const String &p_from_port,
                                      const String &p_to_node, const String &p_to_port) {
    // Prevent duplicate connections to the same input port
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> existing = edges[i];
        if (existing.is_valid() &&
            existing->get_to_node_id() == p_to_node &&
            existing->get_to_port_id() == p_to_port) {
            return String(); // already connected
        }
    }

    Ref<ShaderGraphEdge> edge;
    edge.instantiate();
    edge->set_id(_generate_edge_id());
    edge->set_from_node_id(p_from_node);
    edge->set_from_port_id(p_from_port);
    edge->set_to_node_id(p_to_node);
    edge->set_to_port_id(p_to_port);
    edges.push_back(edge);
    return edge->get_id();
}

void ShaderGraphDocument::remove_edge(const String &p_edge_id) {
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (edge.is_valid() && edge->get_id() == p_edge_id) {
            edges.remove_at(i);
            return;
        }
    }
}

Array ShaderGraphDocument::get_edges_from(const String &p_node_id) const {
    Array result;
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (edge.is_valid() && edge->get_from_node_id() == p_node_id) {
            result.push_back(edge);
        }
    }
    return result;
}

Array ShaderGraphDocument::get_edges_to(const String &p_node_id) const {
    Array result;
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (edge.is_valid() && edge->get_to_node_id() == p_node_id) {
            result.push_back(edge);
        }
    }
    return result;
}

Array ShaderGraphDocument::get_all_edges() const {
    return edges;
}

// ---- Bindings ----

void ShaderGraphDocument::_bind_methods() {
    ClassDB::bind_method(D_METHOD("set_uuid", "uuid"), &ShaderGraphDocument::set_uuid);
    ClassDB::bind_method(D_METHOD("get_uuid"), &ShaderGraphDocument::get_uuid);

    ClassDB::bind_method(D_METHOD("set_name", "name"), &ShaderGraphDocument::set_name);
    ClassDB::bind_method(D_METHOD("get_name"), &ShaderGraphDocument::get_name);

    ClassDB::bind_method(D_METHOD("set_format_version", "version"), &ShaderGraphDocument::set_format_version);
    ClassDB::bind_method(D_METHOD("get_format_version"), &ShaderGraphDocument::get_format_version);

    ClassDB::bind_method(D_METHOD("set_shader_domain", "domain"), &ShaderGraphDocument::set_shader_domain);
    ClassDB::bind_method(D_METHOD("get_shader_domain"), &ShaderGraphDocument::get_shader_domain);

    ClassDB::bind_method(D_METHOD("set_stage_config", "config"), &ShaderGraphDocument::set_stage_config);
    ClassDB::bind_method(D_METHOD("get_stage_config"), &ShaderGraphDocument::get_stage_config);

    ClassDB::bind_method(D_METHOD("set_parameters", "parameters"), &ShaderGraphDocument::set_parameters);
    ClassDB::bind_method(D_METHOD("get_parameters"), &ShaderGraphDocument::get_parameters);

    ClassDB::bind_method(D_METHOD("set_subgraph_refs", "refs"), &ShaderGraphDocument::set_subgraph_refs);
    ClassDB::bind_method(D_METHOD("get_subgraph_refs"), &ShaderGraphDocument::get_subgraph_refs);

    ClassDB::bind_method(D_METHOD("set_editor_state", "state"), &ShaderGraphDocument::set_editor_state);
    ClassDB::bind_method(D_METHOD("get_editor_state"), &ShaderGraphDocument::get_editor_state);

    ClassDB::bind_method(D_METHOD("set_nodes", "nodes"), &ShaderGraphDocument::set_nodes);
    ClassDB::bind_method(D_METHOD("get_nodes"), &ShaderGraphDocument::get_nodes);

    ClassDB::bind_method(D_METHOD("set_edges", "edges"), &ShaderGraphDocument::set_edges);
    ClassDB::bind_method(D_METHOD("get_edges"), &ShaderGraphDocument::get_edges);

    ClassDB::bind_method(D_METHOD("add_node", "definition_id", "position"), &ShaderGraphDocument::add_node);
    ClassDB::bind_method(D_METHOD("remove_node", "node_id"), &ShaderGraphDocument::remove_node);
    ClassDB::bind_method(D_METHOD("get_node", "node_id"), &ShaderGraphDocument::get_node);
    ClassDB::bind_method(D_METHOD("get_all_nodes"), &ShaderGraphDocument::get_all_nodes);

    ClassDB::bind_method(D_METHOD("add_edge", "from_node", "from_port", "to_node", "to_port"), &ShaderGraphDocument::add_edge);
    ClassDB::bind_method(D_METHOD("remove_edge", "edge_id"), &ShaderGraphDocument::remove_edge);
    ClassDB::bind_method(D_METHOD("get_edges_from", "node_id"), &ShaderGraphDocument::get_edges_from);
    ClassDB::bind_method(D_METHOD("get_edges_to", "node_id"), &ShaderGraphDocument::get_edges_to);
    ClassDB::bind_method(D_METHOD("get_all_edges"), &ShaderGraphDocument::get_all_edges);

    ADD_PROPERTY(PropertyInfo(Variant::STRING, "uuid"), "set_uuid", "get_uuid");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "name"), "set_name", "get_name");
    ADD_PROPERTY(PropertyInfo(Variant::INT, "format_version"), "set_format_version", "get_format_version");
    ADD_PROPERTY(PropertyInfo(Variant::STRING, "shader_domain"), "set_shader_domain", "get_shader_domain");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "stage_config"), "set_stage_config", "get_stage_config");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "nodes"), "set_nodes", "get_nodes");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "edges"), "set_edges", "get_edges");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "parameters"), "set_parameters", "get_parameters");
    ADD_PROPERTY(PropertyInfo(Variant::ARRAY, "subgraph_refs"), "set_subgraph_refs", "get_subgraph_refs");
    ADD_PROPERTY(PropertyInfo(Variant::DICTIONARY, "editor_state"), "set_editor_state", "get_editor_state");
}
