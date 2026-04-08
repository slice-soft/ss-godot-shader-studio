#pragma once

#include <godot_cpp/variant/string.hpp>
#include "../ir/ir_graph.h"

using namespace godot;

namespace sgs {

// Abstract base for all shader domain emitters.
// Each backend knows the shader_type declaration, built-in variables, and
// how to bind the output node's inputs to the correct Godot shader outputs.
class EmitBackend {
public:
    virtual ~EmitBackend() = default;

    // Emit the full .gdshader source from an IRGraph.
    virtual String emit(const IRGraph &ir) = 0;

    // The "shader_type xxx;" line.
    virtual String get_shader_type_declaration() = 0;

protected:
    // Substitutes {port_id} and {prop:key} placeholders in a template.
    // `inputs`  — port_id → variable name string
    // `outputs` — port_id → variable name string
    // `props`   — Dictionary of node instance properties
    static String substitute_template(const String &tpl,
                                       const std::unordered_map<std::string, IRValue> &inputs,
                                       const std::unordered_map<std::string, IRValue> &outputs,
                                       const Dictionary &props);

    // Emit all nodes in the given list into a code block string.
    static String emit_nodes(const std::vector<IRNode> &nodes);

    // Emit uniform declarations (sorted alphabetically for determinism).
    static String emit_uniforms(const std::vector<IRUniform> &uniforms);

    // Emit varying declarations (sorted alphabetically).
    static String emit_varyings(const std::vector<IRVarying> &varyings);
};

} // namespace sgs
