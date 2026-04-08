#pragma once

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/dictionary.hpp>

#include "ir_types.h"

#include <unordered_map>
#include <string>

using namespace godot;

namespace sgs {

// An IR node represents one shader graph node with all ports resolved to
// concrete GLSL variable names. Ready for template substitution by the emitter.
struct IRNode {
    String node_id;
    String definition_id;

    // input port_id → IRValue (the variable that feeds into this port)
    std::unordered_map<std::string, IRValue> resolved_inputs;

    // output port_id → IRValue (the new variable produced by this node)
    std::unordered_map<std::string, IRValue> output_vars;

    // The compiler_template from the definition, ready for substitution
    String compiler_template;

    // Properties from the node instance (used for template substitution of {prop:...})
    Dictionary properties;

    // Which stage this node belongs to
    String stage; // "vertex" | "fragment" | "any"
};

} // namespace sgs
