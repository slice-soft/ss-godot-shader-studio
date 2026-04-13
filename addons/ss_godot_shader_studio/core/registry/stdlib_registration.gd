## Registers all built-in node definitions into a NodeRegistry.
## Each category lives in its own file under nodes/ — add new nodes there.
class_name StdlibRegistration


static func register_all(registry: NodeRegistry) -> void:
	MathNodes.register(registry)
	TrigNodes.register(registry)
	VectorNodes.register(registry)
	LogicalNodes.register(registry)
	ColorNodes.register(registry)
	UVNodes.register(registry)
	TextureNodes.register(registry)
	InputNodes.register(registry)
	MatrixNodes.register(registry)
	ParameterNodes.register(registry)
	OutputNodes.register(registry)
	UtilityNodes.register(registry)
	EffectsNodes.register(registry)
