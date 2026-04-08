#include "register_types.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>
#include <godot_cpp/classes/engine.hpp>

#include "../graph/shader_graph_document.h"
#include "../graph/shader_graph_node_instance.h"
#include "../graph/shader_graph_edge.h"
#include "../registry/shader_node_definition.h"
#include "../registry/node_registry.h"
#include "../registry/stdlib/stdlib_registration.h"
#include "../validation/validation_engine.h"
#include "../compiler/shader_graph_compiler.h"
#include "../serializer/graph_serializer.h"

using namespace godot;

static NodeRegistry *_node_registry_singleton = nullptr;

void initialize_ss_godot_shader_studio_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    // Register all GDExtension classes
    ClassDB::register_class<ShaderGraphDocument>();
    ClassDB::register_class<ShaderGraphNodeInstance>();
    ClassDB::register_class<ShaderGraphEdge>();
    ClassDB::register_class<ShaderNodeDefinition>();
    ClassDB::register_class<NodeRegistry>();
    ClassDB::register_class<ValidationEngine>();
    ClassDB::register_class<ShaderGraphCompiler>();
    ClassDB::register_class<GraphSerializer>();

    // Create and register the NodeRegistry singleton
    _node_registry_singleton = memnew(NodeRegistry);
    Engine::get_singleton()->register_singleton("NodeRegistry", _node_registry_singleton);

    // Register all built-in node definitions
    register_stdlib(_node_registry_singleton);
}

void uninitialize_ss_godot_shader_studio_module(ModuleInitializationLevel p_level) {
    if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
        return;
    }

    // Unregister singleton
    Engine::get_singleton()->unregister_singleton("NodeRegistry");
    if (_node_registry_singleton) {
        memdelete(_node_registry_singleton);
        _node_registry_singleton = nullptr;
    }
}

extern "C" {

GDExtensionBool GDE_EXPORT ss_godot_shader_studio_init(
    GDExtensionInterfaceGetProcAddress p_get_proc_address,
    const GDExtensionClassLibraryPtr p_library,
    GDExtensionInitialization *r_initialization)
{
    godot::GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

    init_obj.register_initializer(initialize_ss_godot_shader_studio_module);
    init_obj.register_terminator(uninitialize_ss_godot_shader_studio_module);
    init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

    return init_obj.init();
}

} // extern "C"
