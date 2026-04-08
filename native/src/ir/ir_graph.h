#pragma once

#include "ir_node.h"
#include "ir_types.h"

#include <vector>

namespace sgs {

// The complete intermediate representation of a shader graph.
// Produced by IRBuilder after successful validation.
struct IRGraph {
    // Topologically sorted nodes split by stage
    std::vector<IRNode> vertex_nodes;
    std::vector<IRNode> fragment_nodes;

    // Uniforms collected from parameter nodes
    std::vector<IRUniform> uniforms;

    // Varyings needed for vertex → fragment data passing
    std::vector<IRVarying> varyings;

    // Any helper function code that should be emitted before the stages
    std::vector<godot::String> helper_functions;

    // Shader domain string from the document
    godot::String shader_domain;
};

} // namespace sgs
