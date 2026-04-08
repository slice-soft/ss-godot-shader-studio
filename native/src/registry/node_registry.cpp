#include "node_registry.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include <algorithm>

using namespace godot;

NodeRegistry *NodeRegistry::_singleton = nullptr;

NodeRegistry *NodeRegistry::get_singleton() {
    return _singleton;
}

void NodeRegistry::register_definition(ShaderNodeDefinition *p_def) {
    ERR_FAIL_NULL(p_def);

    std::string id = p_def->get_id().utf8().get_data();
    if (_definitions.count(id)) {
        UtilityFunctions::push_warning("NodeRegistry: overwriting definition for id: " + p_def->get_id());
    }

    Ref<ShaderNodeDefinition> ref(p_def);
    _definitions[id] = ref;

    std::string cat = p_def->get_category().utf8().get_data();
    _by_category[cat].push_back(id);
}

ShaderNodeDefinition *NodeRegistry::get_definition(const String &p_id) const {
    auto it = _definitions.find(p_id.utf8().get_data());
    if (it != _definitions.end()) {
        return it->second.ptr();
    }
    return nullptr;
}

Array NodeRegistry::get_all_in_category(const String &p_category) const {
    Array result;
    auto it = _by_category.find(p_category.utf8().get_data());
    if (it != _by_category.end()) {
        for (const auto &id : it->second) {
            auto dit = _definitions.find(id);
            if (dit != _definitions.end()) {
                result.push_back(dit->second);
            }
        }
    }
    return result;
}

Array NodeRegistry::search(const String &p_query) const {
    Array result;
    if (p_query.is_empty()) {
        return get_all_definitions();
    }
    String query_lower = p_query.to_lower();
    for (const auto &pair : _definitions) {
        Ref<ShaderNodeDefinition> def = pair.second;
        bool match = false;

        if (def->get_id().to_lower().contains(query_lower)) {
            match = true;
        } else if (def->get_display_name().to_lower().contains(query_lower)) {
            match = true;
        } else {
            PackedStringArray kw = def->get_keywords();
            for (int i = 0; i < kw.size(); i++) {
                if (kw[i].to_lower().contains(query_lower)) {
                    match = true;
                    break;
                }
            }
        }
        if (match) {
            result.push_back(def);
        }
    }
    return result;
}

PackedStringArray NodeRegistry::get_categories() const {
    PackedStringArray cats;
    for (const auto &pair : _by_category) {
        cats.push_back(String(pair.first.c_str()));
    }
    cats.sort();
    return cats;
}

Array NodeRegistry::get_all_definitions() const {
    Array result;
    for (const auto &pair : _definitions) {
        result.push_back(pair.second);
    }
    return result;
}

void NodeRegistry::_bind_methods() {
    ClassDB::bind_method(D_METHOD("register_definition", "definition"), &NodeRegistry::register_definition);
    ClassDB::bind_method(D_METHOD("get_definition", "id"), &NodeRegistry::get_definition);
    ClassDB::bind_method(D_METHOD("get_all_in_category", "category"), &NodeRegistry::get_all_in_category);
    ClassDB::bind_method(D_METHOD("search", "query"), &NodeRegistry::search);
    ClassDB::bind_method(D_METHOD("get_categories"), &NodeRegistry::get_categories);
    ClassDB::bind_method(D_METHOD("get_all_definitions"), &NodeRegistry::get_all_definitions);
}
