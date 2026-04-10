# Godot Shader Studio - Documentacion Integral del Addon

Revision analizada: estado del repositorio al 2026-04-10.

Base de verificacion usada para este documento:

- Confirmado: inspeccion directa de `addons/ss_godot_shader_studio`, `project.godot`, `README.md`, `docs/`, ejemplos en `shaders/`, tests en `test/`, workflows en `.github/workflows/` y artefactos de distribucion locales.
- Confirmado: ejecucion de `godot --headless --path . --script test/runner.gd` fuera del sandbox. Resultado: 5 suites, 199 assertions aprobadas, 0 fallos.
- Inferido: comportamiento no cubierto por tests ni visible en UI durante esta revision, pero deducible razonablemente a partir de codigo.
- Pendiente de validacion: comportamiento anunciado por docs/changelog/campos existentes que no pudo verificarse con suficiente evidencia o no tiene integracion activa.

Cuando este documento contradice docs previas del repositorio, debe prevalecer el codigo inspeccionado.

## 1. Resumen ejecutivo

- Nombre del addon: `Godot Shader Studio`. Confirmado en `addons/ss_godot_shader_studio/plugin.cfg`.
- Proposito principal: editor visual de shaders basado en grafos que compila a `.gdshader` generado. Confirmado.
- Problema que resuelve: authoring visual de shaders fuera de `VisualShader`, con formato fuente propio, compilador propio y UI propia. Confirmado.
- Tipo de addon: plugin de editor de Godot con pipeline de compilacion en GDScript y artefacto runtime derivado (`.generated.gdshader`). Confirmado.
- Publico objetivo:
  - usuarios nuevos que quieran authoring visual dentro del editor
  - usuarios avanzados que necesiten control sobre shaders por dominio
  - desarrolladores que quieran registrar nodos propios
  - mantenedores del addon
  - equipos que quieran versionar grafo fuente y shader generado
- Capacidades principales:
  - crear y editar grafos `.gshadergraph` desde una pantalla principal propia
  - crear subgrafos `.gssubgraph`
  - compilar a `spatial`, `canvas_item`, `fullscreen`, `particles`, `sky` y `fog`
  - generar uniforms desde nodos `parameter/*`
  - validar estructura, tipos, ciclos, presencia de nodo de salida y compatibilidad basica de stage scope
  - previsualizar `spatial` y parte del flujo `canvas_item/fullscreen`
  - importar `.gshadergraph` y `.gssubgraph` como recursos editables por el plugin
  - soportar nodos utilitarios como `custom_function`, `reroute` y `subgraph`
- Limitaciones principales:
  - no hay GDExtension ni backend C++ en el arbol actual, aunque `plugin.cfg` todavia lo afirma
  - `domain_support`, `properties_schema`, `stage_config`, `parameters`, `subgraph_refs`, `preview_enabled` y `varyings` existen parcial o totalmente sin integracion completa
  - no hay validacion de cruces vertex -> fragment con varyings reales
  - no hay filtrado de nodos por dominio en la UI
  - no hay tests de import plugins o del ciclo completo de `EditorPlugin`, y faltan ejemplos `.gssubgraph` en el repo
  - varias docs previas estan adelantadas o desalineadas respecto al codigo actual
- Estado general del addon: funcional para el nucleo y utilizable para prototipos/controlados; todavia con deuda visible en UX, coherencia documental y seguridad de contratos publicos. Inferido.
- Nivel de madurez aparente: beta temprana a beta media. El nucleo compila y tiene tests, pero la integracion editor/dominios aun no parece cerrada para produccion exigente sin validacion propia. Inferido.
- Contexto de uso ideal:
  - equipos pequenos o medianos con Godot 4.5
  - flujos donde el `.gshadergraph` sea fuente de verdad y el `.generated.gdshader` se comitee
  - uso interno o controlado antes de una publicacion mas amplia

## 2. Vision general del addon

`Godot Shader Studio` es un plugin de editor que crea una pantalla principal llamada `Shader Studio`, registra un singleton `NodeRegistry`, levanta una libreria estandar de definiciones de nodos y ofrece un `GraphEdit` propio para authoring visual de shaders.

No es un wrapper sobre `VisualShader`. Confirmado por `README.md` y por la implementacion del addon:

- tiene modelo de documento propio (`ShaderGraphDocument`)
- tiene tipos propios (`SGSTypes`, `TypeSystem`)
- tiene registro de nodos propio (`NodeRegistry`, `ShaderNodeDefinition`, `StdlibRegistration`)
- tiene validador propio (`ValidationEngine`)
- tiene IR propio (`IRBuilder`)
- tiene compilador propio (`ShaderGraphCompiler`)
- tiene serializador propio (`GraphSerializer`)
- tiene UI propia (`shader_editor_panel`, `graph_canvas`, `node_inspector`, `parameters_panel`, `compiler_output`, `shader_preview`)

### Flujo de trabajo propuesto

1. Crear un grafo nuevo o abrir un `.gshadergraph`/`.gssubgraph`.
2. Elegir dominio del shader.
3. Anadir nodos desde un popup de busqueda.
4. Conectar puertos y editar propiedades en el dock lateral.
5. Guardar para serializar el grafo y regenerar el shader derivado.
6. Compilar bajo demanda para obtener diagnosticos y actualizar preview.
7. Usar el `.generated.gdshader` como shader runtime en materiales o flujos Godot.

### Escenarios donde si conviene usarlo

- Authoring visual de shaders simples o medianos con necesidad de versionar un formato de grafo legible.
- Experimentacion con efectos, full screen postprocess y materiales PBR sin entrar de inmediato en GLSL manual.
- Extensiones de terceros que quieran registrar definiciones de nodos en GDScript.

### Escenarios donde no conviene usarlo

- Proyectos que requieran garantias fuertes de compatibilidad entre dominios y stages sin revision manual.
- Equipos que dependan de previews completas para `sky`, `fog` o validacion estricta `vertex -> fragment`.
- Casos que necesiten propiedades fuertemente tipadas o inspector generico basado en schema.
- Proyectos que exijan una superficie publica estable y documentacion ya alineada al 100% con el codigo.

### Encaje en el ecosistema Godot

- Editor-time: muy alto. Todo el authoring ocurre como plugin de editor.
- Runtime: indirecto. El runtime real consume el `.generated.gdshader`; el plugin no es necesario para ejecutar el shader ya generado. Confirmado.
- Base tecnica actual: GDScript puro. Confirmado.
- Dependencia de GDExtension: no en el arbol actual. Confirmado.
- Vestigios de capa nativa previa o planeada: si. `.gitmodules` aun referencia `native/thirdparty/godot-cpp`, pero `native/` no existe en este checkout. Confirmado.

## 3. Inventario completo del addon

### 3.1 Configuracion, puntos de entrada y packaging

| Elemento | Tipo | Ruta | Proposito | Relevancia | Estado aparente | Dependencias |
| --- | --- | --- | --- | --- | --- | --- |
| Godot Shader Studio plugin | `plugin.cfg` | `addons/ss_godot_shader_studio/plugin.cfg` | Registrar nombre, descripcion, version y script del plugin | Critico | Activo, pero descripcion/version desalineadas | `plugin.gd` |
| Plugin principal | `EditorPlugin` | `addons/ss_godot_shader_studio/plugin.gd` | Alta/baja del addon, singleton, main screen, docks e import plugins | Critico | Activo | Editor API, `NodeRegistry`, escenas editor |
| Configuracion de proyecto de prueba | `project.godot` | `project.godot` | Habilita el plugin y fija Godot 4.5 | Alta | Activo | Godot 4.5 |
| Importador `.gshadergraph` | `EditorImportPlugin` | `addons/ss_godot_shader_studio/editor/shader_graph_import_plugin.gd` | Envuelve grafo fuente en `ShaderGraphResource` | Alta | Activo | `ShaderGraphResource` |
| Importador `.gssubgraph` | `EditorImportPlugin` | `addons/ss_godot_shader_studio/editor/subgraph_import_plugin.gd` | Envuelve subgrafo fuente en `ShaderGraphResource` | Alta | Activo | `ShaderGraphResource` |
| Wrapper de recurso importado | `Resource` | `addons/ss_godot_shader_studio/editor/shader_graph_resource.gd` | Guarda `source_path` para que el plugin abra el archivo fuente | Alta | Activo | Import plugins, `_handles/_edit` |
| CI | GitHub Actions | `.github/workflows/ci.yml` | Ejecuta validacion PR y tests Godot 4.5 via workflow reutilizable | Media | Activo | `slice-soft/ss-pipeline` |
| Release | GitHub Actions | `.github/workflows/release.yml` | Publica releases y addon package | Media | Activo | `slice-soft/ss-pipeline` |
| Release manifest | JSON | `release-please-config.json`, `.release-please-manifest.json` | Versionado automatizado | Media | Activo | release-please |
| Artefacto zip local | ZIP | `dist/ss_godot_shader_studio_v0.0.0-local.zip` | Empaquetado local del addon | Baja | Existe, pero no coincide con version 0.6.0 | Contenido de `addons/ss_godot_shader_studio` |

### 3.2 Clases y scripts del nucleo

| Nombre | Tipo | Ruta | Proposito | Relevancia | Estado | Dependencias |
| --- | --- | --- | --- | --- | --- | --- |
| `SGSTypes` | clase estatica/constantes | `addons/ss_godot_shader_studio/core/types/sgs_types.gd` | Enum de tipos, cast types y flags de stage/domain | Critico | Activo | Consumido por casi todo el core |
| `TypeSystem` | clase estatica | `addons/ss_godot_shader_studio/core/types/type_system.gd` | Compatibilidad, casts, GLSL names, component counts | Critico | Activo | `SGSTypes` |
| `ShaderNodeDefinition` | `Resource` | `addons/ss_godot_shader_studio/core/registry/shader_node_definition.gd` | Contrato de cada nodo del grafo | Critico | Activo | `SGSTypes` |
| `NodeRegistry` | `Object` | `addons/ss_godot_shader_studio/core/registry/node_registry.gd` | Catalogo singleton de definiciones | Critico | Activo | `ShaderNodeDefinition` |
| `StdlibRegistration` | clase utilitaria | `addons/ss_godot_shader_studio/core/registry/stdlib_registration.gd` | Registra 97 definiciones builtin | Critico | Activo | `NodeRegistry`, `SGSTypes` |
| `ShaderGraphDocument` | `Resource` | `addons/ss_godot_shader_studio/core/graph/shader_graph_document.gd` | Documento raiz del grafo | Critico | Activo | `ShaderGraphNodeInstance`, `ShaderGraphEdge` |
| `ShaderGraphNodeInstance` | `Resource` | `addons/ss_godot_shader_studio/core/graph/shader_graph_node_instance.gd` | Instancia colocada de un nodo | Critico | Activo | `ShaderNodeDefinition` |
| `ShaderGraphEdge` | `Resource` | `addons/ss_godot_shader_studio/core/graph/shader_graph_edge.gd` | Conexion dirigida entre puertos | Critico | Activo | Documento y compilador |
| `ValidationEngine` | clase | `addons/ss_godot_shader_studio/core/validation/validation_engine.gd` | Validacion estructural/tipos/stage/ciclos/output | Critico | Activo, con huecos de dominio/varyings | `TypeSystem`, `NodeRegistry` |
| `IRBuilder` | clase estatica | `addons/ss_godot_shader_studio/core/ir/ir_builder.gd` | Construye IR ordenado y resuelve defaults/uniforms/helpers/subgraphs | Critico | Activo | `TypeSystem`, `GraphSerializer`, `NodeRegistry` |
| `ShaderGraphCompiler` | clase | `addons/ss_godot_shader_studio/core/compiler/shader_graph_compiler.gd` | Orquesta validacion, IR y emision `.gdshader` | Critico | Activo | `ValidationEngine`, `IRBuilder`, `NodeRegistry` |
| `GraphSerializer` | clase | `addons/ss_godot_shader_studio/core/serializer/graph_serializer.gd` | Persistencia JSON `.gshadergraph`/`.gssubgraph` | Critico | Activo, version 1 sin migraciones | `ShaderGraphDocument` |

### 3.3 Componentes de editor e interfaz

| Nombre | Tipo | Ruta | Proposito | Relevancia | Estado | Dependencias |
| --- | --- | --- | --- | --- | --- | --- |
| `shader_editor_panel.gd` | `Control` | `addons/ss_godot_shader_studio/editor/shader_editor_panel.gd` | Pantalla principal del addon | Critico | Activo | serializer, compiler, preview, canvas |
| `shader_editor_panel.tscn` | escena | `addons/ss_godot_shader_studio/editor/shader_editor_panel.tscn` | Layout principal de toolbar, canvas, preview y salida | Critico | Activo | escenas hijas |
| `graph_canvas.gd` | `GraphEdit` | `addons/ss_godot_shader_studio/editor/graph_canvas.gd` | Canvas del grafo, conexiones, atajos, frames, copy/paste | Critico | Activo | `GraphNodeWidget`, `NodeRegistry`, undo/redo |
| `graph_canvas.tscn` | escena | `addons/ss_godot_shader_studio/editor/graph_canvas.tscn` | Contenedor del canvas y popup de busqueda | Alta | Activo | popup |
| `graph_node_widget.gd` | `GraphNode` | `addons/ss_godot_shader_studio/editor/graph_node_widget.gd` | Widget visual de cada nodo | Alta | Activo | `ShaderGraphNodeInstance` |
| `graph_node_widget.tscn` | escena | `addons/ss_godot_shader_studio/editor/graph_node_widget.tscn` | Template base del widget de nodo | Alta | Activo | script |
| `node_search_popup.gd` | `PopupPanel` | `addons/ss_godot_shader_studio/editor/node_search_popup.gd` | Busqueda y seleccion de nodos | Alta | Activo | `NodeRegistry` |
| `node_search_popup.tscn` | escena | `addons/ss_godot_shader_studio/editor/node_search_popup.tscn` | Layout del popup | Alta | Activo | script |
| `node_inspector.gd` | `PanelContainer` | `addons/ss_godot_shader_studio/editor/node_inspector.gd` | Inspector lateral para propiedades de nodo/frame | Alta | Activo | `ShaderGraphNodeInstance`, `EditorFileDialog` |
| `node_inspector.tscn` | escena | `addons/ss_godot_shader_studio/editor/node_inspector.tscn` | Layout del inspector | Alta | Activo | script |
| `parameters_panel.gd` | `PanelContainer` | `addons/ss_godot_shader_studio/editor/parameters_panel.gd` | Lista y edicion rapida de nodos `parameter/*` | Alta | Activo | documento |
| `parameters_panel.tscn` | escena | `addons/ss_godot_shader_studio/editor/parameters_panel.tscn` | Layout del panel de parametros | Alta | Activo | script |
| `compiler_output.gd` | `PanelContainer` | `addons/ss_godot_shader_studio/editor/compiler_output.gd` | Consola compacta de compilacion | Media | Activo | `RichTextLabel`, clipboard |
| `compiler_output.tscn` | escena | `addons/ss_godot_shader_studio/editor/compiler_output.tscn` | Layout del panel de salida | Media | Activo | script |
| `shader_preview.gd` | `SubViewportContainer` | `addons/ss_godot_shader_studio/preview/shader_preview.gd` | Preview 3D/2D del shader generado | Alta | Activo parcialmente | `Shader`, `ShaderMaterial`, escenas preview |
| `shader_preview.tscn` | escena | `addons/ss_godot_shader_studio/preview/shader_preview.tscn` | Preview 3D basado en capsula + luz + camara | Alta | Activo | script |

### 3.4 Recursos, ejemplos y artefactos tecnicos

| Elemento | Tipo | Ruta | Proposito | Relevancia | Estado | Dependencias |
| --- | --- | --- | --- | --- | --- | --- |
| `test.gshadergraph` | ejemplo fuente | `shaders/test.gshadergraph` | Ejemplo spatial con `Append Vec3`, `Custom Function` y frame | Media | Activo | serializer/compiler |
| `test.generated.gdshader` | shader derivado | `shaders/test.generated.gdshader` | Salida compilada del ejemplo spatial | Media | Activo | compilador |
| `screen green.gshadergraph` | ejemplo fuente | `shaders/screen green.gshadergraph` | Ejemplo fullscreen con screen texture, HSV y parametros | Media | Activo | serializer/compiler |
| `screen green.generated.gdshader` | shader derivado | `shaders/screen green.generated.gdshader` | Salida compilada del ejemplo fullscreen | Media | Activo | compilador |
| `.gshadergraph.import` | metadata de import | `shaders/*.gshadergraph.import` | Mapeo a recurso importado `.res` en `.godot/imported` | Media | Activo | import plugin |
| `.godot/imported/*.res` | recurso importado | `.godot/imported/...` | Resultado del import editor-time | Baja | Activo localmente | Godot import pipeline |

### 3.5 Test suite y verificacion automatica

| Elemento | Tipo | Ruta | Proposito | Cobertura |
| --- | --- | --- | --- | --- |
| `TestCase` | base de test | `test/framework/test_case.gd` | Mini framework de assertions | Core |
| `runner.gd` | runner headless editor | `test/runner.gd` | Descubre y ejecuta suites | Core |
| `test_type_system.gd` | unit tests | `test/unit/test_type_system.gd` | Tipos y casts | Alta |
| `test_graph_document.gd` | unit tests | `test/unit/test_graph_document.gd` | CRUD y counters | Alta |
| `test_validation_engine.gd` | unit tests | `test/unit/test_validation_engine.gd` | Validacion basica | Media |
| `test_ir_builder.gd` | unit tests | `test/unit/test_ir_builder.gd` | IR, uniforms, casts basicos | Media |
| `test_compiler.gd` | integration tests | `test/unit/test_compiler.gd` | Emision por dominio y errores basicos | Media |
| `test_shader_editor_panel_integration.gd` | integration tests | `test/integration/test_shader_editor_panel_integration.gd` | Guardado, naming y salida generada desde el panel | Alta |
| `test_graph_canvas_integration.gd` | integration tests | `test/integration/test_graph_canvas_integration.gd` | Puertos dinamicos, limpieza de edges y validacion visual | Media |
| `test_shader_preview_integration.gd` | integration tests | `test/integration/test_shader_preview_integration.gd` | Preview 3D/2D y dominios no soportados | Media |
| `smoke_test_phase_a.gd` | smoke test | `test/smoke_test_phase_a.gd` | Demo manual de compilacion | Baja |

Observaciones de cobertura:

- Confirmado: el core tiene cobertura razonable para tipos, documento, validacion basica e interfaces de compilacion.
- Confirmado: ya hay tests headless para escenas de editor clave (`shader_editor_panel`, `graph_canvas`, `shader_preview`).
- Confirmado: ya hay tests especificos para contratos dinamicos de subgraph, compatibilidad con paths legacy y normalizacion de nombres/rutas.
- Requisito de ejecucion: la suite completa ahora corre en modo `--headless --editor` porque varias escenas usan clases exclusivas del editor.
- Pendiente: siguen faltando tests de import plugins, del ciclo completo de `EditorPlugin`, de escenarios complejos de `custom_function` y de cruces reales vertex -> fragment.

### 3.6 Inventario completo de definiciones de nodo de grafo

Conteo confirmado de la stdlib builtin:

- Total de definiciones registradas: 97.
- Distribucion por categoria:

| Categoria | Cantidad |
| --- | ---: |
| Math | 16 |
| Trigonometry | 4 |
| Vector | 7 |
| Float | 6 |
| Swizzle | 6 |
| Color | 5 |
| UV | 3 |
| Texture | 2 |
| Input | 26 |
| Parameters | 4 |
| Output | 6 |
| Utility | 3 |
| Subgraph | 2 |
| Effects | 7 |

Listado completo por categoria:

| Categoria | Definiciones |
| --- | --- |
| Math | `math/add`, `math/subtract`, `math/multiply`, `math/divide`, `math/power`, `math/sqrt`, `math/abs`, `math/negate`, `math/floor`, `math/ceil`, `math/round`, `math/fract`, `math/mod`, `math/min`, `math/max`, `math/sign` |
| Trigonometry | `trig/sin`, `trig/cos`, `trig/tan`, `trig/atan2` |
| Vector | `vector/dot`, `vector/cross`, `vector/normalize`, `vector/length`, `vector/distance`, `vector/reflect`, `vector/refract` |
| Float | `float/lerp`, `float/clamp`, `float/smoothstep`, `float/step`, `float/saturate`, `float/remap` |
| Swizzle | `swizzle/split_vec4`, `swizzle/split_vec3`, `swizzle/split_vec2`, `swizzle/append_vec2`, `swizzle/append_vec3`, `swizzle/append_vec4` |
| Color | `color/blend`, `color/color_to_vec3`, `color/vec3_to_color`, `color/hsv_to_rgb`, `color/rgb_to_hsv` |
| UV | `uv/panner`, `uv/rotator`, `uv/tiling_offset` |
| Texture | `texture/sample_2d`, `texture/sample_cube` |
| Input | `input/time`, `input/screen_uv`, `input/vertex_normal`, `input/world_position`, `input/view_direction`, `input/uv`, `input/uv2`, `input/vertex_color`, `input/frag_coord`, `input/screen_texture`, `input/depth_texture`, `input/canvas_texture`, `input/canvas_vertex`, `input/particles_velocity`, `input/particles_color`, `input/particles_index`, `input/particles_lifetime`, `input/particles_random`, `input/sky_eyedir`, `input/sky_light_direction`, `input/sky_light_color`, `input/sky_light_energy`, `input/sky_position`, `input/fog_world_position`, `input/fog_view_direction`, `input/fog_sky_color` |
| Parameters | `parameter/float`, `parameter/vec4`, `parameter/color`, `parameter/texture2d` |
| Output | `output/spatial`, `output/vertex_offset`, `output/canvas_item`, `output/fullscreen`, `output/particles`, `output/sky`, `output/fog` |
| Utility | `utility/reroute`, `utility/custom_function`, `utility/subgraph` |
| Subgraph | `subgraph/input`, `subgraph/output` |
| Effects | `effects/fresnel`, `effects/normal_blend`, `effects/toon_ramp`, `effects/value_noise`, `effects/triplanar`, `effects/dither`, `effects/dissolve` |

## 4. Estructura de carpetas y organizacion del proyecto

```text
.
├── addons/ss_godot_shader_studio/
│   ├── plugin.cfg
│   ├── plugin.gd
│   ├── CHANGELOG.md
│   ├── core/
│   │   ├── compiler/
│   │   ├── graph/
│   │   ├── ir/
│   │   ├── registry/
│   │   ├── serializer/
│   │   ├── types/
│   │   └── validation/
│   ├── editor/
│   │   ├── *.gd
│   │   └── *.tscn
│   └── preview/
│       ├── shader_preview.gd
│       └── shader_preview.tscn
├── docs/
│   ├── architecture/overview.md
│   ├── compiler/pipeline.md
│   ├── graph-format/gshadergraph-spec.md
│   ├── node-authoring/node-definition-spec.md
│   └── addon-reference.md
├── shaders/
│   ├── *.gshadergraph
│   └── *.generated.gdshader
├── test/
│   ├── framework/
│   ├── unit/
│   └── smoke_test_phase_a.*
├── .github/workflows/
├── dist/
└── README.md
```

### Proposito de cada carpeta

- `addons/ss_godot_shader_studio/core/`: dominio del problema y compilador. Sin UI.
- `addons/ss_godot_shader_studio/editor/`: integracion con Godot Editor y experiencia de authoring.
- `addons/ss_godot_shader_studio/preview/`: vista previa embebida.
- `docs/`: especificaciones previas y arquitectura.
- `shaders/`: ejemplos fuente y shaders generados.
- `test/`: framework y suite headless.
- `.github/workflows/`: automatizacion CI/release.
- `dist/`: artefacto local zip.

### Patrones de organizacion visibles

- Separacion razonable editor/core. Confirmado.
- Registro centralizado de nodos builtin en un solo archivo grande (`stdlib_registration.gd`). Confirmado.
- Persistencia via JSON sin dependencia externa. Confirmado.
- Escenas pequenas y scripts especificos por panel. Confirmado.

### Fortalezas de la estructura actual

- La frontera `core/` vs `editor/` es clara.
- El pipeline es legible y facil de seguir.
- Los tests del core estan separados de la UI.
- Los ejemplos de shader ayudan a validar salida real.

### Problemas u areas confusas

- `stdlib_registration.gd` concentra demasiada superficie en un solo archivo. Confirmado.
- `.gitmodules` apunta a `native/thirdparty/godot-cpp`, pero `native/` no existe. Confirmado.
- `plugin.cfg`, `CHANGELOG`, manifest de release y `ShaderGraphCompiler.COMPILER_VERSION` no comparten la misma version. Confirmado.
- La documentacion en `docs/` no siempre refleja la implementacion real. Confirmado.
- El zip local en `dist/` esta versionado como `v0.0.0-local`, distinto del manifiesto `0.6.0`. Confirmado.

## 5. Instalacion y activacion

### Requisitos previos

- Godot 4.5 estable. Confirmado por `project.godot` y CI.
- No se requiere toolchain C++ ni GDExtension en el arbol actual. Confirmado.
- No hay dependencias runtime externas para consumir el shader ya generado. Confirmado.

### Versiones compatibles de Godot

- Confirmado: 4.5 estable.
- Inferido: versiones 4.x cercanas pueden funcionar si preservan `GraphFrame`, `EditorUndoRedoManager`, `EditorImportPlugin` y APIs usadas, pero no hay evidencia en este repo.

### Instalacion copiando carpeta

1. Copiar `addons/ss_godot_shader_studio/` dentro de `addons/` del proyecto Godot.
2. Abrir el proyecto en Godot 4.5.
3. Ir a `Project Settings -> Plugins`.
4. Habilitar `Godot Shader Studio`.
5. Verificar que aparezca la pantalla principal `Shader Studio` y el dock derecho `Shader Studio` con tabs `Properties` y `Parameters`.

### Instalacion desde este repositorio

1. Clonar el repositorio completo.
2. Abrir el proyecto tal como viene.
3. El `project.godot` ya deja el plugin habilitado en este checkout.

### Instalacion como submodulo git en otro proyecto

1. Anadir el repo como submodulo o subtree.
2. Exponer solo `addons/ss_godot_shader_studio/` en la ruta esperada por Godot.
3. Habilitar el plugin desde Project Settings.

Observacion: el repo contiene `.gitmodules` hacia un path `native/thirdparty/godot-cpp`, pero ese path no existe en el checkout actual. Para la instalacion actual no parece necesario. Confirmado.

### Instalacion desde zip

- Existe `dist/ss_godot_shader_studio_v0.0.0-local.zip`. Confirmado.
- Es util como paquete local, pero su nomenclatura no coincide con la version publicada en el manifiesto. Confirmado.
- Pendiente de validacion: flujo exacto de publicacion final en Godot Asset Library.

### Activacion y verificacion inicial

Checklist rapido:

- `Shader Studio` visible como pantalla principal.
- Dock derecho `Shader Studio` visible.
- Al abrir la pantalla aparece un grafo nuevo con `Spatial Output`.
- Doble click en canvas vacio abre popup de busqueda.
- `Compile` sobre el grafo minimo produce shader spatial valido.

### Errores frecuentes de instalacion

| Problema | Sintomas | Causa probable | Solucion |
| --- | --- | --- | --- |
| El plugin no aparece | No hay pantalla `Shader Studio` | Carpeta en ruta incorrecta o plugin deshabilitado | Revisar `addons/ss_godot_shader_studio` y activar en Plugins |
| Abrir `.gshadergraph` no abre el editor | El archivo se ve como recurso generico | Plugin deshabilitado o import no refrescado | Rehabilitar plugin, reimportar, reiniciar editor |
| No se genera `.generated.gdshader` | Guardado correcto del grafo pero sin shader en la carpeta esperada | El documento es `subgraph`, hubo error de compilacion o aun no se eligio carpeta de salida | Usar dominio no `subgraph`, revisar panel Output y confirmar la carpeta de salida del shader generado |
| Tests headless fallan por logs | Crash al iniciar Godot headless bajo sandbox | Restriccion de escritura fuera de workspace | Ejecutar fuera del sandbox o ajustar permisos de entorno |

## 6. Conceptos fundamentales

### 6.1 Modelo mental correcto

Piensa el addon como cuatro niveles:

1. Definiciones de nodo: contratos reutilizables registrados en `NodeRegistry`.
2. Documento de grafo: instancias de nodos, edges, frames y metadata serializada.
3. Pipeline: validacion -> IR -> emision `.gdshader`.
4. UI de editor: canvas, inspector, panel de parametros, preview y logs.

### 6.2 Fuente de verdad

- La fuente de verdad real es el archivo `.gshadergraph` o `.gssubgraph`. Confirmado.
- El `.generated.gdshader` es derivado. Confirmado.
- El recurso importado `.res` no contiene el grafo completo; solo apunta a `source_path` via `ShaderGraphResource`. Confirmado.

### 6.3 Documento, nodo, edge y frame

- `ShaderGraphDocument`: contiene dominio, metadata, nodos, edges y frames. Confirmado.
- `ShaderGraphNodeInstance`: no es un `Node` de escena; es una `Resource` con `definition_id`, `title`, `position`, `properties`, `stage_scope`, `preview_enabled`. Confirmado.
- `ShaderGraphEdge`: une `from_node_id/from_port_id` con `to_node_id/to_port_id`. Confirmado.
- Frame/comment: se serializa como `Dictionary`, no clase dedicada. Confirmado.

### 6.4 Definicion de nodo vs instancia

- Definicion (`ShaderNodeDefinition`): describe puertos, template GLSL, soporte de stage/domain, helper functions y auto-uniform opcional.
- Instancia (`ShaderGraphNodeInstance`): guarda colocacion y propiedades concretas del nodo dentro del documento.

### 6.5 Propiedades de nodo

- La mayoria de propiedades editables son strings con literales GLSL o nombres. Confirmado.
- No hay esquema tipado aplicado por `properties_schema` en la UI actual. Confirmado.
- La UI del inspector muestra:
  - `LineEdit` generico para propiedades simples
  - `TextEdit` para `body` de `utility/custom_function`
  - file picker para `subgraph_path` de `utility/subgraph`

### 6.6 Domains y stages

- Domains soportados por compilador: `spatial`, `canvas_item`, `fullscreen`, `particles`, `sky`, `fog`, `subgraph`. Confirmado.
- Stage support declarado por nodos: flags en `SGSTypes`. Confirmado.
- Limitacion critica: `domain_support` existe pero no se valida ni filtra en la UI ni en `ValidationEngine`. Confirmado.
- Limitacion critica: el sistema no materializa varyings reales para conexiones vertex -> fragment, aunque la docs previa lo sugiera. Confirmado.

### 6.7 Parametros

- Los uniforms publicos no salen de `doc.parameters`; salen de nodos `parameter/*`. Confirmado.
- `ParametersPanel` solo edita propiedades de esos nodos (`param_name`, `default_value`). Confirmado.
- `doc.parameters` se serializa, pero no es mantenido por la UI actual. Confirmado.

### 6.8 Subgrafos

- `.gssubgraph` usa el mismo serializer JSON con `shader_domain == "subgraph"`. Confirmado.
- `utility/subgraph` expande inline un subgrafo cargado desde `subgraph_path`. Confirmado.
- El contrato visible de `utility/subgraph` ahora se deriva del archivo `.gssubgraph`: cantidad de entradas/salidas, nombres y tipos. Confirmado.
- El sistema vigila cambios de los subgrafos referenciados, refresca puertos y elimina edges que ya no correspondan al contrato vigente. Confirmado.
- Compatibilidad legacy: si un subgrafo antiguo quedo guardado con extension `.gshadergraph`, el loader intenta resolverlo y seguir compilando, aunque el flujo normal de guardado ya fuerza `.gssubgraph`. Confirmado.

### 6.9 Editor-time vs runtime

- Editor-time: authoring, serializacion, preview, validacion y compilacion.
- Runtime: el juego usa el shader ya generado como cualquier otro `Shader` Godot.
- No hay singleton/autoload runtime que el juego final necesite conservar. Confirmado.

## 7. Documentacion completa de nodos

### 7.1 Aclaracion importante

- Nodos personalizados de SceneTree expuestos al usuario final: ninguno confirmado.
- Lo que este addon llama "nodes" son definiciones de nodo de grafo shader, no clases `Node` reusables en una escena del juego. Confirmado.
- Todas las definiciones builtin viven en `addons/ss_godot_shader_studio/core/registry/stdlib_registration.gd`. Confirmado.
- Herencia comun: `ShaderNodeDefinition extends Resource`. Confirmado.
- Metodos publicos por definicion: no hay API por nodo individual; el comportamiento se describe por puertos y `compiler_template`. Confirmado.
- Señales por definicion: ninguna. Confirmado.
- Propiedades exportadas por definicion: ninguna. Confirmado.

### 7.2 Contrato comun de cualquier nodo de grafo

Cada definicion comparte estas reglas base:

- Rol dentro del sistema: transformar valores, exponer builtins, declarar uniforms o escribir salidas del shader.
- Uso tipico:
  - la instancia se coloca en `ShaderGraphDocument`
  - sus puertos se conectan via `ShaderGraphEdge`
  - el compilador resuelve inputs conectados o defaults
  - el template GLSL se emite en `vertex()`, `fragment()`, `process()`, `sky()` o `fog()`
- Lo que no hace una definicion por si sola:
  - no renderiza nada en runtime
  - no crea controles de inspector tipados automaticamente
  - no valida dominio por si misma
  - no crea varyings
- Restricciones comunes:
  - los defaults son literales GLSL o `0.0/vecN(0.0)` resueltos por `IRBuilder`
  - `stage_scope` de la instancia puede forzar `vertex`, pero no hay flujo real cross-stage seguro
  - `preview_enabled` existe como campo, pero no hay preview por nodo implementado

### 7.3 Nodos especiales que requieren atencion adicional

#### `parameter/*`

- Proposito: declarar uniforms.
- Implementacion: el `compiler_template` esta vacio y `IRBuilder` usa el `param_name` como `var_name` del output.
- Defaults iniciales sembrados por UI:
  - `parameter/float` -> `default_value = "0.0"`
  - `parameter/vec4` -> `default_value = "vec4(0.0, 0.0, 0.0, 1.0)"`
  - `parameter/color` -> `default_value = "vec4(1.0, 1.0, 1.0, 1.0)"`
  - `parameter/texture2d` -> sin default editor visible
- Riesgos:
  - nombres sin sanitizar pueden producir GLSL invalido
  - `ParametersPanel` no impide duplicados; `IRBuilder` solo deduplica por nombre y la ultima semantica queda ambigua

#### `utility/custom_function`

- Proposito: permitir una expresion GLSL inline.
- Propiedad clave: `body`.
- Lo que hace: `IRBuilder` envuelve el body como `float {result} = <body>;`.
- Lo que no hace:
  - no permite declarar multiples outputs
  - no cambia el tipo de salida: siempre `float`
  - no valida sintaxis GLSL
- Uso correcto: expresiones escalares pequenas usando `{a}`, `{b}`, `{c}`, `{d}`.
- Anti-patron: intentar escribir un bloque GLSL completo o retornar `vec3`.

#### `utility/subgraph`, `subgraph/input`, `subgraph/output`

- Proposito: reutilizacion de fragmentos de grafo.
- Flujo:
  - `utility/subgraph` guarda `subgraph_path`
  - `IRBuilder` carga ese archivo con `GraphSerializer`
  - cada `subgraph/input` expone `input_name`, `input_type` y un `port_id` estable derivado del nodo interno
  - cada `subgraph/output` expone `output_name`, `output_type` y su `port_id` estable
  - `utility/subgraph` refleja ese contrato dinamicamente en el canvas, validacion y compilacion
- Regla operativa confirmada:
  - el orden visible de puertos se deriva de la posicion vertical/horizontal de los nodos internos
  - cambiar nombres no rompe edges existentes porque el wrapper usa ids estables de contrato
  - quitar puertos si puede podar edges obsoletos al refrescar el contrato

#### `utility/reroute`

- Proposito: ordenar cableado visual.
- Implementacion: transparente en validacion tipada y en IR.
- Lo que no hace: no emite codigo, no cambia tipo, no guarda metadata adicional.

#### `output/*`

- Son nodos terminales por dominio.
- `ValidationEngine` exige presencia del output correspondiente al dominio, pero no exige unicidad. Confirmado.
- `ShaderEditorPanel` intercambia automaticamente el nodo output principal cuando cambia el dominio desde el dropdown. Confirmado.

#### `input/screen_texture` y `input/depth_texture`

- Proposito: exponer texturas automáticas del motor.
- Implementacion: usan `auto_uniform`.
- Uniforms auto-inyectados:
  - `_sgs_screen_tex : hint_screen_texture, repeat_disable, filter_linear`
  - `_sgs_depth_tex : hint_depth_texture, repeat_disable, filter_nearest`

### 7.4 Tablas completas por categoria

#### Math

| ID | IO | Scope declarado | Uso tipico | Limites, defaults y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `math/add` | `float,float -> float` | any/all | suma escalar | defaults `a=0.0`, `b=0.0`; no suma vectorial | Confirmado |
| `math/subtract` | `float,float -> float` | any/all | resta escalar | defaults `0.0`; no resta vectorial | Confirmado |
| `math/multiply` | `float,float -> float` | any/all | multiplicacion escalar | defaults `1.0`; no producto vectorial | Confirmado |
| `math/divide` | `float,float -> float` | any/all | division escalar | defaults `1.0`; no evita division por cero | Confirmado |
| `math/power` | `float,float -> float` | any/all | potencia | `base=1.0`, `exp=2.0` | Confirmado |
| `math/sqrt` | `float -> float` | any/all | raiz cuadrada | default `1.0`; no protege negativos | Confirmado |
| `math/abs` | `float -> float` | any/all | valor absoluto | default `0.0` | Confirmado |
| `math/negate` | `float -> float` | any/all | cambio de signo | default `0.0` | Confirmado |
| `math/floor` | `float -> float` | any/all | redondeo hacia abajo | default `0.0` | Confirmado |
| `math/ceil` | `float -> float` | any/all | redondeo hacia arriba | default `0.0` | Confirmado |
| `math/round` | `float -> float` | any/all | redondeo | default `0.0` | Confirmado |
| `math/fract` | `float -> float` | any/all | parte fraccionaria | default `0.0` | Confirmado |
| `math/mod` | `float,float -> float` | any/all | modulo | `x=0.0`, `y=1.0`; divisor cero no se valida | Confirmado |
| `math/min` | `float,float -> float` | any/all | minimo escalar | defaults `0.0` | Confirmado |
| `math/max` | `float,float -> float` | any/all | maximo escalar | defaults `0.0` | Confirmado |
| `math/sign` | `float -> float` | any/all | signo | default `0.0` | Confirmado |

#### Trigonometry

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `trig/sin` | `float -> float` | any/all | seno escalar | input en radianes; default `0.0` | Confirmado |
| `trig/cos` | `float -> float` | any/all | coseno escalar | input en radianes; default `0.0` | Confirmado |
| `trig/tan` | `float -> float` | any/all | tangente escalar | input en radianes; default `0.0` | Confirmado |
| `trig/atan2` | `float,float -> float` | any/all | angulo desde `y,x` | `y=0.0`, `x=1.0` | Confirmado |

#### Vector

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `vector/dot` | `vec3,vec3 -> float` | any/all | producto punto | solo `vec3` | Confirmado |
| `vector/cross` | `vec3,vec3 -> vec3` | any/all | producto cruz | solo `vec3` | Confirmado |
| `vector/normalize` | `vec3 -> vec3` | any/all | normalizar vector | solo `vec3`; sin guard para longitud cero | Confirmado |
| `vector/length` | `vec3 -> float` | any/all | longitud | solo `vec3` | Confirmado |
| `vector/distance` | `vec3,vec3 -> float` | any/all | distancia | solo `vec3` | Confirmado |
| `vector/reflect` | `vec3,vec3 -> vec3` | any/all | reflejar vector incidente | solo `vec3` | Confirmado |
| `vector/refract` | `vec3,vec3,float -> vec3` | any/all | refraccion | `ior=1.0`; solo `vec3` | Confirmado |

#### Float

| ID | IO | Scope declarado | Uso tipico | Limites y defaults | Estado |
| --- | --- | --- | --- | --- | --- |
| `float/lerp` | `float,float,float -> float` | any/all | mezcla lineal escalar | defaults `0.0,1.0,0.5` | Confirmado |
| `float/clamp` | `float,float,float -> float` | any/all | clamp escalar | defaults `0.0,0.0,1.0` | Confirmado |
| `float/smoothstep` | `float,float,float -> float` | any/all | transicion suave | defaults `0.0,1.0,0.5` | Confirmado |
| `float/step` | `float,float -> float` | any/all | threshold | defaults `0.5,0.0` | Confirmado |
| `float/saturate` | `float -> float` | any/all | clamp 0..1 | default `0.0` | Confirmado |
| `float/remap` | `float,float,float,float,float -> float` | any/all | remapeo de rango | no protege `in_max == in_min` | Confirmado |

#### Swizzle

| ID | IO | Scope declarado | Uso tipico | Limites y defaults | Estado |
| --- | --- | --- | --- | --- | --- |
| `swizzle/split_vec4` | `vec4 -> float,float,float,float` | any/all | descomponer vec4/color | sin defaults internos | Confirmado |
| `swizzle/split_vec3` | `vec3 -> float,float,float` | any/all | descomponer vec3 | sin defaults internos | Confirmado |
| `swizzle/split_vec2` | `vec2 -> float,float` | any/all | descomponer vec2/uv | sin defaults internos | Confirmado |
| `swizzle/append_vec2` | `float,float -> vec2` | any/all | construir vec2 | defaults `0.0,0.0` | Confirmado |
| `swizzle/append_vec3` | `float,float,float -> vec3` | any/all | construir vec3 | defaults `0.0,0.0,0.0` | Confirmado |
| `swizzle/append_vec4` | `float,float,float,float -> vec4` | any/all | construir vec4 | defaults `0.0,0.0,0.0,1.0` | Confirmado |

#### Color

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `color/blend` | `color,color -> color` | any/all | multiplicar colores | blend fijo por multiplicacion; no modos avanzados | Confirmado |
| `color/color_to_vec3` | `color -> vec3` | any/all | extraer RGB | descarta alpha | Confirmado |
| `color/vec3_to_color` | `vec3,float -> color` | any/all | recomponer RGBA | alpha default `1.0` | Confirmado |
| `color/hsv_to_rgb` | `vec3 -> vec3` | any/all | pasar HSV a RGB | input esperado normalizado | Confirmado |
| `color/rgb_to_hsv` | `vec3 -> vec3` | any/all | pasar RGB a HSV | no valida rango de entrada | Confirmado |

#### UV

| ID | IO | Scope declarado | Uso tipico | Limites y defaults | Estado |
| --- | --- | --- | --- | --- | --- |
| `uv/panner` | `uv,vec2,time -> uv` | any/all | desplazar UV en el tiempo | `time` default `0.0` | Confirmado |
| `uv/rotator` | `uv,vec2,float -> uv` | any/all | rotar UV alrededor de centro | `angle=0.0`; usa trig directo | Confirmado |
| `uv/tiling_offset` | `uv,vec2,vec2 -> uv` | any/all | tiling y offset | sin defaults sembrados por UI | Confirmado |

#### Texture

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `texture/sample_2d` | `sampler2D,uv -> color,vec3,float,float,float,float` | fragment/all | sample 2D | solo fragment; depende de UV valido | Confirmado |
| `texture/sample_cube` | `samplerCube,vec3 -> color,vec3` | fragment/all | sample cubemap | solo fragment | Confirmado |

#### Input

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `input/time` | `-> time` | any/all | tiempo global | mapea a `TIME` | Confirmado |
| `input/screen_uv` | `-> screen_uv` | fragment/spatial+canvas+fullscreen | coordenadas de pantalla | no deberia usarse fuera de esos dominios, pero no se valida | Confirmado |
| `input/vertex_normal` | `-> normal` | vertex+fragment/spatial | normal de superficie | `domain_support` no se valida | Confirmado |
| `input/world_position` | `-> world_position` | vertex/spatial | posicion de mundo | cruzarlo a fragment no genera varying | Confirmado |
| `input/view_direction` | `-> view_direction` | fragment/spatial | direccion de vista | spatial only en intencion, no en validacion | Confirmado |
| `input/uv` | `-> uv` | vertex+fragment/spatial+canvas+particles | UV principal | amplio pero sin filtro UI | Confirmado |
| `input/uv2` | `-> uv` | vertex+fragment/spatial+canvas | UV2 | idem | Confirmado |
| `input/vertex_color` | `-> color` | vertex+fragment/spatial+canvas | color de vertice | puede truncarse a vec3 con warning | Confirmado |
| `input/frag_coord` | `-> vec2` | fragment/spatial+canvas+fullscreen | posicion de pixel | no filtrado por dominio | Confirmado |
| `input/screen_texture` | `-> color,vec3,float,float,float,float` | fragment/spatial+canvas+fullscreen | leer color de pantalla | auto-uniform `_sgs_screen_tex`; requiere contexto de screen texture | Confirmado |
| `input/depth_texture` | `-> float` | fragment/spatial | leer depth buffer | auto-uniform `_sgs_depth_tex`; spatial only en intencion | Confirmado |
| `input/canvas_texture` | `-> color,vec3,float,float,float,float` | fragment/canvas+fullscreen | sample `TEXTURE` 2D | sin filtro UI por dominio | Confirmado |
| `input/canvas_vertex` | `-> vec2` | vertex/canvas+fullscreen | vertice 2D | usarlo en spatial puede generar shader invalido | Confirmado |
| `input/particles_velocity` | `-> vec3` | any/particles | velocity de particula | depende de shader_type particles | Confirmado |
| `input/particles_color` | `-> color` | any/particles | color de particula | idem | Confirmado |
| `input/particles_index` | `-> float` | any/particles | indice de particula | cast de `INDEX` a float | Confirmado |
| `input/particles_lifetime` | `-> float,float` | any/particles | lifetime y life normalizada | usa `CUSTOM.y`; semantica del life no esta documentada fuera del codigo | Confirmado |
| `input/particles_random` | `-> float` | any/particles | valor random | usa `CUSTOM.x` | Confirmado |
| `input/sky_eyedir` | `-> vec3` | fragment/sky | direccion del rayo | preview no soportado | Confirmado |
| `input/sky_light_direction` | `-> vec3` | fragment/sky | direccion del sol | preview no soportado | Confirmado |
| `input/sky_light_color` | `-> vec3` | fragment/sky | color del sol | preview no soportado | Confirmado |
| `input/sky_light_energy` | `-> float` | fragment/sky | energia del sol | preview no soportado | Confirmado |
| `input/sky_position` | `-> vec3` | fragment/sky | posicion de camara | preview no soportado | Confirmado |
| `input/fog_world_position` | `-> vec3` | fragment/fog | posicion de mundo para fog | preview no soportado | Confirmado |
| `input/fog_view_direction` | `-> vec3` | fragment/fog | vista en fog | preview no soportado | Confirmado |
| `input/fog_sky_color` | `-> color` | fragment/fog | color de cielo en fog | preview no soportado | Confirmado |

#### Parameters

| ID | IO | Scope declarado | Uso tipico | Limites y defaults | Estado |
| --- | --- | --- | --- | --- | --- |
| `parameter/float` | `-> float` | any/all | uniform float | nombre default `my_param`; default `0.0` | Confirmado |
| `parameter/vec4` | `-> vec4` | any/all | uniform vec4 | default `vec4(0.0, 0.0, 0.0, 1.0)` | Confirmado |
| `parameter/color` | `-> color` | any/all | uniform color | usa hint `source_color`; default blanco | Confirmado |
| `parameter/texture2d` | `-> sampler2D` | any/all | uniform texture2D | sin picker de textura en el panel propio | Confirmado |

#### Output

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `output/spatial` | `vec3,float,float,vec3,vec3,float,float ->` | fragment/spatial | salida PBR spatial | defaults implicitos si faltan conexiones; no exige unicidad | Confirmado |
| `output/vertex_offset` | `vec3 ->` | vertex/spatial | desplazar `VERTEX` | convive con `output/spatial`; no crea varying | Confirmado |
| `output/canvas_item` | `color,vec3,float ->` | fragment/canvas_item | salida 2D | compila como `shader_type canvas_item` | Confirmado |
| `output/fullscreen` | `color ->` | fragment/fullscreen | postprocess/fullscreen | emite como `shader_type canvas_item` | Confirmado |
| `output/particles` | `vec3,color,color,float ->` | fragment/particles | salida de particulas | emite en `process()`; preview real pendiente | Confirmado |
| `output/sky` | `vec3,float,color ->` | fragment/sky | shader sky | preview no soportado | Confirmado |
| `output/fog` | `vec3,float,vec3 ->` | fragment/fog | shader fog | preview no soportado | Confirmado |

#### Utility

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `utility/reroute` | `float -> float` | any/all | ordenar cables | tipo placeholder, transparente; la UI lo muestra compacto | Confirmado |
| `utility/custom_function` | `float,float,float,float -> float` | any/all | expresion GLSL custom | salida solo float; body sin sanitizar | Confirmado |
| `utility/subgraph` | `contrato dinamico` | any/all | embebido de subgrafo | path obligatorio; puertos leidos desde el `.gssubgraph`; elimina edges invalidos si el contrato cambia | Confirmado |

#### Subgraph

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `subgraph/input` | `-> float` | any/all | exponer entrada de subgrafo | depende de propiedad `input_name`; default `a` | Confirmado |
| `subgraph/output` | `float ->` | any/all | exponer salida de subgrafo | depende de propiedad `output_name`; default `out1` | Confirmado |

#### Effects

| ID | IO | Scope declarado | Uso tipico | Limites y advertencias | Estado |
| --- | --- | --- | --- | --- | --- |
| `effects/fresnel` | `vec3,vec3,float -> float` | fragment/spatial | rim/fresnel | spatial fragment only | Confirmado |
| `effects/normal_blend` | `vec3,vec3 -> vec3` | any/all | blend de normales | formula fija UDN simplificada | Confirmado |
| `effects/toon_ramp` | `float,float -> float` | any/all | posterize/cel shade | `steps` minimo via `max(steps,1.0)` | Confirmado |
| `effects/value_noise` | `uv,float -> float` | any/all | ruido procedural | agrega helper functions `_sgs_hash` y `_sgs_value_noise` | Confirmado |
| `effects/triplanar` | `sampler2D,vec3,vec3,float -> color,vec3` | fragment/spatial | proyeccion triplanar | spatial fragment only; helper `_sgs_triplanar` | Confirmado |
| `effects/dither` | `vec2,float -> float` | fragment/all | dither ordenado | helper `_sgs_dither` | Confirmado |
| `effects/dissolve` | `uv,float,float -> float` | any/all | mascara de dissolve | usa value noise helper; sin borde/emission extra | Confirmado |

### 7.5 Buenas practicas especificas para nodos

- Mantener un solo nodo `output/*` principal por grafo.
- Usar `parameter/*` para valores expuestos al material, no strings literales dispersos.
- Reservar `utility/custom_function` para formulas pequenas y locales.
- Evitar usar nodos de dominios distintos aunque la UI lo permita.
- No confiar en conexiones `vertex -> fragment` sin revisar el shader emitido.
- Usar `utility/reroute` para limpieza visual, no para cambiar semantica.

## 8. Documentacion completa de clases y scripts

### 8.1 Clases de runtime/core

| Nombre | Herencia | Ruta | Responsabilidad principal | Responsabilidades secundarias | Dependencias | Riesgos y observaciones |
| --- | --- | --- | --- | --- | --- | --- |
| `SGSTypes` | clase | `addons/ss_godot_shader_studio/core/types/sgs_types.gd` | enums y flags | semantic aliases | ninguna | `DOMAIN_*` y `STAGE_*` existen mas completos que su uso real |
| `TypeSystem` | clase estatica | `addons/ss_godot_shader_studio/core/types/type_system.gd` | compatibilidad y casts | nombres GLSL/display | `SGSTypes` | no soporta matrices/casts avanzados |
| `ShaderNodeDefinition` | `Resource` | `addons/ss_godot_shader_studio/core/registry/shader_node_definition.gd` | contrato declarativo de nodos | helper/auto-uniform metadata | `SGSTypes` | `properties_schema` y `supports_domain()` no usados por la UI/validacion |
| `NodeRegistry` | `Object` | `addons/ss_godot_shader_studio/core/registry/node_registry.gd` | catalogo singleton de definiciones | busqueda por texto/categoria | `ShaderNodeDefinition` | no tiene `unregister_definition`; `search()` no filtra por dominio |
| `StdlibRegistration` | clase | `addons/ss_godot_shader_studio/core/registry/stdlib_registration.gd` | registrar stdlib builtin | empaquetar helper functions | `NodeRegistry` | archivo monolitico, alto acoplamiento |
| `ShaderGraphDocument` | `Resource` | `addons/ss_godot_shader_studio/core/graph/shader_graph_document.gd` | almacenar grafo, metadata y frames | generar ids secuenciales | `ShaderGraphNodeInstance`, `ShaderGraphEdge` | `uuid` no se autogenera; `stage_config/parameters/subgraph_refs` casi inertes |
| `ShaderGraphNodeInstance` | `Resource` | `addons/ss_godot_shader_studio/core/graph/shader_graph_node_instance.gd` | encapsular instancia de nodo | almacenar propiedades y stage_scope | `ShaderNodeDefinition` | `preview_enabled` no se consume |
| `ShaderGraphEdge` | `Resource` | `addons/ss_godot_shader_studio/core/graph/shader_graph_edge.gd` | representar conexiones | ninguna | documento | modelo simple, sin metadata de cast |
| `ValidationEngine` | clase | `addons/ss_godot_shader_studio/core/validation/validation_engine.gd` | validacion previa a compile | clasificar warnings/errores | `TypeSystem`, `NodeRegistry` | no valida dominio ni varyings; stage pass solo mira `stage_scope` |
| `IRBuilder` | clase estatica | `addons/ss_godot_shader_studio/core/ir/ir_builder.gd` | construir IR ejecutable | defaults, uniforms, helpers, subgrafos | `TypeSystem`, `GraphSerializer`, `NodeRegistry` | `varyings` no se llena; defaults como strings GLSL; sin DCE |
| `ShaderGraphCompiler` | clase | `addons/ss_godot_shader_studio/core/compiler/shader_graph_compiler.gd` | emitir shader final por dominio | banner y ordenado de uniforms | `ValidationEngine`, `IRBuilder` | version interna `0.3.0-gdscript` desalineada; emision simple |
| `GraphSerializer` | clase | `addons/ss_godot_shader_studio/core/serializer/graph_serializer.gd` | JSON save/load | migration hook | modelo de documento | formato version 1 sin migraciones reales |

### 8.2 Clases de editor

| Nombre | Herencia | Ruta | Responsabilidad principal | Colaboraciones clave | Riesgos y observaciones |
| --- | --- | --- | --- | --- | --- |
| plugin principal | `EditorPlugin` | `addons/ss_godot_shader_studio/plugin.gd` | registrar UI, singleton e importadores | `ShaderEditorPanel`, `NodeRegistry`, import plugins | lifecycle central; si falla, todo el addon cae |
| panel principal | `Control` | `addons/ss_godot_shader_studio/editor/shader_editor_panel.gd` | nuevo/abrir/guardar/compilar/cambiar dominio | canvas, preview, output, serializer, compiler | no expone configuraciones avanzadas; guarda y compila acoplados |
| canvas | `GraphEdit` | `addons/ss_godot_shader_studio/editor/graph_canvas.gd` | interaccion de grafo | NodeRegistry, undo/redo, node widgets | script grande y denso; mezcla UI y politicas de defaults |
| widget de nodo | `GraphNode` | `addons/ss_godot_shader_studio/editor/graph_node_widget.gd` | representar puertos/titulo/estado validacion | canvas | sin colores por tipo; `reroute` tiene tratamiento especial |
| popup de busqueda | `PopupPanel` | `addons/ss_godot_shader_studio/editor/node_search_popup.gd` | buscar y elegir nodos | `NodeRegistry`, canvas | no filtra por dominio ni ordena explicitamente |
| inspector | `PanelContainer` | `addons/ss_godot_shader_studio/editor/node_inspector.gd` | editar propiedades de nodo/frame | panel principal, `EditorFileDialog` | no interpreta `properties_schema`; todo es texto salvo casos especiales |
| panel de parametros | `PanelContainer` | `addons/ss_godot_shader_studio/editor/parameters_panel.gd` | listar `parameter/*` | documento | no sincroniza `doc.parameters`; solo nodos |
| salida de compilacion | `PanelContainer` | `addons/ss_godot_shader_studio/editor/compiler_output.gd` | mostrar estado/issues y copiar log | panel principal | no muestra shader generado |
| preview | `SubViewportContainer` | `addons/ss_godot_shader_studio/preview/shader_preview.gd` | preview visual | panel principal | `sky`/`fog` no preview; modos no conectados a UI |
| import plugin grafo | `EditorImportPlugin` | `addons/ss_godot_shader_studio/editor/shader_graph_import_plugin.gd` | import `.gshadergraph` | `ShaderGraphResource` | declara `Resource` generico |
| import plugin subgrafo | `EditorImportPlugin` | `addons/ss_godot_shader_studio/editor/subgraph_import_plugin.gd` | import `.gssubgraph` | `ShaderGraphResource` | idem |
| wrapper importado | `Resource` | `addons/ss_godot_shader_studio/editor/shader_graph_resource.gd` | puente entre import y editor | plugin principal | delgado y estable |

### 8.3 Escenas de editor/preview

| Escena | Ruta | Estructura interna | Uso |
| --- | --- | --- | --- |
| `shader_editor_panel.tscn` | `addons/ss_godot_shader_studio/editor/shader_editor_panel.tscn` | toolbar + `HSplitContainer` + `GraphCanvas` + preview + output | pantalla principal |
| `graph_canvas.tscn` | `addons/ss_godot_shader_studio/editor/graph_canvas.tscn` | `GraphEdit` + popup de busqueda | canvas |
| `graph_node_widget.tscn` | `addons/ss_godot_shader_studio/editor/graph_node_widget.tscn` | `GraphNode` base con VBox placeholder | nodos |
| `node_search_popup.tscn` | `addons/ss_godot_shader_studio/editor/node_search_popup.tscn` | `LineEdit` + `ItemList` | busqueda |
| `node_inspector.tscn` | `addons/ss_godot_shader_studio/editor/node_inspector.tscn` | labels + scroll + container de propiedades | inspector |
| `parameters_panel.tscn` | `addons/ss_godot_shader_studio/editor/parameters_panel.tscn` | header + scroll + lista | parametros |
| `compiler_output.tscn` | `addons/ss_godot_shader_studio/editor/compiler_output.tscn` | header + copy + rich text | log |
| `shader_preview.tscn` | `addons/ss_godot_shader_studio/preview/shader_preview.tscn` | `SubViewport` + `Node3D` + camara + luz + capsula | preview 3D base |

## 9. Recursos, escenas y tipos de datos propios

### 9.1 Formatos y recursos propios reales

| Tipo | Ruta/clase | Representa | Serializacion | Estado |
| --- | --- | --- | --- | --- |
| `.gshadergraph` | JSON via `GraphSerializer` | grafo shader fuente | JSON stringificado con indentacion | Confirmado |
| `.gssubgraph` | mismo serializer, dominio `subgraph` | subgrafo reusable | mismo formato que `.gshadergraph` | Confirmado |
| `.generated.gdshader` | texto GLSL de Godot | shader compilado | escritura directa en disco | Confirmado |
| `ShaderGraphDocument` | `Resource` | documento vivo en memoria | serializer custom | Confirmado |
| `ShaderGraphResource` | `Resource` | wrapper importado con `source_path` | `ResourceSaver` | Confirmado |
| frame/comment | `Dictionary` | bloque visual agrupador | embebido en JSON | Confirmado |

### 9.2 Estructura real del `.gshadergraph`

Campos confirmados por `GraphSerializer`:

- `format_version`
- `uuid`
- `name`
- `shader_domain`
- `stage_config`
- `nodes`
- `edges`
- `frames`
- `parameters`
- `subgraph_refs`
- `editor_state`

Campos mencionados por docs previas pero no implementados en serializer actual:

- `created_at`
- `modified_at`
- `compiler_version`

Estado: confirmado como discrepancia documental.

### 9.3 Validaciones y persistencia

- `GraphSerializer.save()` guarda solo lo que el documento conoce actualmente.
- `GraphSerializer.load()` no valida extension; parsea JSON y migra si hiciera falta.
- `_migrate()` es un no-op. Confirmado.
- `uuid` no se autogenera al crear documento nuevo. Confirmado.

### 9.4 Escenas relevantes

- `shader_editor_panel.tscn`: orquestador visual principal.
- `shader_preview.tscn`: preview 3D con capsula, camara y directional light.
- `graph_canvas.tscn`: canvas y popup.
- No hay escenas runtime del addon para el juego final. Confirmado.

### 9.5 Recursos/metadata tecnicos Godot

- `.uid` y archivos dentro de `.godot/` son metadata del editor. Relevancia funcional baja.
- `.import` de grafos confirma que el importador reconocido es `ss_godot_shader_studio.gshadergraph` y guarda un `Resource` wrapper.

## 10. Herramientas de editor e interfaz

### 10.1 Pantalla principal

- Nombre visible: `Shader Studio`. Confirmado.
- Ubicacion: main screen del editor. Confirmado.
- Icono: `VisualShader` de `EditorIcons`. Confirmado.

### 10.2 Dock lateral

- Nombre del dock: `Shader Studio`.
- Estructura: `TabContainer` con tabs `Properties` y `Parameters`.
- Dock slot: `DOCK_SLOT_RIGHT_UL`.

### 10.3 Toolbar superior

| Elemento | Aparicion | Funcion | Limitaciones |
| --- | --- | --- | --- |
| `New` | siempre | crea documento spatial nuevo y agrega `output/spatial` | no genera UUID |
| `New Subgraph` | siempre | crea documento `subgraph` vacio | no agrega nodos `subgraph/input/output` automaticamente |
| `Open` | siempre | abre `EditorFileDialog` para `.gshadergraph` o `.gssubgraph` | sin recientes ni drag-drop especial |
| `Save` | siempre | guarda sobre la ruta actual; si el archivo aun no existe o el nombre/extensión no son validos, abre el selector con una sugerencia normalizada | para subgraphs no compila shader standalone |
| `Save As` | siempre | siempre pregunta ubicacion y nombre con sugerencia `snake_case` y extension correcta | no borra el archivo previo; es copia/renombre explicito |
| `Compile` | siempre | compila manualmente, actualiza preview y log | subgraph no compila directo |
| `Domain` dropdown | siempre | cambia dominio y reemplaza output principal | no filtra nodos existentes por dominio |

Reglas operativas de guardado confirmadas:

- Primer guardado: sugiere `res://shader_assets/graphs` o `res://shader_assets/subgraphs` segun el dominio.
- Nombres de archivo: se normalizan automaticamente a `snake_case`.
- Extensiones: `subgraph` siempre se guarda como `.gssubgraph`; el resto como `.gshadergraph`.
- Ubicaciones problemáticas: el editor advierte si intentas guardar dentro de `res://addons/` o `res://.godot/`.
- Shader derivado: en grafos normales, la primera generacion pide una carpeta de salida antes de escribir el `.generated.gdshader`.
- Nombre derivado: el archivo generado conserva el basename normalizado del graph fuente y se guarda en la carpeta elegida.
- Persistencia de salida: la carpeta elegida se guarda en `editor_state.generated_shader_dir` dentro del documento fuente.

### 10.4 Graph canvas

Capacidades confirmadas:

- Doble click izquierdo en canvas vacio abre busqueda de nodos.
- Conectar y desconectar puertos via `GraphEdit`.
- `right_disconnects = true`.
- Multi-select.
- Delete de nodos y frames.
- `Ctrl/Cmd+C`: copy.
- `Ctrl/Cmd+V`: paste.
- `Ctrl/Cmd+D`: duplicate.
- `Ctrl/Cmd+G`: crear frame.
- Sync de posiciones y attached nodes al documento antes de save/compile.
- Overlay de validacion en titlebar del nodo.

### 10.5 Popup de busqueda

- Query libre contra `NodeRegistry.search()`.
- Muestra `DisplayName [Category]`.
- No filtra por dominio, stage o contexto actual. Confirmado.

### 10.6 Inspector de nodo

Comportamiento confirmado:

- Muestra `title`.
- Recorre propiedades existentes del `ShaderGraphNodeInstance`.
- Usa editores genericos de texto salvo:
  - `body`: `TextEdit`
  - `subgraph_path`: `LineEdit` + boton de browse
- Para frames, solo expone `title`.

### 10.7 Parameters panel

- Lista nodos `parameter/*` encontrados en el documento.
- Permite editar `param_name`.
- Permite editar `default_value` salvo `parameter/texture2d`.
- No crea ni mantiene `doc.parameters`. Confirmado.

### 10.8 Compiler output

- Muestra `Compile successful` o `Compile failed`.
- Enumera `issues` con color y copia version plain text al clipboard.
- No muestra el codigo shader generado.
- El boton `Copy` copia el log, no el shader. Confirmado.

### 10.9 Preview

| Dominio/Tipo | Comportamiento confirmado |
| --- | --- |
| `spatial` | aplica shader a una capsula 3D |
| `canvas_item` | usa `ColorRect` dentro de `SubViewportContainer` 2D |
| `fullscreen` | mismo flujo que `canvas_item` |
| `particles` | el codigo lo trata como preview 2D; la fidelidad real queda pendiente de validacion manual |
| `sky` | preview desactivado silenciosamente |
| `fog` | preview desactivado silenciosamente |

Comportamiento operativo confirmado:

- el panel programa recompilacion con debounce despues de cambios de grafo, propiedades y parametros
- el preview tambien se refresca si cambia en disco un `.gssubgraph` referenciado por el documento actual
- `Compile` sigue existiendo como accion explicita para ver diagnosticos completos en el panel Output

Modos de preview internos:

- `FULL`
- `CHANNEL_R`
- `CHANNEL_G`
- `CHANNEL_B`
- `ALPHA`
- `UV`

Limitacion confirmada: no existe UI conectada a `set_preview_mode()`, asi que esos modos no son accesibles desde la interfaz actual.

### 10.10 Integracion con filesystem/import

- `.gshadergraph` y `.gssubgraph` se importan como `Resource`.
- El plugin `_handles()` solo edita objetos `ShaderGraphResource`.
- `_edit()` usa `source_path` para cargar el archivo fuente.
- Efecto practico: el usuario edita el archivo JSON fuente, no el wrapper `.res`.

## 11. Señales, eventos y flujo de ejecucion

### 11.1 Señales custom confirmadas

| Señal | Emisor | Payload | Uso |
| --- | --- | --- | --- |
| `node_selected_in_canvas` | `GraphCanvas` | `ShaderGraphNodeInstance` | alimentar inspector |
| `frame_selected_in_canvas` | `GraphCanvas` | `Dictionary`, `GraphFrame` | inspeccionar frame |
| `graph_changed` | `GraphCanvas` | none | revalidar y refrescar parametros |
| `node_chosen` | `NodeSearchPopup` | `def_id`, `graph_pos` | crear nodo en canvas |

### 11.2 Secuencia de inicializacion

```text
EditorPlugin._enter_tree()
  -> crea NodeRegistry
  -> StdlibRegistration.register_all()
  -> Engine.register_singleton("NodeRegistry")
  -> instancia ShaderEditorPanel
  -> agrega main screen
  -> instancia NodeInspector + ParametersPanel
  -> crea dock TabContainer
  -> registra import plugins
```

### 11.3 Secuencia de apertura de archivo

```text
Seleccion de ShaderGraphResource
  -> EditorPlugin._edit(object)
  -> ShaderEditorPanel.open_file(source_path)
  -> GraphSerializer.load(path)
  -> GraphCanvas.load_document(doc)
  -> clear output/preview
  -> sync dropdown de dominio
  -> ValidationEngine.validate()
  -> GraphCanvas.apply_validation_result()
  -> ParametersPanel.refresh()
```

### 11.4 Secuencia de edicion

```text
Usuario agrega/conecta/borra nodo
  -> GraphCanvas modifica documento y/o widgets
  -> emite graph_changed
  -> ShaderEditorPanel._on_graph_changed()
  -> ValidationEngine.validate()
  -> overlay de errores/warnings
  -> refresh de ParametersPanel
```

### 11.5 Secuencia de compilacion/guardado

```text
Save
  -> GraphCanvas.sync_positions_to_document()
  -> normalizar nombre a snake_case y extension segun dominio
  -> GraphSerializer.save()
  -> si dominio != subgraph:
       -> ShaderGraphCompiler.compile_gd()
       -> CompilerOutput.show_result()
       -> ShaderPreview.apply_shader()
       -> si falta carpeta de salida: preguntar carpeta para generated shader
       -> escribir `.generated.gdshader` en la carpeta elegida
```

### 11.6 Cleanup

```text
EditorPlugin._exit_tree()
  -> remove dock
  -> free editor panel
  -> remove import plugins
  -> Engine.unregister_singleton("NodeRegistry")
```

### 11.7 Puntos criticos de sincronizacion y orden

- `ShaderEditorPanel.setup_undo_redo()` debe llegar al canvas para que haya historial. Confirmado.
- `graph_changed` es la via principal de refresco visual y de validacion. Confirmado.
- `sync_positions_to_document()` es necesario antes de save/compile para persistir posiciones y frames. Confirmado.
- Error confirmado de arquitectura: el pipeline no inserta varyings para dependencias vertex -> fragment.

## 12. Capacidades del addon

### 12.1 Que si se puede hacer

- Crear shaders visuales custom en dominios soportados.
- Serializar grafos a JSON versionable.
- Generar `.gdshader` determinista para casos cubiertos por la stdlib actual.
- Definir uniforms mediante nodos parametro.
- Incrustar subgrafos con contrato dinamico reflejado en el wrapper.
- Usar funciones helper auto-inyectadas y auto-uniforms.
- Agrupar nodos en frames/comentarios.
- Buscar nodos por nombre, id o keyword.
- Copiar, pegar y duplicar subgrafos seleccionados.
- Extender el catalogo builtin registrando nuevas definiciones desde otro addon.

### 12.2 Que no se puede hacer

- Compilar un documento `subgraph` como shader standalone.
- Obtener validacion robusta por dominio.
- Obtener varyings automaticos entre stages.
- Usar `properties_schema` para generar inspector typed.
- Previsualizar `sky` o `fog` dentro del addon.
- Tener preview por nodo individual.
- Cubrir import plugins y el ciclo completo de `EditorPlugin` desde la suite actual.

### 12.3 Que solo se puede hacer parcialmente

- Previsualizacion `canvas_item/fullscreen`: existe, pero es simplificada.
- Previsualizacion `particles`: el codigo intenta una ruta 2D, pero la fidelidad real requiere validacion manual.
- Extension por addons externos: el registro funciona, pero no hay API de unregistration ni capa de compatibilidad formal.
- Multi-domain authoring: el compilador emite varios dominios, pero la UI y la validacion no bloquean combinaciones invalidas.

### 12.4 Que depende del contexto

- Si un shader generado es valido para Godot depende de no mezclar builtins de dominios incompatibles.
- Si un cruce de stages funciona depende de que no haya referencias vertex usadas luego en fragment sin varying.
- La utilidad del preview depende del dominio y del tipo de nodo usado.

### 12.5 Falsas expectativas probables

- "Hay backend C++/GDExtension": falso en este arbol actual.
- "La docs de graph format refleja exactamente el serializer": falso.
- "Los nodos se filtran segun dominio": falso.
- "La opcion `PreviewMode` esta accesible en UI": falso.
- "El panel Parameters refleja `doc.parameters`": falso.

## 13. Guias de uso paso a paso

### 13.1 Primer contacto

1. Habilita el plugin.
2. Abre `Shader Studio`.
3. Observa el grafo nuevo con `Spatial Output`.
4. Doble click en canvas vacio.
5. Busca `append vec3`.
6. Conecta `result` a `output/spatial.albedo`.
7. Compila.
8. Guarda el grafo para persistir el `.gshadergraph`.
9. La primera vez que se vaya a escribir el shader compilado, el editor pide la carpeta de salida del `.generated.gdshader`.

### 13.2 Caso basico: material spatial con roughness procedural

1. Crea un grafo `spatial`.
2. Agrega `math/add`.
3. Agrega `math/multiply`.
4. Conecta `add.result -> multiply.a`.
5. Conecta `multiply.result -> output/spatial.roughness`.
6. Ajusta defaults en inspector si quieres cambiar las constantes.
7. Compila y revisa `Output`.

Resultado esperado:

- shader spatial con `void fragment()`
- una o dos temporales `_tN`
- asignacion final a `ROUGHNESS`

### 13.3 Caso intermedio: fullscreen effect con parametros

1. Crea grafo `fullscreen`.
2. Agrega `input/screen_texture`.
3. Agrega `color/rgb_to_hsv`.
4. Agrega `swizzle/split_vec3`.
5. Agrega `parameter/float` para hue.
6. Agrega `parameter/float` para saturation.
7. Agrega `swizzle/append_vec3`.
8. Agrega `color/hsv_to_rgb`.
9. Conecta salida RGB final a `output/fullscreen.color`.
10. Guarda y verifica que el compilador emite uniforms.

Este flujo sigue siendo valido para cualquier ejemplo fullscreen del repo; al volver a guardarlo, el editor normaliza el nombre a `snake_case`. Confirmado.

### 13.4 Caso avanzado: encapsular logica reusable

1. Crea `New Subgraph`.
2. Agrega `subgraph/input` y configura `input_name` y `input_type`.
3. Agrega logica intermedia.
4. Agrega `subgraph/output` y configura `output_name` y `output_type`.
5. Guarda como `.gssubgraph`.
6. En un grafo normal, agrega `utility/subgraph`.
7. Usa el inspector para elegir `subgraph_path`.
8. Observa que el wrapper actualiza sus puertos con la firma real del subgrafo.
9. Conecta una fuente a la entrada expuesta y consume la salida expuesta.

Advertencia confirmada:

- la firma visible depende del archivo `.gssubgraph`, no del nodo wrapper
- los nombres pueden cambiar sin romper edges mientras el `port_id` interno siga existiendo
- eliminar puertos o cambiar tipos puede requerir reconectar edges si el contrato ya no es compatible

### 13.5 Integracion en proyecto real

Flujo recomendado:

1. Mantener `*.gshadergraph` y `*.generated.gdshader` bajo control de versiones.
2. Editar solo el grafo fuente en `Shader Studio`.
3. Recompilar/guardar y usar el shader generado en materiales del juego.
4. Si el proyecto no necesitara authoring en runtime, el juego final solo depende del shader generado.

### 13.6 Ejemplo de uso correcto

- Grafo `spatial`.
- Nodos `input/uv -> texture/sample_2d -> output/spatial.albedo`.
- `parameter/float` conectado a `roughness`.
- Sin mezclar nodos `canvas`/`sky`.

### 13.7 Ejemplo de uso incorrecto

- Grafo `spatial` usando `input/canvas_vertex`.
- Conexion de `input/world_position` directamente a un nodo fragment sin revisar el shader.
- Multiples `output/spatial` esperando comportamiento definido.

### 13.8 Depuracion de caso problematico

Caso: el shader compila pero Godot lo rechaza o renderiza mal.

1. Revisa el dominio seleccionado.
2. Revisa el panel `Output` para warnings y errores.
3. Inspecciona el `.generated.gdshader`.
4. Busca usos de builtins ajenos al dominio.
5. Busca temporales generadas en `vertex()` consumidas en `fragment()`.
6. Simplifica el grafo hasta un output minimo.
7. Reintroduce nodos poco a poco.

## 14. Arquitectura interna

### 14.1 Modulos principales

```text
EditorPlugin
  -> ShaderEditorPanel
       -> GraphCanvas
       -> NodeInspector
       -> ParametersPanel
       -> CompilerOutput
       -> ShaderPreview

Core
  -> NodeRegistry + StdlibRegistration
  -> ShaderGraphDocument / NodeInstance / Edge
  -> ValidationEngine
  -> IRBuilder
  -> ShaderGraphCompiler
  -> GraphSerializer
```

### 14.2 Flujo de datos

```text
NodeRegistry
  -> define contratos de nodo

ShaderGraphDocument
  -> contiene instancias y conexiones

ValidationEngine
  -> produce issues

IRBuilder
  -> resuelve inputs/defaults/uniforms/helpers

ShaderGraphCompiler
  -> emite .gdshader

ShaderEditorPanel
  -> serializa, compila, previsualiza
```

### 14.3 Puntos de entrada

- `plugin.gd::_enter_tree()` para ciclo de vida del addon.
- `shader_editor_panel.gd::open_file()` para abrir grafos.
- `GraphCanvas` para interaccion de usuario.
- `ShaderGraphCompiler.compile_gd()` para compilacion programatica.
- `GraphSerializer.save/load()` para persistencia.

### 14.4 Puntos de extension

- `Engine.get_singleton("NodeRegistry")` desde otros addons.
- `NodeRegistry.register_definition(def)`.
- `ShaderNodeDefinition.compiler_template`.
- `ShaderNodeDefinition.helper_functions`.
- `ShaderNodeDefinition.auto_uniform`.

### 14.5 Separacion editor vs runtime

Fortaleza confirmada:

- el core no depende del `GraphEdit` ni de escenas editor
- el shader generado runtime no necesita el plugin

Debilidad confirmada:

- `graph_canvas.gd` concentra UI, defaults, copy/paste, frames y parte de politica de datos
- la linea entre metadata declarativa (`properties_schema`) y controles editor reales no esta cerrada

### 14.6 Acoplamientos importantes

- `NodeRegistry` como singleton Engine es dependencia transversal.
- `IRBuilder` conoce strings de nodos especiales (`parameter/*`, `utility/reroute`, `utility/subgraph`, `subgraph/*`).
- `GraphCanvas` siembra propiedades default de varios nodos especiales.
- `ShaderEditorPanel` acopla save con compile y preview.

### 14.7 Trade-offs visibles

- GDScript puro simplifica contribucion y elimina build step.
- Templates GLSL como string reducen complejidad inicial, pero exponen riesgos de sintaxis y sanitizacion.
- Registro centralizado facilita inventario, pero escala mal.

## 15. Limitaciones tecnicas y restricciones

| Limitacion | Evidencia | Impacto | Estado |
| --- | --- | --- | --- |
| `plugin.cfg` aun habla de backend C++ nativo | descripcion actual del plugin | confunde instalacion y alcance tecnico | Confirmado |
| Versiones desalineadas (`plugin.cfg` 0.1.0, compiler 0.3.0-gdscript, manifest 0.6.0) | archivos de configuracion y codigo | dificulta soporte y trazabilidad | Confirmado |
| `domain_support` no se usa en validacion ni UI | solo existe en definicion | se pueden construir grafos semanticamente invalidos | Confirmado |
| No hay varyings reales | `IRBuilder` crea `varyings=[]` pero nunca los llena; compiler no los emite | conexiones vertex -> fragment pueden generar shaders invalidos | Confirmado |
| `stage_config` se serializa pero no gobierna emision | solo aparece en document/serializer | falsa sensacion de control de pipeline | Confirmado |
| `properties_schema` existe pero no genera UI ni validacion | solo definido en clase/docs | extension de nodos incompleta | Confirmado |
| `parameters` y `subgraph_refs` del documento estan inertes | serializer/document, sin integracion editor | formato adelantado a implementacion | Confirmado |
| `preview_enabled` existe pero no hace nada observable | campo en nodo/serializer, sin consumo | feature incompleta | Confirmado |
| No hay DCE/optimizacion | docs previas lo mencionan como futuro; codigo no lo hace | nodos muertos compilan igual | Confirmado |
| No se genera `uuid`, timestamps ni `compiler_version` en el JSON | serializer y ejemplos | metadata de trazabilidad incompleta | Confirmado |
| No hay sanitizacion de nombres/cuerpos GLSL | sustitucion por strings | riesgo de shader invalido o injection accidental | Confirmado |
| No se fuerza unicidad de output node | validador solo exige presencia | comportamiento ambiguo con multiples outputs | Confirmado |
| `sky` y `fog` no tienen preview | `shader_preview.gd` los desactiva | menor ergonomia | Confirmado |
| Modos `R/G/B/Alpha/UV` no tienen UI | `set_preview_mode()` nunca se llama | feature escondida/inaccesible | Confirmado |
| No hay ejemplos `.gssubgraph` | busqueda de archivos vacia | curva de adopcion mayor | Confirmado |
| No hay tests de import plugins ni del ciclo completo de `EditorPlugin` | suite actual | regresiones de integracion aun posibles fuera de panel/canvas/preview | Confirmado |
| `.gitmodules` conserva `godot-cpp` pero no existe `native/` | inspeccion de repo | deuda historica/documental | Confirmado |
| `README.md` refiere `LICENSE`, pero no existe en este checkout | archivo faltante | problema de distribucion/legalidad documental | Confirmado |
| Preview de `particles` podria no ser representativo | el codigo lo trata como material 2D sobre `ColorRect` | requiere validacion manual | Pendiente de validacion |

## 16. Buenas practicas recomendadas

- Tratar siempre `*.gshadergraph` y `*.gssubgraph` como fuente de verdad.
- Commitear tambien `*.generated.gdshader`.
- Mantener un solo nodo `output/*` por documento.
- Mantener nombres de uniforms ASCII, sin espacios ni keywords GLSL.
- Usar `parameter/*` para valores expuestos al juego/material.
- Revisar el shader generado cuando uses nodos vertex-only o dominios avanzados.
- Evitar mezclar nodos de distintos dominios aunque el editor lo permita.
- Preferir subgrafos pequenos y con contrato simple, dadas sus limitaciones actuales.
- Para extensiones externas, usar prefijos de namespace en `def.id`, por ejemplo `miaddon/foo`.
- Mantener pruebas del core al dia y agregar fixtures grafo/shader cuando se anadan nodos complejos.

## 17. Anti-patrones y errores comunes

| Anti-patron | Que ocurre | Por que ocurre | Como detectarlo | Como corregirlo | Prevencion |
| --- | --- | --- | --- | --- | --- |
| Mezclar nodos canvas en spatial | shader invalido o semantica rara | no hay filtro por dominio | revisar generated shader y builtins usados | reemplazar por nodos del dominio correcto | trabajar por dominio cerrado |
| Conectar salida vertex a output fragment | uso de temporales fuera de scope | no hay varyings | generated shader usa `_tN` en `fragment()` sin declaracion global | reestructurar grafo o escribir shader manual | evitar cruces de stage |
| Usar nombres de uniform con espacios | GLSL invalido | no hay sanitizacion | compile success local pero error en Godot shader | renombrar `param_name` | convencion de nombres valida |
| Meter un bloque GLSL entero en `body` | salida invalida | custom function envuelve en `float result = <body>;` | shader roto alrededor del nodo | escribir solo expresion escalar | reservar el nodo para formulas simples |
| Esperar que Parameters panel sincronice `doc.parameters` | docs/format quedan inconsistentes | panel trabaja solo con nodos `parameter/*` | `doc.parameters` sigue vacio | ignorar `doc.parameters` o implementarlo | tratarlo como campo inactivo |
| Confiar en `properties_schema` para UI | nada aparece | no hay consumo de schema | inspector vacio salvo props ya existentes | sembrar props y/o extender inspector | documentar requerimientos de nuevos nodos |
| Duplicar outputs | asignaciones multiples a builtins | no hay unicidad | generated shader con multiples `ALBEDO =` o similares | dejar un output por documento | review manual del grafo |
| Guardar subgraph esperando `.generated.gdshader` | no se genera shader | dominio `subgraph` no compila | no aparece archivo generado | usar subgrafo solo como dependencia | separar claramente source graph vs subgraph |
| Suponer que el boton Copy copia shader | solo copia log | `compiler_output.gd` copia `_plain_text` | clipboard sin codigo GLSL | abrir archivo generado | aclararlo al equipo |
| Confiar en docs previas como especificacion final | decisiones erradas de integracion | docs adelantadas al codigo | comparar con serializer/compiler reales | usar este documento y revisar codigo | mantener doc y codigo sincronizados |

## 18. Troubleshooting

### Problema: compile success pero Godot muestra error de shader

- Sintomas: el addon compila, pero al usar el shader generado Godot lo rechaza.
- Posible causa: builtins de dominio incorrecto, nombre de uniform invalido o cruce de stages sin varying.
- Diagnostico: abrir el `.generated.gdshader` y buscar:
  - builtins no validos para el `shader_type`
  - temporales `_tN` producidas en `vertex()` y consumidas en `fragment()`
  - uniforms con nombres invalidos
- Solucion: corregir nodos, dominio o nombres; evitar cruces de stage.
- Prevencion: revisar shader generado en cambios importantes.

### Problema: no aparece ningun control editable en el inspector

- Sintomas: seleccionas un nodo y el panel `Properties` casi no muestra nada.
- Posible causa: ese nodo no tiene propiedades sembradas o `properties_schema` no esta implementado en la UI.
- Diagnostico: revisar `node_inst.properties`.
- Solucion: editar defaults via conexiones o extender la UI si el nodo nuevo necesita propiedades.
- Prevencion: al anadir nodos custom, sembrar props iniciales en `GraphCanvas.apply_port_defaults()`.

### Problema: no veo parametros en el panel `Parameters`

- Sintomas: el panel dice `No parameters`.
- Posible causa: no hay nodos `parameter/*` en el grafo.
- Diagnostico: buscar `parameter`.
- Solucion: anadir nodos parametro y volver al panel.
- Prevencion: usar nodos parametro siempre que un valor deba salir como uniform.

### Problema: un segundo cable no se conecta a una entrada

- Sintomas: arrastras una conexion y no pasa nada.
- Posible causa: `ShaderGraphDocument.add_edge()` rechaza duplicados al mismo input.
- Diagnostico: la entrada ya tenia una conexion.
- Solucion: desconectar la anterior o reroutear logica.
- Prevencion: pensar el grafo como un input = una fuente.

### Problema: sky o fog no muestran preview

- Sintomas: preview vacio.
- Posible causa: `shader_preview.gd` los desactiva.
- Diagnostico: leer rama `is_unsupported`.
- Solucion: probar el shader en una escena Godot real.
- Prevencion: asumir desde el inicio que preview embebido no cubre esos dominios.

### Problema: el archivo se importa pero no se abre en Shader Studio

- Sintomas: al hacer click en recurso importado no se ve la pantalla del addon.
- Posible causa: plugin deshabilitado o recurso no importado como `ShaderGraphResource`.
- Diagnostico: revisar plugins activos y metadata `.import`.
- Solucion: reactivar plugin y reimportar.
- Prevencion: mantener el addon instalado en el proyecto donde se edita el grafo.

## 19. Extension, personalizacion y contribucion

### 19.1 Como extender el addon hoy

Extension soportada de forma razonable:

1. Obtener `NodeRegistry` desde `Engine.get_singleton("NodeRegistry")`.
2. Crear `ShaderNodeDefinition`.
3. Completar `id`, `display_name`, `category`, `inputs`, `outputs`, `stage_support`, `domain_support`, `compiler_template`.
4. Registrar con `register_definition()`.

Ejemplo minimo:

```gdscript
var registry := Engine.get_singleton("NodeRegistry") as NodeRegistry
var d := ShaderNodeDefinition.new()
d.id = "myaddon/wobble"
d.display_name = "Wobble"
d.category = "MyAddon"
d.inputs = [
	{"id": "x", "name": "X", "type": SGSTypes.ShaderType.FLOAT, "default": 0.0, "optional": false}
]
d.outputs = [
	{"id": "result", "name": "Result", "type": SGSTypes.ShaderType.FLOAT}
]
d.stage_support = SGSTypes.STAGE_ANY
d.domain_support = SGSTypes.DOMAIN_ALL
d.compiler_template = "float {result} = sin({x});"
registry.register_definition(d)
```

### 19.2 Partes seguras de extender

- Nuevas definiciones de nodo puramente declarativas.
- Nuevos helpers GLSL por `helper_functions`.
- Nuevos auto-uniforms por `auto_uniform`.
- Nuevos tests del core.

### 19.3 Partes delicadas o no estables

- `IRBuilder`: contiene logica especial por string id.
- `GraphCanvas.apply_port_defaults()`: si agregas nodos especiales, probablemente debas tocarla.
- `NodeInspector`: hoy necesita casos especiales hardcoded.
- `ValidationEngine`: aun no refleja todo lo que prometen las docs previas.

### 19.4 Contratos implicitos que deben respetarse

- Los `id` de puertos deben coincidir con placeholders `{port_id}` del template.
- Los nombres de uniform deben ser GLSL validos.
- Los nodos special-case (`parameter/*`, `utility/subgraph`, `subgraph/*`, `utility/reroute`) tienen semantica extra en `IRBuilder`.
- Si agregas nodos domain-specific, hoy tu principal proteccion es la disciplina del autor, no la validacion del sistema.

### 19.5 Guia para contribuidores

1. Ejecutar Godot una vez para refrescar cache de clases si anades `class_name`.
2. Correr `godot --headless --path . --script test/runner.gd`.
3. Probar manualmente la UI si tocas `editor/` o `preview/`.
4. Actualizar docs y changelog junto con el codigo.
5. Evitar ampliar la discrepancia entre docs especificativas y comportamiento real.

## 20. Mantenimiento a largo plazo

### Componentes criticos

- `plugin.gd`
- `NodeRegistry` y `StdlibRegistration`
- `ValidationEngine`
- `IRBuilder`
- `ShaderGraphCompiler`
- `GraphSerializer`
- `graph_canvas.gd`

### Areas fragiles

- Integracion entre `stage_support`, `stage_scope` y emision real.
- Nodos especiales hardcoded en `IRBuilder`.
- Serializacion/documentacion de metadata no usada.
- Preview multi-dominio.
- Versionado y packaging.

### Dependencias peligrosas

- Reusable GitHub workflows en `slice-soft/ss-pipeline`.
- Suposicion de Godot 4.5 para APIs de editor.

### Donde falta cobertura de pruebas

- UI editor
- import plugins
- subgraphs end-to-end con archivos reales
- preview
- combinaciones invalidas de dominio
- cruces de stage
- nombres invalidos de uniforms y bodies GLSL

### Prioridades tecnicas sugeridas

1. Alinear versionado entre `plugin.cfg`, changelog, release manifest y compiler.
2. Implementar validacion por dominio y varyings reales.
3. Decidir el destino de `properties_schema`, `stage_config`, `parameters`, `subgraph_refs`, `preview_enabled`.
4. Agregar tests para subgraphs, editor e import pipeline.
5. Dividir `stdlib_registration.gd` por modulos/categorias.
6. Sanear `README`, `plugin.cfg`, docs de formato y assets de release.
7. Resolver el faltante de `LICENSE` en el checkout distribuido.

## 21. Referencia tecnica rapida

### 21.1 Dominios soportados

| Dominio | Output requerido | Funcion emitida |
| --- | --- | --- |
| `spatial` | `output/spatial` | `fragment()` y opcional `vertex()` |
| `canvas_item` | `output/canvas_item` | `fragment()` y opcional `vertex()` |
| `fullscreen` | `output/fullscreen` | `fragment()` y opcional `vertex()` en shader `canvas_item` |
| `particles` | `output/particles` | `process()` y opcional `start()` |
| `sky` | `output/sky` | `sky()` |
| `fog` | `output/fog` | `fog()` |
| `subgraph` | ninguno | no compila a shader directo |

### 21.2 Atajos

| Atajo | Accion |
| --- | --- |
| doble click canvas vacio | buscar/anadir nodo |
| `Ctrl/Cmd+C` | copiar nodos seleccionados |
| `Ctrl/Cmd+V` | pegar |
| `Ctrl/Cmd+D` | duplicar |
| `Ctrl/Cmd+G` | crear frame |
| `Ctrl+Shift+Z` | redo explicito del plugin |

### 21.3 Artefactos

| Artefacto | Fuente de verdad | Consumidor |
| --- | --- | --- |
| `.gshadergraph` | si | plugin + serializer |
| `.gssubgraph` | si | plugin + IRBuilder |
| `.generated.gdshader` | no, derivado | Godot runtime/materiales |
| `.res` importado | no, wrapper | Godot editor + plugin |

### 21.4 Resultado de pruebas de esta revision

| Suite | Assertions | Estado |
| --- | ---: | --- |
| `test_type_system` | 87 | PASS |
| `test_graph_document` | 32 | PASS |
| `test_validation_engine` | 19 | PASS |
| `test_ir_builder` | 23 | PASS |
| `test_compiler` | 39 | PASS |
| `test_subgraph_contracts` | 8 | PASS |
| `test_shader_graph_path_utils` | 5 | PASS |
| `test_shader_editor_panel_integration` | 21 | PASS |
| `test_graph_canvas_integration` | 14 | PASS |
| `test_shader_preview_integration` | 13 | PASS |
| Total | 261 | PASS |

## 22. FAQ

### Usuarios nuevos

**Que archivo debo editar realmente?**  
Edita el `.gshadergraph` o `.gssubgraph`. El `.generated.gdshader` es derivado.

**El addon reemplaza VisualShader de Godot?**  
No. Es una herramienta separada con formato, UI y compilador propios.

**Necesito el addon en el juego final?**  
No para ejecutar el shader ya generado. Si para seguir editando el grafo en el editor.

**Por que el panel Parameters esta vacio?**  
Porque solo lista nodos `parameter/*`.

### Usuarios avanzados

**Puedo usar nodos vertex en shaders fragment sin problema?**  
No de forma segura. El sistema no genera varyings automaticos.

**Puedo hacer subgrafos con contratos arbitrarios?**  
Si, dentro del conjunto de tipos soportados por `subgraph/input` y `subgraph/output`; el wrapper refleja nombres, tipos y cantidad de puertos del archivo interno.

**Puedo agregar mis propios nodos sin C++?**  
Si. Registra nuevas `ShaderNodeDefinition` en `NodeRegistry`.

**El panel inspector sale de `properties_schema`?**  
No en esta revision.

### Integradores

**Como abro un `.gshadergraph` desde el filesystem?**  
Godot lo importa como `ShaderGraphResource` y el plugin usa `source_path` para abrir el archivo fuente.

**Puedo confiar en `doc.parameters` y `doc.subgraph_refs`?**  
No como fuente operativa actual; el sistema real deriva uniforms desde nodos parametro y no mantiene `subgraph_refs` automaticamente.

### Desarrolladores/mantenedores

**Donde agrego nuevos nodos builtin?**  
En `core/registry/stdlib_registration.gd`.

**Donde se siembran propiedades default de nodos especiales?**  
En `editor/graph_canvas.gd`, metodo `apply_port_defaults()`.

**Donde se decide como se emite cada dominio?**  
En `core/compiler/shader_graph_compiler.gd`.

**Hay soporte oficial para unregister de nodos externos?**  
No.

## 23. Evaluacion critica del addon

### 23.1 Valoracion tecnica honesta

| Dimension | Valoracion | Comentario |
| --- | --- | --- |
| Claridad de arquitectura | Media-Alta | la division core/editor es buena |
| Coherencia interna | Media | hay buenas bases, pero varias capas no estan alineadas |
| Facilidad de uso | Media | el flujo principal funciona; faltan filtros y ayudas contextuales |
| Mantenibilidad | Media | el core es legible, pero hay scripts grandes y docs desalineadas |
| Extensibilidad | Media | registrar nodos es facil; integrarlos bien en UI/validacion no tanto |
| Escalabilidad | Media-Baja | stdlib monolitica y strings GLSL crudas limitan crecimiento |
| Experiencia de integracion | Media | importar/editar/guardar funciona, pero hay zonas grises |
| Robustez aparente | Media | 199 assertions en core, pero huecos fuertes en editor/dominios |
| Madurez de diseño | Media-Baja a Media | solido como prototipo serio, todavia no como plataforma cerrada |

### 23.2 Fortalezas principales

- Pipeline completo y legible en GDScript puro.
- Tests reales del nucleo.
- Separacion razonable entre editor y core.
- Extensibilidad basal via `NodeRegistry`.
- Soporte para varios dominios ya presente en compilador.

### 23.3 Debilidades principales

- Validacion incompleta de dominio y stage crossings.
- Versionado y documentacion desalineados.
- Muchas features "esqueleto" o a medio integrar.
- Preview y UX no cubren todos los dominios.
- Contratos especiales codificados por strings.

### 23.4 Riesgos inmediatos

- Generar shaders invalidos en combinaciones no filtradas por dominio/stage.
- Tomar decisiones de integracion basadas en docs previas y no en el codigo real.
- Agregar nuevos nodos creyendo que `properties_schema` ya funciona.
- Publicar el addon con versionado/licencia incoherentes.

### 23.5 Mejoras prioritarias

1. Validacion de dominio y varyings.
2. Unificacion de versionado y limpieza documental.
3. Tests editor/subgraph/import.
4. Activar o retirar metadata no usada.
5. Refactor del registro builtin y del canvas.

### 23.6 Mejoras deseables a mediano plazo

- Inspector tipado a partir de schema real.
- Preview configurables por dominio.
- Contratos dinamicos para subgrafos.
- Optimizacion IR (DCE, constant folding).
- Libreria de ejemplos y subgrafos reutilizables.

## 24. Salida final esperada y uso recomendado de esta documentacion

Este documento puede usarse como:

- manual tecnico base del repositorio
- punto de partida para wiki oficial
- guia de onboarding para usuarios del addon
- referencia para desarrolladores que quieran extenderlo
- checklist para mantenedores antes de una release estable

Uso recomendado:

1. Leer secciones 1, 2 y 6 para comprender el modelo mental.
2. Usar secciones 7, 10 y 21 como referencia diaria.
3. Revisar secciones 15, 17, 18 y 23 antes de integrar el addon en un pipeline de produccion.
4. Revisar secciones 19 y 20 antes de hacer cambios estructurales.

Resumen final honesto:

- El addon existe, funciona y compila shaders reales.
- El core esta mejor resuelto que la capa de UX y que la documentacion historica.
- Su principal deuda no es la ausencia de ideas, sino la falta de cierre entre metadata declarada, validacion efectiva y superficie de editor.
- Si se corrigen dominio/stage validation, versionado/documentacion y pruebas de editor, la base actual puede evolucionar a una herramienta mucho mas solida.
