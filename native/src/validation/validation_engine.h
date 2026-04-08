#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/array.hpp>

#include "validation_result.h"
#include "../graph/shader_graph_document.h"
#include "../registry/node_registry.h"

using namespace godot;

class ValidationEngine : public Object {
    GDCLASS(ValidationEngine, Object)

public:
    ValidationEngine() = default;

    // Main entry point. Runs all passes in order.
    // Stops early if a pass produces errors that would make later passes meaningless.
    sgs::ValidationResult validate(ShaderGraphDocument *p_doc, NodeRegistry *p_registry);

    // Individual passes — public so they can be unit-tested independently.
    void pass_structural(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, sgs::ValidationResult &result);
    void pass_typing(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, sgs::ValidationResult &result);
    void pass_stage(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, sgs::ValidationResult &result);
    void pass_cycles(ShaderGraphDocument *p_doc, sgs::ValidationResult &result);
    void pass_outputs(ShaderGraphDocument *p_doc, NodeRegistry *p_registry, sgs::ValidationResult &result);

protected:
    static void _bind_methods();
};
