#pragma once

#include <godot_cpp/variant/string.hpp>
#include <godot_cpp/variant/variant.hpp>

#include "shader_type.h"

using namespace godot;

namespace sgs {

struct PortDefinition {
    String id;
    String name;
    ShaderType type = ShaderType::FLOAT;
    Variant default_value;
    bool optional = false;
};

} // namespace sgs
