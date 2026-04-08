#pragma once

#include "emit_backend.h"

namespace sgs {

class EmitBackendSpatial : public EmitBackend {
public:
    String emit(const IRGraph &ir) override;
    String get_shader_type_declaration() override { return "shader_type spatial;"; }
};

} // namespace sgs
