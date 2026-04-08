#pragma once

#include "validation_issue.h"
#include <vector>

namespace sgs {

struct ValidationResult {
    std::vector<ValidationIssue> issues;

    bool has_errors() const {
        for (const auto &issue : issues) {
            if (issue.severity == IssueSeverity::ERROR) return true;
        }
        return false;
    }

    std::vector<ValidationIssue> get_errors() const {
        std::vector<ValidationIssue> result;
        for (const auto &issue : issues) {
            if (issue.severity == IssueSeverity::ERROR) result.push_back(issue);
        }
        return result;
    }

    std::vector<ValidationIssue> get_warnings() const {
        std::vector<ValidationIssue> result;
        for (const auto &issue : issues) {
            if (issue.severity == IssueSeverity::WARNING) result.push_back(issue);
        }
        return result;
    }

    void add_error(const String &p_node_id, const String &p_port_id,
                   const String &p_message, const String &p_code = "") {
        issues.push_back({IssueSeverity::ERROR, p_node_id, p_port_id, p_message, p_code});
    }

    void add_warning(const String &p_node_id, const String &p_port_id,
                     const String &p_message, const String &p_code = "") {
        issues.push_back({IssueSeverity::WARNING, p_node_id, p_port_id, p_message, p_code});
    }
};

} // namespace sgs
