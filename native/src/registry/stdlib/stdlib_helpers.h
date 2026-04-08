#pragma once

// Convenience macros for building ShaderNodeDefinition objects concisely
// in stdlib registration functions.
//
// Usage:
//   BEGIN_DEF(math/add, "Add", "Math")
//   KEYWORDS("add", "sum", "plus", "+")
//   INPUT_PORT(a, "A", FLOAT, 0.0f)
//   INPUT_PORT(b, "B", FLOAT, 0.0f)
//   OUTPUT_PORT(result, "Result", FLOAT)
//   TEMPLATE("float {result} = {a} + {b};")
//   STAGE(STAGE_ANY) SGS_DOMAIN(DOMAIN_ALL)
//   END_DEF(registry)

#include "../shader_node_definition.h"
#include "../node_registry.h"
#include "../../types/shader_type.h"
#include "../../graph/shader_domain.h"

#include <godot_cpp/variant/packed_string_array.hpp>
using namespace godot;
using namespace sgs;

// ---- Port builder helpers ----

inline sgs::PortDefinition make_port(const char *p_id, const char *p_name,
                                     sgs::ShaderType p_type,
                                     Variant p_default = Variant(),
                                     bool p_optional = false) {
    sgs::PortDefinition pd;
    pd.id            = p_id;
    pd.name          = p_name;
    pd.type          = p_type;
    pd.default_value = p_default;
    pd.optional      = p_optional;
    return pd;
}

// ---- Definition builder macros ----

#define BEGIN_DEF(def_id_str, def_name, def_cat)             \
    {                                                         \
        ShaderNodeDefinition *_def = memnew(ShaderNodeDefinition); \
        _def->set_id(def_id_str);                            \
        _def->set_display_name(def_name);                    \
        _def->set_category(def_cat);                         \
        std::vector<sgs::PortDefinition> _inputs, _outputs;

#define KEYWORDS(...)                                         \
        {                                                     \
            PackedStringArray _kw;                           \
            for (const char *k : {__VA_ARGS__}) _kw.push_back(k); \
            _def->set_keywords(_kw);                         \
        }

#define INPUT(id_str, name_str, type_enum, def_val)          \
        _inputs.push_back(make_port(id_str, name_str, sgs::ShaderType::type_enum, def_val));

#define INPUT_OPT(id_str, name_str, type_enum, def_val)      \
        _inputs.push_back(make_port(id_str, name_str, sgs::ShaderType::type_enum, def_val, true));

#define OUTPUT(id_str, name_str, type_enum)                  \
        _outputs.push_back(make_port(id_str, name_str, sgs::ShaderType::type_enum));

#define TEMPLATE(tpl_str)                                     \
        _def->set_compiler_template(tpl_str);

#define STAGE(flag)                                           \
        _def->set_stage_support(flag);

// SGS_DOMAIN avoids collision with math.h's #define DOMAIN 1 on macOS
#define SGS_DOMAIN(flag)                                      \
        _def->set_domain_support(flag);

#define PREVIEW(policy)                                       \
        _def->set_preview_policy(PreviewPolicy::policy);

#define END_DEF(registry_ptr)                                 \
        _def->set_inputs_native(_inputs);                    \
        _def->set_outputs_native(_outputs);                  \
        (registry_ptr)->register_definition(_def);           \
    }
