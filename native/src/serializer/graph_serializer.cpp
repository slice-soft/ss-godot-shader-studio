#include "graph_serializer.h"

#include <godot_cpp/classes/file_access.hpp>
#include <godot_cpp/classes/json.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

// ---- Document → Dictionary ----

Dictionary GraphSerializer::_document_to_dict(ShaderGraphDocument *p_doc) {
    Dictionary d;
    d["format_version"] = GraphSerializer::CURRENT_FORMAT_VERSION;
    d["uuid"]           = p_doc->get_uuid();
    d["name"]           = p_doc->get_name();
    d["shader_domain"]  = p_doc->get_shader_domain();
    d["stage_config"]   = p_doc->get_stage_config();

    // Nodes
    Array nodes_arr;
    Array nodes = p_doc->get_all_nodes();
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) continue;

        Dictionary nd;
        nd["id"]              = node->get_id();
        nd["definition_id"]   = node->get_definition_id();
        nd["title"]           = node->get_title();
        nd["position"]        = Dictionary();
        Dictionary pos_dict;
        pos_dict["x"] = node->get_position().x;
        pos_dict["y"] = node->get_position().y;
        nd["position"]        = pos_dict;
        nd["properties"]      = node->get_properties();
        nd["stage_scope"]     = node->get_stage_scope();
        nd["preview_enabled"] = node->get_preview_enabled();
        nodes_arr.push_back(nd);
    }
    d["nodes"] = nodes_arr;

    // Edges
    Array edges_arr;
    Array edges = p_doc->get_all_edges();
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (!edge.is_valid()) continue;

        Dictionary ed;
        ed["id"]           = edge->get_id();
        ed["from_node_id"] = edge->get_from_node_id();
        ed["from_port_id"] = edge->get_from_port_id();
        ed["to_node_id"]   = edge->get_to_node_id();
        ed["to_port_id"]   = edge->get_to_port_id();
        edges_arr.push_back(ed);
    }
    d["edges"] = edges_arr;

    d["parameters"]    = p_doc->get_parameters();
    d["subgraph_refs"] = p_doc->get_subgraph_refs();
    d["editor_state"]  = p_doc->get_editor_state();

    return d;
}

// ---- Dictionary → Document ----

ShaderGraphDocument *GraphSerializer::_dict_to_document(const Dictionary &d) {
    ShaderGraphDocument *doc = memnew(ShaderGraphDocument);

    if (d.has("uuid"))          doc->set_uuid(d["uuid"]);
    if (d.has("name"))          doc->set_name(d["name"]);
    if (d.has("shader_domain")) doc->set_shader_domain(d["shader_domain"]);
    if (d.has("stage_config"))  doc->set_stage_config(d["stage_config"]);
    if (d.has("parameters"))    doc->set_parameters(d["parameters"]);
    if (d.has("subgraph_refs")) doc->set_subgraph_refs(d["subgraph_refs"]);
    if (d.has("editor_state"))  doc->set_editor_state(d["editor_state"]);

    // Nodes
    if (d.has("nodes")) {
        Array nodes_arr = d["nodes"];
        Array node_refs;
        for (int i = 0; i < nodes_arr.size(); i++) {
            Dictionary nd = nodes_arr[i];
            Ref<ShaderGraphNodeInstance> node;
            node.instantiate();

            if (nd.has("id"))              node->set_id(nd["id"]);
            if (nd.has("definition_id"))   node->set_definition_id(nd["definition_id"]);
            if (nd.has("title"))           node->set_title(nd["title"]);
            if (nd.has("properties"))      node->set_properties(nd["properties"]);
            if (nd.has("stage_scope"))     node->set_stage_scope(nd["stage_scope"]);
            if (nd.has("preview_enabled")) node->set_preview_enabled(nd["preview_enabled"]);

            if (nd.has("position")) {
                Dictionary pos = nd["position"];
                float px = pos.has("x") ? (float)pos["x"] : 0.0f;
                float py = pos.has("y") ? (float)pos["y"] : 0.0f;
                node->set_position(Vector2(px, py));
            }
            node_refs.push_back(node);
        }
        doc->set_nodes(node_refs);
    }

    // Edges
    if (d.has("edges")) {
        Array edges_arr = d["edges"];
        Array edge_refs;
        for (int i = 0; i < edges_arr.size(); i++) {
            Dictionary ed = edges_arr[i];
            Ref<ShaderGraphEdge> edge;
            edge.instantiate();

            if (ed.has("id"))           edge->set_id(ed["id"]);
            if (ed.has("from_node_id")) edge->set_from_node_id(ed["from_node_id"]);
            if (ed.has("from_port_id")) edge->set_from_port_id(ed["from_port_id"]);
            if (ed.has("to_node_id"))   edge->set_to_node_id(ed["to_node_id"]);
            if (ed.has("to_port_id"))   edge->set_to_port_id(ed["to_port_id"]);
            edge_refs.push_back(edge);
        }
        doc->set_edges(edge_refs);
    }

    return doc;
}

// ---- Save ----

int GraphSerializer::save(ShaderGraphDocument *p_doc, const String &p_path) {
    ERR_FAIL_NULL_V(p_doc, FAILED);

    Dictionary d = _document_to_dict(p_doc);
    String json_text = JSON::stringify(d, "\t", false);

    Ref<FileAccess> file = FileAccess::open(p_path, FileAccess::WRITE);
    ERR_FAIL_COND_V_MSG(!file.is_valid(), FAILED,
        "GraphSerializer: Cannot open file for writing: " + p_path);

    file->store_string(json_text);
    file->close();
    return OK;
}

// ---- Load ----

ShaderGraphDocument *GraphSerializer::load(const String &p_path) {
    Ref<FileAccess> file = FileAccess::open(p_path, FileAccess::READ);
    ERR_FAIL_COND_V_MSG(!file.is_valid(), nullptr,
        "GraphSerializer: Cannot open file for reading: " + p_path);

    String json_text = file->get_as_text();
    file->close();

    Ref<JSON> json;
    json.instantiate();
    Error err = json->parse(json_text);
    if (err != OK) {
        String msg = "GraphSerializer: JSON parse error in file: ";
        msg += p_path; msg += " -- "; msg += json->get_error_message();
        ERR_FAIL_V_MSG(nullptr, msg);
    }

    Variant parsed = json->get_data();
    if (parsed.get_type() != Variant::DICTIONARY) {
        String msg = "GraphSerializer: Root element is not a Dictionary in: ";
        msg += p_path;
        ERR_FAIL_V_MSG(nullptr, msg);
    }

    Dictionary d = parsed;

    // Version migration
    int file_version = d.has("format_version") ? (int)d["format_version"] : 0;
    if (file_version < CURRENT_FORMAT_VERSION) {
        d = migrate(d, file_version, CURRENT_FORMAT_VERSION);
    }

    return _dict_to_document(d);
}

// ---- Migration ----

Dictionary GraphSerializer::migrate(Dictionary p_dict, int p_from_version, int p_to_version) {
    // No migrations needed yet (format_version 1 is the initial version).
    // Future migrations will be added here as version bumps occur.
    return p_dict;
}

// ---- Bindings ----

void GraphSerializer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("save", "document", "path"), &GraphSerializer::save);
    ClassDB::bind_method(D_METHOD("load", "path"), &GraphSerializer::load);
}
