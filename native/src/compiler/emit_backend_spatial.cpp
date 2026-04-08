#include "emit_backend_spatial.h"
#include "../types/type_system.h"

#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/variant.hpp>
#include <algorithm>

using namespace godot;
using namespace sgs;

// ---- EmitBackend shared helpers ----

String EmitBackend::substitute_template(
    const String &tpl,
    const std::unordered_map<std::string, IRValue> &inputs,
    const std::unordered_map<std::string, IRValue> &outputs,
    const Dictionary &props)
{
    String result = tpl;

    // Substitute output port placeholders: {port_id}
    for (const auto &pair : outputs) {
        String placeholder = "{";
        placeholder += pair.first.c_str();
        placeholder += "}";
        result = result.replace(placeholder, pair.second.var_name);
    }

    // Substitute input port placeholders: {port_id}
    for (const auto &pair : inputs) {
        String placeholder = "{";
        placeholder += pair.first.c_str();
        placeholder += "}";
        result = result.replace(placeholder, pair.second.var_name);
    }

    // Substitute property placeholders: {prop:key}
    Array keys = props.keys();
    for (int i = 0; i < keys.size(); i++) {
        String key = keys[i];
        String placeholder = "{prop:";
        placeholder += key;
        placeholder += "}";
        Variant val = props.get(key, Variant());
        result = result.replace(placeholder, String(val));
    }

    return result;
}

String EmitBackend::emit_nodes(const std::vector<IRNode> &nodes) {
    String out;
    for (const auto &node : nodes) {
        String code = substitute_template(
            node.compiler_template,
            node.resolved_inputs,
            node.output_vars,
            node.properties);
        out += "\t";
        out += code.replace("\n", "\n\t");
        out += "\n";
    }
    return out;
}

String EmitBackend::emit_uniforms(const std::vector<IRUniform> &uniforms) {
    // Sort alphabetically for determinism
    std::vector<IRUniform> sorted = uniforms;
    std::sort(sorted.begin(), sorted.end(), [](const IRUniform &a, const IRUniform &b) {
        return a.name < b.name;
    });

    String out;
    for (const auto &u : sorted) {
        String type = TypeSystem::type_to_glsl(u.type);
        out += "uniform ";
        out += type;
        out += " ";
        out += u.name;
        out += u.glsl_hint;
        if (!u.default_value.is_empty()) {
            out += " = ";
            out += u.default_value;
        }
        out += ";\n";
    }
    return out;
}

String EmitBackend::emit_varyings(const std::vector<IRVarying> &varyings) {
    std::vector<IRVarying> sorted = varyings;
    std::sort(sorted.begin(), sorted.end(), [](const IRVarying &a, const IRVarying &b) {
        return a.name < b.name;
    });

    String out;
    for (const auto &v : sorted) {
        String type = TypeSystem::type_to_glsl(v.type);
        out += "varying ";
        out += type;
        out += " ";
        out += v.name;
        out += ";\n";
    }
    return out;
}

// ---- EmitBackendSpatial ----

String EmitBackendSpatial::emit(const IRGraph &ir) {
    String code;

    // Uniforms
    String uniforms = emit_uniforms(ir.uniforms);
    if (!uniforms.is_empty()) {
        code += uniforms;
        code += "\n";
    }

    // Varyings
    String varyings = emit_varyings(ir.varyings);
    if (!varyings.is_empty()) {
        code += varyings;
        code += "\n";
    }

    // Helper functions
    for (const String &helper : ir.helper_functions) {
        code += helper;
        code += "\n\n";
    }

    // Vertex stage (only emitted if there are vertex nodes)
    if (!ir.vertex_nodes.empty()) {
        code += "void vertex() {\n";
        code += emit_nodes(ir.vertex_nodes);
        code += "}\n\n";
    }

    // Fragment stage
    code += "void fragment() {\n";
    code += emit_nodes(ir.fragment_nodes);
    code += "}\n";

    return code;
}
