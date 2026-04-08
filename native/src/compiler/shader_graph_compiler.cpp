#include "shader_graph_compiler.h"

#include "../validation/validation_engine.h"
#include "../ir/ir_builder.h"
#include "emit_backend_spatial.h"

#include <godot_cpp/classes/engine.hpp>
#include <godot_cpp/variant/array.hpp>
#include <memory>

using namespace godot;
using namespace sgs;

sgs::CompileResult ShaderGraphCompiler::compile(ShaderGraphDocument *p_doc, NodeRegistry *p_registry) {
    CompileResult result;
    result.source_uuid = p_doc->get_uuid();

    // ---- Validation ----
    ValidationEngine *validator = memnew(ValidationEngine);
    ValidationResult validation = validator->validate(p_doc, p_registry);
    result.issues = validation.issues;
    memdelete(validator);

    if (validation.has_errors()) {
        result.success = false;
        return result;
    }

    // ---- IR Build ----
    IRGraph ir = IRBuilder::build(p_doc, p_registry, validation);

    // ---- Select backend ----
    String domain = p_doc->get_shader_domain();
    std::unique_ptr<EmitBackend> backend;

    if (domain == "spatial") {
        backend = std::make_unique<EmitBackendSpatial>();
    } else {
        ValidationIssue issue;
        issue.severity = IssueSeverity::ERROR;
        issue.message  = "Unsupported shader domain: '";
        issue.message += domain;
        issue.message += "'. Only 'spatial' is available in Phase A.";
        issue.code     = "E100";
        result.issues.push_back(issue);
        result.success = false;
        return result;
    }

    // ---- Emit ----
    String body = backend->emit(ir);

    // ---- Assemble final file ----
    String header = make_file_banner(p_doc->get_name(), result.compiler_version);
    String shader_type = backend->get_shader_type_declaration();

    result.shader_code = header;
    result.shader_code += shader_type;
    result.shader_code += "\n\n";
    result.shader_code += body;
    result.success = true;
    return result;
}

String ShaderGraphCompiler::make_file_banner(const String &p_source_path, const String &p_compiler_version) {
    String banner = "// ============================================================\n";
    banner += "// GENERATED FILE — DO NOT EDIT MANUALLY\n";
    banner += "// Source: ";
    banner += p_source_path;
    banner += "\n// Compiled by: Godot Shader Studio ";
    banner += p_compiler_version;
    banner += "\n// ============================================================\n";
    return banner;
}

Dictionary ShaderGraphCompiler::compile_gd(ShaderGraphDocument *p_doc) {
    Dictionary result_dict;

    NodeRegistry *registry = Object::cast_to<NodeRegistry>(
        Engine::get_singleton()->get_singleton("NodeRegistry"));

    if (!registry) {
        result_dict["success"] = false;
        result_dict["shader_code"] = String();
        result_dict["issues"] = Array();
        return result_dict;
    }

    CompileResult result = compile(p_doc, registry);

    result_dict["success"] = result.success;
    result_dict["shader_code"] = result.shader_code;

    Array issues_arr;
    for (const auto &issue : result.issues) {
        Dictionary d;
        d["severity"] = (int)issue.severity;
        d["node_id"]  = issue.node_id;
        d["port_id"]  = issue.port_id;
        d["message"]  = issue.message;
        d["code"]     = issue.code;
        issues_arr.push_back(d);
    }
    result_dict["issues"] = issues_arr;

    return result_dict;
}

void ShaderGraphCompiler::_bind_methods() {
    ClassDB::bind_method(D_METHOD("compile_gd", "document"), &ShaderGraphCompiler::compile_gd);
}
