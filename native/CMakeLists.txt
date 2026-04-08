cmake_minimum_required(VERSION 3.22)
project(ss_godot_shader_studio)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ---- godot-cpp submodule ----
set(GODOT_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/godot-cpp")
add_subdirectory(${GODOT_CPP_DIR} godot-cpp)

# ---- Source files ----
set(SOURCES
    # Core
    src/core/register_types.cpp

    # Graph model
    src/graph/shader_graph_document.cpp
    src/graph/shader_graph_node_instance.cpp
    src/graph/shader_graph_edge.cpp

    # Type system
    src/types/type_system.cpp

    # Registry
    src/registry/shader_node_definition.cpp
    src/registry/node_registry.cpp
    src/registry/stdlib/stdlib_math.cpp
    src/registry/stdlib/stdlib_trig.cpp
    src/registry/stdlib/stdlib_vector.cpp
    src/registry/stdlib/stdlib_float_ops.cpp
    src/registry/stdlib/stdlib_swizzle.cpp
    src/registry/stdlib/stdlib_color.cpp
    src/registry/stdlib/stdlib_uv.cpp
    src/registry/stdlib/stdlib_texture.cpp
    src/registry/stdlib/stdlib_input.cpp
    src/registry/stdlib/stdlib_parameters.cpp
    src/registry/stdlib/stdlib_output.cpp
    src/registry/stdlib/stdlib_registration.cpp

    # Validation
    src/validation/validation_engine.cpp

    # IR
    src/ir/ir_builder.cpp

    # Compiler
    src/compiler/emit_backend_spatial.cpp
    src/compiler/shader_graph_compiler.cpp

    # Serializer
    src/serializer/graph_serializer.cpp
)

# ---- Shared library ----
add_library(${PROJECT_NAME} SHARED ${SOURCES})

target_include_directories(${PROJECT_NAME} PRIVATE
    src
    ${GODOT_CPP_DIR}/include
    ${GODOT_CPP_DIR}/gen/include
)

target_link_libraries(${PROJECT_NAME} PRIVATE godot-cpp)

# ---- Output directory ----
set_target_properties(${PROJECT_NAME} PROPERTIES
    LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../addons/ss_godot_shader_studio/gdextension/bin"
    RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../addons/ss_godot_shader_studio/gdextension/bin"
)

# ---- Platform-specific suffix ----
if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".linux.template_debug.x86_64.so")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".macos.template_debug.universal.dylib")
elseif(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set_target_properties(${PROJECT_NAME} PROPERTIES SUFFIX ".windows.template_debug.x86_64.dll")
endif()
