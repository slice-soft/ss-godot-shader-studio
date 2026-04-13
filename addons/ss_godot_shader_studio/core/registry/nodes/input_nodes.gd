## All shader input node definitions: built-ins, time, camera, surface, and domain-specific.
class_name InputNodes

static func register(r: NodeRegistry) -> void:
	_register_input(r)
	_register_time(r)
	_register_camera_screen(r)
	_register_surface_data(r)
	_register_object_transform(r)
	_register_canvas_item(r)
	_register_particles(r)
	_register_sky(r)
	_register_fog(r)


static func _def(id: String, name: String, cat: String,
		keywords: Array, inputs: Array, outputs: Array,
		template: String, stage: int, domain: int,
		helpers: Array[String] = [], auto_uni: Dictionary = {}) -> ShaderNodeDefinition:
	var d := ShaderNodeDefinition.new()
	d.id               = id
	d.display_name     = name
	d.category         = cat
	d.keywords         = keywords
	d.inputs           = inputs
	d.outputs          = outputs
	d.compiler_template = template
	d.stage_support    = stage
	d.domain_support   = domain
	d.helper_functions = helpers
	d.auto_uniform     = auto_uni
	return d


static func _p(id: String, name: String, type: int,
		default: Variant = null, optional: bool = false) -> Dictionary:
	return {"id": id, "name": name, "type": type, "default": default, "optional": optional}


# ---- Core Inputs ----

static func _register_input(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/time", "Time", "Input",
		["time","seconds","elapsed time","animation time"],
		[], [_p("time","Time",T.TIME)],
		"float {time} = TIME;", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("input/screen_uv", "Screen UV", "Input",
		["screen uv","screen coordinates","viewport uv"],
		[], [_p("uv","UV",T.SCREEN_UV)],
		"vec2 {uv} = SCREEN_UV;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	r.register_definition(_def("input/vertex_normal", "Vertex Normal", "Input",
		["normal","vertex normal","surface normal","object normal"],
		[], [_p("normal","Normal",T.NORMAL)],
		"vec3 {normal} = NORMAL;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("input/world_position", "World Position", "Input",
		["world position","vertex position","model matrix","position"],
		[], [_p("pos","Position",T.WORLD_POSITION)],
		"vec3 {pos} = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;",
		S.STAGE_VERTEX, S.DOMAIN_SPATIAL))

	r.register_definition(_def("input/view_direction", "View Direction", "Input",
		["view direction","camera direction","view vector","eye direction"],
		[], [_p("dir","Direction",T.VIEW_DIRECTION)],
		"vec3 {dir} = VIEW;", S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("input/uv", "UV", "Input",
		["uv","texture coordinates","uv0"],
		[], [_p("uv","UV",T.UV)],
		"vec2 {uv} = UV;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/uv2", "UV2", "Input",
		["uv2","second uv","lightmap uv","uv channel 2"],
		[], [_p("uv2","UV2",T.UV)],
		"vec2 {uv2} = UV2;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM))

	r.register_definition(_def("input/vertex_color", "Vertex Color", "Input",
		["vertex color","color attribute","paint color"],
		[], [_p("color","Color",T.COLOR)],
		"vec4 {color} = COLOR;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT,
		S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM))

	r.register_definition(_def("input/frag_coord", "Fragment Coordinate", "Input",
		["fragcoord","fragment coordinate","pixel position","screen pixel"],
		[], [_p("pos","Position",T.VEC2)],
		"vec2 {pos} = FRAGCOORD.xy;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	var screen_auto_uni := {
		"name": "_sgs_screen_tex",
		"type": T.SAMPLER2D,
		"glsl_hint": " : hint_screen_texture, repeat_disable, filter_linear",
		"default_value": ""
	}
	r.register_definition(_def("input/screen_texture", "Screen Texture", "Input",
		["screen texture","screen grab","viewport texture","background"],
		[],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3),
		 _p("r","R",T.FLOAT), _p("g","G",T.FLOAT), _p("b","B",T.FLOAT), _p("a","A",T.FLOAT)],
		"vec4 {rgba} = texture(_sgs_screen_tex, SCREEN_UV);\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN,
		[], screen_auto_uni))

	var depth_auto_uni := {
		"name": "_sgs_depth_tex",
		"type": T.SAMPLER2D,
		"glsl_hint": " : hint_depth_texture, repeat_disable, filter_nearest",
		"default_value": ""
	}
	r.register_definition(_def("input/depth_texture", "Depth Texture", "Input",
		["depth","depth texture","depth buffer","z-depth"],
		[], [_p("depth","Depth",T.FLOAT)],
		"float {depth} = texture(_sgs_depth_tex, SCREEN_UV).r;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL,
		[], depth_auto_uni))


# ---- Time ----

static func _register_time(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/sin_time", "Sin Time", "Input",
		["sin time","sinusoidal time","oscillate","time wave"],
		[], [_p("result","Result",T.FLOAT)],
		"float {result} = sin(TIME);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("input/cos_time", "Cos Time", "Input",
		["cos time","cosine time","cosine wave"],
		[], [_p("result","Result",T.FLOAT)],
		"float {result} = cos(TIME);", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("input/time_scaled", "Scaled Time", "Input",
		["scaled time","time speed","time rate","time frequency"],
		[_p("speed","Speed",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = TIME * {speed};", S.STAGE_ANY, S.DOMAIN_ALL))

	r.register_definition(_def("input/sin_time_scaled", "Sin Scaled Time", "Input",
		["sin scaled time","oscillate speed","wave speed","animated sin"],
		[_p("frequency","Frequency",T.FLOAT,1.0), _p("amplitude","Amplitude",T.FLOAT,1.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = sin(TIME * {frequency}) * {amplitude};", S.STAGE_ANY, S.DOMAIN_ALL))


# ---- Camera and Screen ----

static func _register_camera_screen(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("camera/world_camera_pos", "World Camera Pos", "Camera",
		["world camera position","camera world pos","eye position","camera location"],
		[],
		[_p("pos","Position",T.VEC3), _p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT)],
		"vec3 {pos} = (INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;\nfloat {x} = {pos}.x;\nfloat {y} = {pos}.y;\nfloat {z} = {pos}.z;",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("camera/screen_params", "Screen Params", "Camera",
		["screen params","viewport size","screen resolution","render target size"],
		[],
		[_p("width","Width",T.FLOAT), _p("height","Height",T.FLOAT),
		 _p("inv_width","1/Width",T.FLOAT), _p("inv_height","1/Height",T.FLOAT)],
		"float {width} = VIEWPORT_SIZE.x;\nfloat {height} = VIEWPORT_SIZE.y;\nfloat {inv_width} = 1.0 / VIEWPORT_SIZE.x;\nfloat {inv_height} = 1.0 / VIEWPORT_SIZE.y;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	r.register_definition(_def("camera/screen_position", "Screen Position", "Camera",
		["screen position","screen uv position","fragment screen","ndc position"],
		[],
		[_p("out","Out",T.VEC2), _p("x","X",T.FLOAT), _p("y","Y",T.FLOAT)],
		"vec2 {out} = SCREEN_UV;\nfloat {x} = SCREEN_UV.x;\nfloat {y} = SCREEN_UV.y;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL | S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	r.register_definition(_def("camera/clip_planes", "Clip Planes", "Camera",
		["clip planes","near plane","far plane","camera near far","znear zfar"],
		[],
		[_p("near","Near",T.FLOAT), _p("far","Far",T.FLOAT)],
		"float {near} = PROJECTION_MATRIX[3][2] / (PROJECTION_MATRIX[2][2] - 1.0);\nfloat {far} = PROJECTION_MATRIX[3][2] / (PROJECTION_MATRIX[2][2] + 1.0);",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("camera/projection_params", "Projection Params", "Camera",
		["projection params","near far params","depth params"],
		[],
		[_p("near","Near",T.FLOAT), _p("far","Far",T.FLOAT), _p("inv_far","1/Far",T.FLOAT)],
		"float {near} = PROJECTION_MATRIX[3][2] / (PROJECTION_MATRIX[2][2] - 1.0);\nfloat {far} = PROJECTION_MATRIX[3][2] / (PROJECTION_MATRIX[2][2] + 1.0);\nfloat {inv_far} = 1.0 / {far};",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("camera/z_buffer_params", "Z-Buffer Params", "Camera",
		["z buffer params","depth linearize","zbuffer params"],
		[],
		[_p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT), _p("w","W",T.FLOAT)],
		"float _zn_{x} = PROJECTION_MATRIX[3][2] / (PROJECTION_MATRIX[2][2] - 1.0);\nfloat _zf_{x} = PROJECTION_MATRIX[3][2] / (PROJECTION_MATRIX[2][2] + 1.0);\nfloat {x} = 1.0 - _zf_{x} / _zn_{x};\nfloat {y} = _zf_{x} / _zn_{x};\nfloat {z} = {x} / _zf_{x};\nfloat {w} = {y} / _zf_{x};",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))

	var depth_fade_uni := {
		"name": "_sgs_depth_fade_tex",
		"type": T.SAMPLER2D,
		"glsl_hint": " : hint_depth_texture, repeat_disable, filter_nearest",
		"default_value": ""
	}
	r.register_definition(_def("camera/depth_fade", "Camera Depth Fade", "Camera",
		["depth fade","camera fade","soft intersection","proximity fade"],
		[_p("length","Length",T.FLOAT,1.0), _p("offset","Offset",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float _df_raw_{result} = texture(_sgs_depth_fade_tex, SCREEN_UV).r;\nfloat _df_eye_{result} = PROJECTION_MATRIX[3][2] / (_df_raw_{result} + PROJECTION_MATRIX[2][2]);\nfloat _df_surf_{result} = -VERTEX.z;\nfloat {result} = clamp((_df_surf_{result} - {offset}) / max({length}, 0.001), 0.0, 1.0);",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL,
		[], depth_fade_uni))

	r.register_definition(_def("camera/linear_eye_depth", "Linear Eye Depth", "Camera",
		["linear eye depth","linearize depth","eye space depth","view depth"],
		[_p("raw_depth","Raw Depth",T.FLOAT,0.0)],
		[_p("result","Result",T.FLOAT)],
		"float {result} = PROJECTION_MATRIX[3][2] / ({raw_depth} + PROJECTION_MATRIX[2][2]);",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))


# ---- Surface Data ----

static func _register_surface_data(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("surface/tangent", "Tangent", "Surface Data",
		["tangent","vertex tangent","surface tangent"],
		[], [_p("tangent","Tangent",T.VEC3)],
		"vec3 {tangent} = TANGENT;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("surface/bitangent", "Bitangent", "Surface Data",
		["bitangent","binormal","vertex bitangent"],
		[], [_p("bitangent","Bitangent",T.VEC3)],
		"vec3 {bitangent} = BINORMAL;",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("surface/world_normal", "World Normal", "Surface Data",
		["world normal","world space normal","transformed normal"],
		[], [_p("normal","Normal",T.VEC3)],
		"vec3 {normal} = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);",
		S.STAGE_VERTEX | S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("surface/vertex_position_local", "Vertex Position (Local)", "Surface Data",
		["vertex local","object space vertex","local vertex position"],
		[], [_p("pos","Position",T.VEC3), _p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT)],
		"vec3 {pos} = VERTEX;\nfloat {x} = VERTEX.x;\nfloat {y} = VERTEX.y;\nfloat {z} = VERTEX.z;",
		S.STAGE_VERTEX, S.DOMAIN_SPATIAL))

	r.register_definition(_def("surface/facing", "Is Front Face", "Surface Data",
		["facing","front face","back face","two sided","double sided"],
		[], [_p("result","Is Front",T.FLOAT)],
		"float {result} = FRONT_FACING ? 1.0 : 0.0;",
		S.STAGE_FRAGMENT, S.DOMAIN_SPATIAL))

	r.register_definition(_def("surface/world_position_full", "World Position (XYZ)", "Surface Data",
		["world position xyz","world pos split","position components"],
		[], [_p("pos","Position",T.VEC3), _p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT)],
		"vec3 {pos} = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;\nfloat {x} = {pos}.x;\nfloat {y} = {pos}.y;\nfloat {z} = {pos}.z;",
		S.STAGE_VERTEX, S.DOMAIN_SPATIAL))


# ---- Object Transform ----

static func _register_object_transform(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("object/position", "Object Position", "Object Transform",
		["object position","world position object","pivot","object origin"],
		[],
		[_p("pos","Position",T.VEC3), _p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT)],
		"vec3 {pos} = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;\nfloat {x} = {pos}.x;\nfloat {y} = {pos}.y;\nfloat {z} = {pos}.z;",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("object/scale", "Object Scale", "Object Transform",
		["object scale","world scale","lossyscale","transform scale"],
		[],
		[_p("scale","Scale",T.VEC3), _p("x","X",T.FLOAT), _p("y","Y",T.FLOAT), _p("z","Z",T.FLOAT)],
		"vec3 {scale} = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));\nfloat {x} = {scale}.x;\nfloat {y} = {scale}.y;\nfloat {z} = {scale}.z;",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))

	r.register_definition(_def("object/rotation", "Object Rotation Axes", "Object Transform",
		["object rotation","rotation axes","forward right up","object directions"],
		[],
		[_p("right","Right",T.VEC3), _p("up","Up",T.VEC3), _p("forward","Forward",T.VEC3)],
		"vec3 {right} = normalize(MODEL_MATRIX[0].xyz);\nvec3 {up} = normalize(MODEL_MATRIX[1].xyz);\nvec3 {forward} = normalize(MODEL_MATRIX[2].xyz);",
		S.STAGE_ANY, S.DOMAIN_SPATIAL))


# ---- Canvas Item ----

static func _register_canvas_item(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/canvas_texture", "Canvas Texture", "Input",
		["canvas texture","sprite texture","2d texture","texture()"],
		[],
		[_p("rgba","RGBA",T.COLOR), _p("rgb","RGB",T.VEC3),
		 _p("r","R",T.FLOAT), _p("g","G",T.FLOAT), _p("b","B",T.FLOAT), _p("a","A",T.FLOAT)],
		"vec4 {rgba} = texture(TEXTURE, UV);\nvec3 {rgb} = {rgba}.rgb;\nfloat {r} = {rgba}.r;\nfloat {g} = {rgba}.g;\nfloat {b} = {rgba}.b;\nfloat {a} = {rgba}.a;",
		S.STAGE_FRAGMENT, S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))

	r.register_definition(_def("input/canvas_vertex", "Canvas Vertex", "Input",
		["canvas vertex","vertex position 2d","vertex 2d"],
		[], [_p("vertex","Vertex",T.VEC2)],
		"vec2 {vertex} = VERTEX;",
		S.STAGE_VERTEX, S.DOMAIN_CANVAS_ITEM | S.DOMAIN_FULLSCREEN))


# ---- Particles ----

static func _register_particles(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/particles_velocity", "Particles Velocity", "Input",
		["particles velocity","particle velocity","speed","direction"],
		[], [_p("velocity","Velocity",T.VEC3)],
		"vec3 {velocity} = VELOCITY;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_color", "Particles Color", "Input",
		["particles color","particle color","start color"],
		[], [_p("color","Color",T.COLOR)],
		"vec4 {color} = COLOR;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_index", "Particle Index", "Input",
		["particle index","particle id","particle number"],
		[], [_p("index","Index",T.FLOAT)],
		"float {index} = float(INDEX);",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_lifetime", "Particle Lifetime", "Input",
		["particle lifetime","life","age","ttl"],
		[], [_p("lifetime","Lifetime",T.FLOAT), _p("life","Life (0-1)",T.FLOAT)],
		"float {lifetime} = LIFETIME;\nfloat {life} = LIFETIME > 0.0 ? clamp(CUSTOM.y * LIFETIME, 0.0, 1.0) : 0.0;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))

	r.register_definition(_def("input/particles_random", "Particle Random", "Input",
		["particle random","random","seed","stochastic"],
		[], [_p("rand","Random",T.FLOAT)],
		"float {rand} = CUSTOM.x;",
		S.STAGE_ANY, S.DOMAIN_PARTICLES))


# ---- Sky ----

static func _register_sky(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/sky_eyedir", "Eye Direction", "Input",
		["eye direction","ray direction","sky direction","eyedir","view ray"],
		[], [_p("dir","Direction",T.VEC3)],
		"vec3 {dir} = EYEDIR;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_light_direction", "Sun Direction", "Input",
		["sun direction","light direction","sky light","directional light"],
		[], [_p("dir","Direction",T.VEC3)],
		"vec3 {dir} = LIGHT0_DIRECTION;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_light_color", "Sun Color", "Input",
		["sun color","light color","sky light color","directional color"],
		[], [_p("color","Color",T.VEC3)],
		"vec3 {color} = LIGHT0_COLOR;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_light_energy", "Sun Energy", "Input",
		["sun energy","light energy","sky light energy","intensity"],
		[], [_p("energy","Energy",T.FLOAT)],
		"float {energy} = LIGHT0_ENERGY;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))

	r.register_definition(_def("input/sky_position", "Camera Position", "Input",
		["sky position","camera position","world position sky","observer"],
		[], [_p("pos","Position",T.VEC3)],
		"vec3 {pos} = POSITION;",
		S.STAGE_FRAGMENT, S.DOMAIN_SKY))


# ---- Fog ----

static func _register_fog(r: NodeRegistry) -> void:
	var T := SGSTypes.ShaderType
	var S := SGSTypes

	r.register_definition(_def("input/fog_world_position", "World Position (Fog)", "Input",
		["fog world position","voxel position","fog position"],
		[], [_p("pos","Position",T.VEC3)],
		"vec3 {pos} = WORLD_POSITION;",
		S.STAGE_FRAGMENT, S.DOMAIN_FOG))

	r.register_definition(_def("input/fog_view_direction", "View Direction (Fog)", "Input",
		["fog view direction","fog camera direction","fog view vector"],
		[], [_p("dir","Direction",T.VEC3)],
		"vec3 {dir} = VIEW_DIRECTION;",
		S.STAGE_FRAGMENT, S.DOMAIN_FOG))

	r.register_definition(_def("input/fog_sky_color", "Sky Color (Fog)", "Input",
		["fog sky color","background color","ambient fog color"],
		[], [_p("color","Color",T.COLOR)],
		"vec4 {color} = SKY_COLOR;",
		S.STAGE_FRAGMENT, S.DOMAIN_FOG))
