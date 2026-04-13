# Extreme Validation Examples

These example graphs are meant to stress the editor across multiple layers at once:

- graph serialization
- node registry lookup
- validation and stage checks
- subgraph expansion
- uniform emission
- helper function emission
- vertex to fragment varying generation
- generated shader output per domain

## Regenerate the examples

Run:

```bash
godot --headless --editor --path . --script tools/generate_extreme_examples.gd
```

This writes:

- `shader_assets/subgraphs/extreme_palette.gssubgraph`
- `shaders/examples/spatial_triplanar_rim.gshadergraph`
- `shaders/examples/fullscreen_posterized_glitch.gshadergraph`
- `shaders/examples/particles_orbit_burst.gshadergraph`
- `assets/shaders/examples/*.generated.gdshader`

## Example 1: Spatial Triplanar Rim

Source:

- `res://shaders/examples/spatial_triplanar_rim.gshadergraph`

What it validates:

- vertex displacement branch
- explicit vertex-scoped math nodes
- vertex to fragment transfer through generated `varying`
- triplanar helper function emission
- Fresnel-based emission
- mixed spatial outputs (`ALBEDO`, `ROUGHNESS`, `EMISSION`)

How to inspect it:

1. Open the graph in Shader Studio.
2. Assign a texture to the `albedo_tex` uniform.
3. Compile and open the generated shader.
4. Confirm the generated shader includes `varying vec3 _v0;`.
5. Apply the shader to a 3D mesh.

Expected result:

- the mesh waves vertically
- texture projection is world-space triplanar
- edges glow with a cyan rim light

## Example 2: Fullscreen Posterized Glitch

Source:

- `res://shaders/examples/fullscreen_posterized_glitch.gshadergraph`

What it validates:

- fullscreen/canvas_item backend
- auto uniform injection for `hint_screen_texture`
- helper emission for `dither`, `hue_shift`, and `posterize`
- subgraph expansion inside a post-process graph

How to inspect it:

1. Open the graph in Shader Studio.
2. Compile the graph.
3. Apply the generated shader to a full-screen `ColorRect` or preview setup.
4. Change `hue_amount`, `contrast_amount`, and `posterize_steps`.

Expected result:

- the screen is posterized
- contrast is boosted
- dither chooses between processed screen color and a synthetic palette color

## Example 3: Particles Orbit Burst

Source:

- `res://shaders/examples/particles_orbit_burst.gshadergraph`

What it validates:

- particles domain backend
- time-driven motion
- subgraph reuse in a non-spatial domain
- color generation from particle random/index data

How to inspect it:

1. Open the graph in Shader Studio.
2. Compile the graph.
3. Assign the generated shader to a particle process material.
4. Tweak `orbit_speed`, `orbit_strength`, and `hue_bias`.

Expected result:

- particles move in orbit-like arcs
- upward motion stays constant
- hue shifts over time per particle

## Current limits surfaced by these examples

- The editor now validates node domain compatibility, but the node search UI still does not filter by domain.
- Automatic vertex to fragment transfer is implemented for `spatial`, `canvas_item`, and `fullscreen` graphs.
- Sky and fog graphs still compile, but preview is intentionally disabled because the preview scene does not set up those domains.
- Vertex-heavy graphs still need explicit `vertex` stage scope on shared math chains when the same node type can run in either stage.
