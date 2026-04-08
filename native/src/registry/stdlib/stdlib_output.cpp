#include "stdlib_output.h"
#include "stdlib_helpers.h"

using namespace sgs;

// Output nodes are handled specially by the EmitBackend — they write directly
// to built-in Godot shader outputs (ALBEDO, ROUGHNESS, etc.). The template is
// used only for type checking and variable wiring; the backend overrides emission.

void register_stdlib_output(NodeRegistry *registry) {
    BEGIN_DEF("output/spatial", "Spatial Output", "Output")
    KEYWORDS("output", "spatial output", "material output", "pbr output")
    INPUT_OPT("albedo",     "Albedo",     VEC3,  Variant())
    INPUT_OPT("roughness",  "Roughness",  FLOAT, 0.5f)
    INPUT_OPT("metallic",   "Metallic",   FLOAT, 0.0f)
    INPUT_OPT("emission",   "Emission",   VEC3,  Variant())
    INPUT_OPT("normal_map", "Normal Map", VEC3,  Variant())
    INPUT_OPT("alpha",      "Alpha",      FLOAT, 1.0f)
    INPUT_OPT("ao",         "AO",         FLOAT, 1.0f)
    // No outputs — this is the terminal node
    TEMPLATE(
        "ALBEDO = {albedo};\n"
        "ROUGHNESS = {roughness};\n"
        "METALLIC = {metallic};\n"
        "EMISSION = {emission};\n"
        "NORMAL_MAP = {normal_map};\n"
        "ALPHA = {alpha};\n"
        "AO = {ao};"
    )
    STAGE(STAGE_FRAGMENT) SGS_DOMAIN(DOMAIN_SPATIAL)
    PREVIEW(NONE)
    END_DEF(registry)
}
