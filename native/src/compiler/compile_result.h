#pragma once

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/array.hpp>
#include <vector>
#include "../validation/validation_issue.h"

using namespace godot;

namespace sgs {

struct CompileResult {
    bool success = false;
    String shader_code;     // empty if success == false
    std::vector<ValidationIssue> issues;
    String compiler_version = "0.1.0";
    String source_uuid;

    bool has_errors() const {
        for (const auto &issue : issues) {
            if (issue.severity == IssueSeverity::ERROR) return true;
        }
        return false;
    }
};

} // namespace sgs
