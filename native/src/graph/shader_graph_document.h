#pragma once

#include <godot_cpp/classes/resource.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/vector2.hpp>

#include "shader_graph_node_instance.h"
#include "shader_graph_edge.h"

using namespace godot;

class ShaderGraphDocument : public Resource {
    GDCLASS(ShaderGraphDocument, Resource)

public:
    ShaderGraphDocument();

    // --- Identity ---
    void set_uuid(const String &p_uuid) { uuid = p_uuid; }
    String get_uuid() const { return uuid; }

    void set_name(const String &p_name) { name = p_name; }
    String get_name() const { return name; }

    void set_format_version(int p_version) { format_version = p_version; }
    int get_format_version() const { return format_version; }

    void set_shader_domain(const String &p_domain) { shader_domain = p_domain; }
    String get_shader_domain() const { return shader_domain; }

    // --- Stage config ---
    void set_stage_config(const Dictionary &p_config) { stage_config = p_config; }
    Dictionary get_stage_config() const { return stage_config; }

    // --- Parameters (exposed uniforms) ---
    void set_parameters(const Array &p_params) { parameters = p_params; }
    Array get_parameters() const { return parameters; }

    // --- Subgraph refs ---
    void set_subgraph_refs(const Array &p_refs) { subgraph_refs = p_refs; }
    Array get_subgraph_refs() const { return subgraph_refs; }

    // --- Editor state (UI-only, not used by compiler) ---
    void set_editor_state(const Dictionary &p_state) { editor_state = p_state; }
    Dictionary get_editor_state() const { return editor_state; }

    // --- Node management ---
    // Adds a node with the given definition_id at position. Returns the new node's ID.
    String add_node(const String &p_definition_id, const Vector2 &p_position);
    void remove_node(const String &p_node_id);
    Ref<ShaderGraphNodeInstance> get_node(const String &p_node_id) const;
    Array get_all_nodes() const;

    // --- Edge management ---
    // Returns edge ID on success, empty string on failure (duplicate or invalid).
    String add_edge(const String &p_from_node, const String &p_from_port,
                    const String &p_to_node, const String &p_to_port);
    void remove_edge(const String &p_edge_id);
    Array get_edges_from(const String &p_node_id) const;
    Array get_edges_to(const String &p_node_id) const;
    Array get_all_edges() const;

    // --- Raw node/edge arrays (used by serializer) ---
    void set_nodes(const Array &p_nodes) { nodes = p_nodes; }
    Array get_nodes() const { return nodes; }

    void set_edges(const Array &p_edges) { edges = p_edges; }
    Array get_edges() const { return edges; }

protected:
    static void _bind_methods();

private:
    String uuid;
    String name;
    int format_version = 1;
    String shader_domain = "spatial";
    Dictionary stage_config;
    Array nodes;
    Array edges;
    Array parameters;
    Array subgraph_refs;
    Dictionary editor_state;

    int _node_counter = 0;
    int _edge_counter = 0;

    String _generate_node_id();
    String _generate_edge_id();
};
