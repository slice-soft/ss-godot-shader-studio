# Shader por altura en Shader Studio

## Objetivo

Crear un material `spatial` que cambie de textura según la altura local del objeto:

- abajo: textura A
- medio: textura B
- arriba: textura C

Las capas responden a la escala Y del objeto y usan umbrales absolutos (no normalizados).

---

## Paso a paso manual

### 1. Crear el graph

- Abre Shader Studio
- Clic en **New**
- Domain: **Spatial**
- El nodo `Spatial Output` ya aparece en el canvas

---

### 2. Nodos de textura (columna izquierda, arriba)

Agrega **3 nodos** `Texture2D Parameter`:

| Nodo | `param_name` | Descripción |
|------|-------------|-------------|
| Texture2D Parameter | `tex_bottom` | textura inferior |
| Texture2D Parameter | `tex_mid` | textura media |
| Texture2D Parameter | `tex_top` | textura superior |

Cada uno se busca en el menú como **"Texture2D Parameter"** o **"texture parameter"**.

Asigna una textura en el campo `Tex` de cada nodo si quieres verlo en el preview.

---

### 3. Nodo UV

Agrega un nodo **`UV`** (búscalo como "uv" o "texture coordinates").

Conéctalo:
- `UV.uv` → `Sample Bottom.uv`
- `UV.uv` → `Sample Mid.uv`
- `UV.uv` → `Sample Top.uv`

---

### 4. Nodos de muestreo

Agrega **3 nodos** `Sample Texture 2D` (búscalos como "sample" o "tex2d"):

- `tex_bottom.value` → `Sample Bottom.tex`
- `tex_mid.value` → `Sample Mid.tex`
- `tex_top.value` → `Sample Top.tex`

---

### 5. Nodo de altura

Agrega **`Vertex Position (Local)`** (búscalo como "vertex local" o "local vertex position").

> El IR del addon detecta automáticamente que este nodo solo existe en el vertex stage.
> No hay que configurar nada — el compilador lo coloca en `void vertex()` solo.

Puerto a usar: **`y`** (float — altura local del objeto)

---

### 6. Nodo de escala

Agrega **`Object Scale`** (búscalo como "object scale" o "lossyscale").

Puerto a usar: **`y`** (float — escala vertical del objeto en la escena)

---

### 7. Multiplicar altura por escala

Agrega **`Multiply`** (búscalo como "multiply" o "mul").

Conecta:
- `Vertex Position (Local).y` → `Multiply.a`
- `Object Scale.y` → `Multiply.b`

Salida: `Multiply.result` = altura local corregida por escala

---

### 8. Parámetros de umbral

Agrega **4 nodos** `Float Parameter` (búscalos como "float parameter"):

| Nodo | `param_name` | `default_value` | Significado |
|------|-------------|-----------------|-------------|
| Float Parameter | `mid_start` | `-0.4` | altura donde empieza la transición inferior→media |
| Float Parameter | `mid_end` | `0.0` | altura donde termina (capa media al 100%) |
| Float Parameter | `top_start` | `0.1` | altura donde empieza la transición media→superior |
| Float Parameter | `top_end` | `0.5` | altura donde termina (capa superior al 100%) |

Estos valores funcionan bien con el mesh **Capsule** del preview (Y local va de -1 a 1).
Para objetos reales, ajusta según la altura del mesh.

---

### 9. Máscaras de transición

Agrega **2 nodos** `Smoothstep` (búscalos como "smoothstep" o "smooth step"):

**Smoothstep Mid** — mezcla inferior→media:
- `mid_start.value` → `Smoothstep Mid.edge0`
- `mid_end.value` → `Smoothstep Mid.edge1`
- `Multiply.result` → `Smoothstep Mid.x`

**Smoothstep Top** — mezcla media→superior:
- `top_start.value` → `Smoothstep Top.edge0`
- `top_end.value` → `Smoothstep Top.edge1`
- `Multiply.result` → `Smoothstep Top.x`

> El IR del addon detecta automáticamente que `Multiply.result` viene del vertex stage
> y crea un `varying` para pasarlo al fragment stage. No hay que hacer nada manual.

---

### 10. Mezclar capas

Agrega **2 nodos** `Lerp Vector` (búscalos como "lerp vector" o "mix vector"):

**Lerp Bottom-Mid:**
- `Sample Bottom.rgb` → `Lerp Bottom-Mid.a`
- `Sample Mid.rgb` → `Lerp Bottom-Mid.b`
- `Smoothstep Mid.result` → `Lerp Bottom-Mid.t`

**Lerp Mid-Top:**
- `Lerp Bottom-Mid.result` → `Lerp Mid-Top.a`
- `Sample Top.rgb` → `Lerp Mid-Top.b`
- `Smoothstep Top.result` → `Lerp Mid-Top.t`

---

### 11. Conectar a la salida

- `Lerp Mid-Top.result` → `Spatial Output.albedo`

---

### 12. Compilar

Clic en **Compile**. Debe decir `Compile successful`.

Si hay error, revisa que `Vertex Position (Local)`, `Object Scale` y `Multiply` estén en **stage vertex**.

---

## Diagrama del grafo

```
[Vertex Position (Local)] ─ .y ─┐
                                 ├─→ [Multiply] ─── .result ──→ [Smoothstep Mid] ─→ [Lerp Bottom-Mid] ─┐
[Object Scale] ────────── .y ─┘         │                                                               │
                                         └──────────────────────→ [Smoothstep Top] ─→ [Lerp Mid-Top]   │
                                                                                              ↑          │
[tex_bottom]→[Sample Bottom]─.rgb ────────────────────────────────────────────────────→ lerp.a          │
[tex_mid]  →[Sample Mid]   ─.rgb ──────────────────────────────────────────────────────→ lerp.b ←───────┘
[tex_top]  →[Sample Top]   ─.rgb ─────────────────────────────────────────────────────→ lerp Mid-Top.b

[UV] ──────────────────────────────────────→ 3× Sample.uv

[Lerp Mid-Top.result] ──────────────────────────────────────────────────────────────→ [Spatial Output.albedo]
```

---

## Qué genera el compilador

```glsl
varying float _v0;  // height = vertex.y * scale.y

void vertex() {
    float _t27 = VERTEX.y * length(MODEL_MATRIX[1].xyz);
    _v0 = _t27;
}

void fragment() {
    vec3 bottom = texture(tex_bottom, UV).rgb;
    vec3 mid    = texture(tex_mid,    UV).rgb;
    vec3 top    = texture(tex_top,    UV).rgb;

    float mask_mid = smoothstep(mid_start, mid_end, _v0);
    float mask_top = smoothstep(top_start, top_end, _v0);

    vec3 result = mix(bottom, mid, mask_mid);
    result      = mix(result, top, mask_top);

    ALBEDO = result;
}
```

---

## Umbrales según tipo de mesh

| Mesh | Y local range | mid_start | mid_end | top_start | top_end |
|------|--------------|-----------|---------|-----------|---------|
| Capsule (default) | -1.0 a 1.0 | -0.4 | 0.0 | 0.1 | 0.5 |
| Cylinder (h=2) | -1.0 a 1.0 | -0.5 | 0.0 | 0.1 | 0.6 |
| Objeto con pivote en base | 0.0 a altura | 0.3*h | 0.5*h | 0.6*h | 0.9*h |

---

## Errores comunes

### Vertex Position (Local) da error en fragment

El IR builder mueve este nodo al vertex stage automáticamente porque su definición tiene `STAGE_VERTEX`.
Si ves un error de `VERTEX` en fragment, es síntoma de otro problema — verifica que el graph cargó correctamente.

### No se ven texturas — capsule gris

Si el `ALBEDO` da negro o gris y las texturas están asignadas:
1. Verifica que `Lerp Mid-Top.result` está conectado a `Spatial Output.albedo`
2. Verifica que los 3 `Sample Texture 2D` tienen tanto `tex` como `uv` conectados
3. Usa el mesh **Cylinder** en el preview — muestra las capas más claramente que la Capsule

### Capa superior aparece en objetos bajos

Si usas `World Position.y` en lugar de `Vertex Position (Local).y`, mover el objeto en la escena cambia las capas.
Usa siempre **Local** para este caso.

### Escala no considerada

Si escalas el objeto en Y en la escena y las capas no se mueven con el mesh, asegúrate de tener el `Multiply` con `Object Scale.y`.
Si no quieres eso, conecta `Vertex Position (Local).y` directo a los `Smoothstep` y omite el `Multiply` y el `Object Scale`.
