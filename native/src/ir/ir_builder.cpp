#include "ir_builder.h"

#include "../types/type_system.h"

#include <algorithm>
#include <unordered_set>
#include <queue>
#include <functional>

using namespace godot;
using namespace sgs;

// ---- Topological sort ----
// Kahn's algorithm. Tie-break by node ID for determinism.

std::vector<String> IRBuilder::topological_sort(ShaderGraphDocument *p_doc) {
    Array nodes = p_doc->get_all_nodes();
    Array edges = p_doc->get_all_edges();

    // in-degree map and adjacency (from → to for data flow direction)
    std::unordered_map<std::string, int> in_degree;
    std::unordered_map<std::string, std::vector<std::string>> adj; // from → [to]

    for (int i = 0; i < nodes.size(); i++) {
        Ref<ShaderGraphNodeInstance> node = nodes[i];
        if (!node.is_valid()) continue;
        std::string id = node->get_id().utf8().get_data();
        in_degree[id] = 0;
        adj[id] = {};
    }
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (!edge.is_valid()) continue;
        std::string from = edge->get_from_node_id().utf8().get_data();
        std::string to   = edge->get_to_node_id().utf8().get_data();
        adj[from].push_back(to);
        in_degree[to]++;
    }

    // Priority queue (min-heap by ID string for determinism)
    auto cmp = [](const std::string &a, const std::string &b) { return a > b; };
    std::priority_queue<std::string, std::vector<std::string>, decltype(cmp)> q(cmp);

    for (const auto &pair : in_degree) {
        if (pair.second == 0) q.push(pair.first);
    }

    std::vector<String> sorted;
    while (!q.empty()) {
        std::string curr = q.top(); q.pop();
        sorted.push_back(String(curr.c_str()));

        // Sort neighbors for determinism before processing
        std::vector<std::string> neighbors = adj[curr];
        std::sort(neighbors.begin(), neighbors.end());

        for (const auto &neighbor : neighbors) {
            in_degree[neighbor]--;
            if (in_degree[neighbor] == 0) {
                q.push(neighbor);
            }
        }
    }
    return sorted;
}

// ---- Assign output variables ----

std::unordered_map<std::string, IRValue> IRBuilder::assign_output_vars(
    const std::vector<String> &sorted_ids,
    ShaderGraphDocument *p_doc,
    NodeRegistry *p_registry)
{
    std::unordered_map<std::string, IRValue> var_map;
    int counter = 0;

    for (const String &node_id : sorted_ids) {
        Ref<ShaderGraphNodeInstance> node = p_doc->get_node(node_id);
        if (!node.is_valid()) continue;

        ShaderNodeDefinition *def = p_registry->get_definition(node->get_definition_id());
        if (!def) continue;

        for (const auto &port : def->get_outputs_native()) {
            std::string key = node_id.utf8().get_data() + std::string("::") + port.id.utf8().get_data();
            IRValue val;
            val.var_name = String("_t") + String::num_int64(counter++);
            val.type     = port.type;
            var_map[key] = val;
        }
    }
    return var_map;
}

// ---- Collect uniforms ----

std::vector<IRUniform> IRBuilder::collect_uniforms(ShaderGraphDocument *p_doc, NodeRegistry *p_registry) {
    std::vector<IRUniform> uniforms;
    Array params = p_doc->get_parameters();

    for (int i = 0; i < params.size(); i++) {
        Dictionary param = params[i];
        IRUniform u;
        u.name = param.get("name", "");
        String type_str = param.get("type", "float");

        if (type_str == "float")   u.type = ShaderType::FLOAT;
        else if (type_str == "vec4" || type_str == "color") u.type = ShaderType::VEC4;
        else if (type_str == "vec3") u.type = ShaderType::VEC3;
        else if (type_str == "vec2") u.type = ShaderType::VEC2;
        else if (type_str == "sampler2D") u.type = ShaderType::SAMPLER2D;
        else u.type = ShaderType::FLOAT;

        if (type_str == "color") u.glsl_hint = " : source_color";

        uniforms.push_back(u);
    }
    return uniforms;
}

// ---- Build the full IRGraph ----

IRGraph IRBuilder::build(ShaderGraphDocument *p_doc,
                          NodeRegistry *p_registry,
                          const ValidationResult &p_validation)
{
    IRGraph ir;
    ir.shader_domain = p_doc->get_shader_domain();

    // 1. Topological sort
    std::vector<String> sorted = topological_sort(p_doc);

    // 2. Assign output variable names
    auto var_map = assign_output_vars(sorted, p_doc, p_registry);

    // 3. Build a quick edge lookup: to_node+port → from output IRValue
    // edge: from_node::from_port → to_node::to_port
    // We need: given (to_node_id, to_port_id) → IRValue of the connected output
    std::unordered_map<std::string, IRValue> input_lookup; // "to_node_id::to_port_id" → IRValue
    Array edges = p_doc->get_all_edges();
    for (int i = 0; i < edges.size(); i++) {
        Ref<ShaderGraphEdge> edge = edges[i];
        if (!edge.is_valid()) continue;
        std::string from_key = edge->get_from_node_id().utf8().get_data()
                             + std::string("::") + edge->get_from_port_id().utf8().get_data();
        std::string to_key   = edge->get_to_node_id().utf8().get_data()
                             + std::string("::") + edge->get_to_port_id().utf8().get_data();
        auto it = var_map.find(from_key);
        if (it != var_map.end()) {
            input_lookup[to_key] = it->second;
        }
    }

    // 4. Collect uniforms
    ir.uniforms = collect_uniforms(p_doc, p_registry);

    // 5. Build IR nodes and split into stages
    for (const String &node_id : sorted) {
        Ref<ShaderGraphNodeInstance> node = p_doc->get_node(node_id);
        if (!node.is_valid()) continue;

        ShaderNodeDefinition *def = p_registry->get_definition(node->get_definition_id());
        if (!def) continue;

        IRNode ir_node;
        ir_node.node_id         = node_id;
        ir_node.definition_id   = node->get_definition_id();
        ir_node.compiler_template = def->get_compiler_template();
        ir_node.properties      = node->get_properties();
        ir_node.stage           = node->get_stage_scope();

        // Resolve inputs
        for (const auto &port : def->get_inputs_native()) {
            std::string to_key = node_id.utf8().get_data() + std::string("::") + port.id.utf8().get_data();
            auto it = input_lookup.find(to_key);
            if (it != input_lookup.end()) {
                ir_node.resolved_inputs[port.id.utf8().get_data()] = it->second;
            } else {
                // Unconnected optional port — use default value as a GLSL literal
                IRValue default_val;
                default_val.type = port.type;
                String glsl_type = TypeSystem::type_to_glsl(port.type);

                // Produce a literal from the default_value
                if (port.default_value.get_type() == Variant::FLOAT) {
                    float f = port.default_value;
                    default_val.var_name = String::num(f);
                } else if (port.default_value.get_type() == Variant::INT) {
                    int iv = port.default_value;
                    default_val.var_name = String::num_int64(iv);
                    default_val.var_name += ".0";
                } else {
                    // Fallback: type-appropriate zero
                    if (glsl_type == "float") default_val.var_name = "0.0";
                    else if (glsl_type == "vec2") default_val.var_name = "vec2(0.0)";
                    else if (glsl_type == "vec3") default_val.var_name = "vec3(0.0)";
                    else if (glsl_type == "vec4") default_val.var_name = "vec4(0.0)";
                    else default_val.var_name = "0.0";
                }
                ir_node.resolved_inputs[port.id.utf8().get_data()] = default_val;
            }
        }

        // Assign output vars
        for (const auto &port : def->get_outputs_native()) {
            std::string key = node_id.utf8().get_data() + std::string("::") + port.id.utf8().get_data();
            auto it = var_map.find(key);
            if (it != var_map.end()) {
                ir_node.output_vars[port.id.utf8().get_data()] = it->second;
            }
        }

        // Stage assignment: fragment-only → fragment, vertex-only → vertex, any → fragment (default)
        String scope = node->get_stage_scope();
        bool is_vertex_node = (scope == "vertex") ||
                              (def->get_stage_support() == STAGE_VERTEX);

        if (is_vertex_node) {
            ir.vertex_nodes.push_back(ir_node);
        } else {
            ir.fragment_nodes.push_back(ir_node);
        }
    }

    return ir;
}
