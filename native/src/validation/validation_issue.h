#pragma once

#include <godot_cpp/variant/string.hpp>

using namespace godot;

namespace sgs {

enum class IssueSeverity {
    INFO    = 0,
    WARNING = 1,
    ERROR   = 2,
};

struct ValidationIssue {
    IssueSeverity severity = IssueSeverity::ERROR;
    String node_id;     // empty if document-level
    String port_id;     // empty if node-level
    String message;
    String code;        // e.g. "E001", "W002"
};

} // namespace sgs
