@tool
class_name ShaderGraphResource
extends Resource

## Thin wrapper produced by the EditorImportPlugin for .gshadergraph files.
## Stores the original source path so the editor panel can load it.
@export var source_path: String = ""
