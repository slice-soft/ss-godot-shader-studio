#include "validation_engine.h"

#include "../types/type_system.h"

#include <unordered_map>
#include <unordered_set>
#include <vector>
#include <string>
#include <stack>

using namespace godot;
using namespace sgs;

// ---- Main entry ----

ValidationResult ValidationEngine::validate(ShaderGraphDocument *p_doc, NodeRegistry *p_registry) {
    ValidationResult result;

    pass_structural(p_doc, p_registry, result);
    if (result.has_errors()) return result;

    pass_typing(p_doc, p_registry, result);
    if (result.has_errors()) return result;

    pass_stage(p_doc, p_registry, result);
    pass_cycles(p_doc, result);
    pass_outputs(p_doc, p_registry, result);

    return result;
}

// ---- Pass 1: Structural ----

void ValidationEngine::pass_structural(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, ValidationResult &result) {
    Array nodes = p_doc->get_all_nodes();
    Array edges = p_doc->get_all_edges();

    // Collect all node ids
    std::unordered_set<std::string> node_ids;
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) {
            result.add_error("", "", "Null node in document", "E001");
            continue;
        }
        std::string id = node->get_id().utf8().get_data();
        if (node_ids.count(id)) {
            result.add_error(node->get_id(), "", "Duplicate node id: " + node->get_id(), "E002");
        }
        node_ids.insert(id);

        // Check definition exists
        ShaderNodeDefinition *def = p_registry->get_definition(node->get_definition_id());
        if (!def) {
            String msg = "Unknown definition_id: '";
            msg += node->get_definition_id();
            msg += "'";
            result.add_error(node->get_id(), "", msg, "E003");
        }
    }

    // Validate edges
    std::unordered_set<std::string> edge_ids;
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (!edge.is_valid()) {
            result.add_error("", "", "Null edge in document", "E004");
            continue;
        }

        std::string eid = edge->get_id().utf8().get_data();
        if (edge_ids.count(eid)) {
            String msg = "Duplicate edge id: "; msg += edge->get_id();
            result.add_error("", "", msg, "E005");
        }
        edge_ids.insert(eid);

        if (!node_ids.count(edge->get_from_node_id().utf8().get_data())) {
            String msg = "Edge from_node_id references unknown node: "; msg += edge->get_from_node_id();
            result.add_error("", "", msg, "E006");
        }
        if (!node_ids.count(edge->get_to_node_id().utf8().get_data())) {
            String msg = "Edge to_node_id references unknown node: "; msg += edge->get_to_node_id();
            result.add_error("", "", msg, "E007");
        }

        // Validate ports exist on their definitions
        if (!result.has_errors()) {
            ShaderNodeDefinition *from_def = p_registry->get_definition(
                p_doc->get_node(edge->get_from_node_id())->get_definition_id());
            ShaderNodeDefinition *to_def = p_registry->get_definition(
                p_doc->get_node(edge->get_to_node_id())->get_definition_id());

            if (from_def) {
                bool found = false;
                for (const auto &port : from_def->get_outputs_native()) {
                    if (port.id == edge->get_from_port_id()) { found = true; break; }
                }
                if (!found) {
                    String msg = "Edge references unknown output port '";
                    msg += edge->get_from_port_id(); msg += "'";
                    result.add_error(edge->get_from_node_id(), edge->get_from_port_id(), msg, "E008");
                }
            }
            if (to_def) {
                bool found = false;
                for (const auto &port : to_def->get_inputs_native()) {
                    if (port.id == edge->get_to_port_id()) { found = true; break; }
                }
                if (!found) {
                    String msg = "Edge references unknown input port '";
                    msg += edge->get_to_port_id(); msg += "'";
                    result.add_error(edge->get_to_node_id(), edge->get_to_port_id(), msg, "E009");
                }
            }
        }
    }
}

// ---- Pass 2: Typing ----

void ValidationEngine::pass_typing(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, ValidationResult &result) {
    Array edges = p_doc->get_all_edges();

    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (!edge.is_valid()) continue;

        Ref<ShaderGraphNodeInstance> from_node = p_doc->get_node(edge->get_from_node_id());
        Ref<ShaderGraphNodeInstance> to_node   = p_doc->get_node(edge->get_to_node_id());
        if (!from_node.is_valid() || !to_node.is_valid()) continue;

        ShaderNodeDefinition *from_def = p_registry->get_definition(from_node->get_definition_id());
        ShaderNodeDefinition *to_def   = p_registry->get_definition(to_node->get_definition_id());
        if (!from_def || !to_def) continue;

        ShaderType from_type = ShaderType::VOID;
        ShaderType to_type   = ShaderType::VOID;

        for (const auto &port : from_def->get_outputs_native()) {
            if (port.id == edge->get_from_port_id()) { from_type = port.type; break; }
        }
        for (const auto &port : to_def->get_inputs_native()) {
            if (port.id == edge->get_to_port_id()) { to_type = port.type; break; }
        }

        CastType cast = TypeSystem::get_cast_type(from_type, to_type);
        if (cast == CastType::INCOMPATIBLE) {
            String msg = "Incompatible types: ";
            msg += TypeSystem::type_to_display_name(from_type);
            msg += " -> ";
            msg += TypeSystem::type_to_display_name(to_type);
            result.add_error(edge->get_to_node_id(), edge->get_to_port_id(), msg, "E010");
        } else if (cast == CastType::IMPLICIT_TRUNCATE) {
            String msg = "Lossy cast: ";
            msg += TypeSystem::type_to_display_name(from_type);
            msg += " -> ";
            msg += TypeSystem::type_to_display_name(to_type);
            msg += " (truncation)";
            result.add_warning(edge->get_to_node_id(), edge->get_to_port_id(), msg, "W001");
        }
    }
}

// ---- Pass 3: Stage ----

void ValidationEngine::pass_stage(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, ValidationResult &result) {
    Array nodes = p_doc->get_all_nodes();
    Array edges = p_doc->get_all_edges();

    // Build node stage scope map
    std::unordered_map<std::string, std::string> node_scope;
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) continue;
        node_scope[node->get_id().utf8().get_data()] = node->get_stage_scope().utf8().get_data();
    }

    // Check definition stage support
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) continue;

        ShaderNodeDefinition *def = p_registry->get_definition(node->get_definition_id());
        if (!def) continue;

        std::string scope = node->get_stage_scope().utf8().get_data();
        if (scope == "vertex" && !def->supports_stage(STAGE_VERTEX)) {
            String msg = "Node '"; msg += node->get_definition_id(); msg += "' does not support vertex stage";
            result.add_error(node->get_id(), "", msg, "E011");
        } else if (scope == "fragment" && !def->supports_stage(STAGE_FRAGMENT)) {
            String msg = "Node '"; msg += node->get_definition_id(); msg += "' does not support fragment stage";
            result.add_error(node->get_id(), "", msg, "E012");
        }
    }
}

// ---- Pass 4: Cycle detection ----

void ValidationEngine::pass_cycles(ShaderGraphDocument *p_doc, ValidationResult &result) {
    Array nodes = p_doc->get_all_nodes();
    Array edges = p_doc->get_all_edges();

    // Build adjacency list (from_node → [to_node, ...])
    std::unordered_map<std::string, std::vector<std::string>> adj;
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) continue;
        adj[node->get_id().utf8().get_data()] = {};
    }
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (!edge.is_valid()) continue;
        adj[edge->get_from_node_id().utf8().get_data()].push_back(
            edge->get_to_node_id().utf8().get_data());
    }

    // DFS cycle detection
    enum class Color { WHITE, GRAY, BLACK };
    std::unordered_map<std::string, Color> color;
    for (auto &pair : adj) color[pair.first] = Color::WHITE;

    std::function<bool(const std::string &)> has_cycle = [&](const std::string &node) -> bool {
        color[node] = Color::GRAY;
        for (const auto &neighbor : adj[node]) {
            if (color[neighbor] == Color::GRAY) return true;
            if (color[neighbor] == Color::WHITE && has_cycle(neighbor)) return true;
        }
        color[node] = Color::BLACK;
        return false;
    };

    for (auto &pair : adj) {
        if (color[pair.first] == Color::WHITE) {
            if (has_cycle(pair.first)) {
                result.add_error("", "", "Graph contains a cycle — shader graphs must be acyclic", "E020");
                return;
            }
        }
    }
}

// ---- Pass 5: Output nodes ----

void ValidationEngine::pass_outputs(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, ValidationResult &result) {
    Array nodes = p_doc->get_all_nodes();
    String domain = p_doc->get_shader_domain();

    String required_output_id;
    if (domain == "spatial") {
        required_output_id = "output/spatial";
    }
    // Other domains: handled in Phase D

    if (required_output_id.is_empty()) return;

    bool found = false;
    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) continue;
        if (node->get_definition_id() == required_output_id) {
            found = true;
            break;
        }
    }

    if (!found) {
        String msg = "Document has no output node for domain '";
        msg += domain; msg += "'. Add a '"; msg += required_output_id; msg += "' node.";
        result.add_error("", "", msg, "E030");
    }
}

// ---- Bindings ----

void ValidationEngine::_bind_methods() {
    // These are not directly callable from GDScript in Phase A,
    // but registered for completeness.
}
