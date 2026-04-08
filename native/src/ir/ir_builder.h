#pragma once

#include "ir_graph.h"
#include "../graph/shader_graph_document.h"
#include "../registry/node_registry.h"
#include "../validation/validation_result.h"

namespace sgs {

class IRBuilder {
public:
    IRBuilder() = delete;

    // Builds an IRGraph from a validated document.
    // `validation_result` must have no errors before calling this.
    static IRGraph build(ShaderGraphDocument *p_doc,
                         NodeRegistry *p_registry,
                         const ValidationResult &p_validation);

private:
    // Returns nodes in topological order (all inputs before outputs).
    // Deterministic: tie-breaks by node ID lexicographic order.
    static std::vector<godot::String> topological_sort(ShaderGraphDocument *p_doc);

    // Assigns variable names to all output ports of the sorted nodes.
    // Returns a map: (node_id, port_id) → IRValue
    static std::unordered_map<std::string, IRValue> assign_output_vars(
        const std::vector<godot::String> &sorted_ids,
        ShaderGraphDocument *p_doc,
        NodeRegistry *p_registry);

    // Collects uniform declarations from parameter nodes.
    static std::vector<IRUniform> collect_uniforms(ShaderGraphDocument *p_doc,
                                                    NodeRegistry *p_registry);

    // Splits sorted nodes into vertex and fragment lists.
    static void split_stages(const std::vector<godot::String> &sorted_ids,
                              ShaderGraphDocument *p_doc,
                              NodeRegistry *p_registry,
                              const std::unordered_map<std::string, IRValue> &output_var_map,
                              ShaderGraphDocument *p_doc2,
                              IRGraph &ir);
};

} // namespace sgs
