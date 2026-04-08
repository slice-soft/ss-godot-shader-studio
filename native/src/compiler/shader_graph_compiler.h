#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/dictionary.hpp>

#include "compile_result.h"
#include "../graph/shader_graph_document.h"
#include "../registry/node_registry.h"

using namespace godot;

class ShaderGraphCompiler : public Object {
    GDCLASS(ShaderGraphCompiler, Object)

public:
    ShaderGraphCompiler() = default;

    // Full pipeline: validation → IR → backend emit.
    // Automatically selects backend based on document's shader_domain.
    sgs::CompileResult compile(ShaderGraphDocument *p_doc, NodeRegistry *p_registry);

    // GDScript-friendly wrapper: returns Dictionary { success, shader_code, issues[] }
    // Gets NodeRegistry singleton automatically.
    Dictionary compile_gd(ShaderGraphDocument *p_doc);

    // Header banner prepended to every generated file.
    static String make_file_banner(const String &p_source_path, const String &p_compiler_version);

protected:
    static void _bind_methods();
};
