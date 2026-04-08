#pragma once

#include <godot_cpp/classes/object.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>

#include "../graph/shader_graph_document.h"

using namespace godot;

class GraphSerializer : public Object {
    GDCLASS(GraphSerializer, Object)

public:
    GraphSerializer() = default;

    // Save `p_doc` as pretty-printed JSON to `p_path`. Returns Godot Error code.
    int save(ShaderGraphDocument *p_doc, const String &p_path);

    // Load a .gshadergraph file from `p_path`. Returns nullptr on failure.
    ShaderGraphDocument *load(const String &p_path);

    // Run all needed migrations from `p_from_version` to current format version.
    // Returns the migrated Dictionary (may be the same object if no migration needed).
    static Dictionary migrate(Dictionary p_dict, int p_from_version, int p_to_version);

    static const int CURRENT_FORMAT_VERSION = 1;

protected:
    static void _bind_methods();

private:
    static Dictionary _document_to_dict(ShaderGraphDocument *p_doc);
    static ShaderGraphDocument *_dict_to_document(const Dictionary &p_dict);
};
