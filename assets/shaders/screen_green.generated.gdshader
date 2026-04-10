// ============================================================
// GENERATED FILE — DO NOT EDIT MANUALLY
// Source: res://shaders/screen_green.gshadergraph
// Compiled by: Godot Shader Studio 0.3.0-gdscript
// ============================================================
shader_type canvas_item;

uniform sampler2D _sgs_screen_tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float green_hue = 0.33;
uniform float saturation = 1.0;

void fragment() {
	vec4 _t0 = texture(_sgs_screen_tex, SCREEN_UV);
	vec3 _t1 = _t0.rgb;
	float _t2 = _t0.r;
	float _t3 = _t0.g;
	float _t4 = _t0.b;
	float _t5 = _t0.a;
	vec4 _p__t6 = (_t1.g < _t1.b) ? vec4(_t1.bg, -1.0, 2.0/3.0) : vec4(_t1.gb, 0.0, -1.0/3.0);
	vec4 _q__t6 = (_t1.r < _p__t6.x) ? vec4(_p__t6.xyw, _t1.r) : vec4(_t1.r, _p__t6.yzx);
	float _d__t6 = _q__t6.x - min(_q__t6.w, _q__t6.y);
	vec3 _t6 = vec3(abs(_q__t6.z + (_q__t6.w - _q__t6.y) / (6.0 * _d__t6 + 1e-10)), _d__t6 / (_q__t6.x + 1e-10), _q__t6.x);
	float _t7 = _t6.x;
	float _t8 = _t6.y;
	float _t9 = _t6.z;
	vec3 node_14_sg__t10 = vec3(green_hue, saturation, _t9);
	vec3 _hsv_c_node_14_sg__t11 = vec3(abs(node_14_sg__t10.x * 6.0 - 3.0) - 1.0, 2.0 - abs(node_14_sg__t10.x * 6.0 - 2.0), 2.0 - abs(node_14_sg__t10.x * 6.0 - 4.0));
	vec3 node_14_sg__t11 = ((clamp(_hsv_c_node_14_sg__t11, 0.0, 1.0) - 1.0) * node_14_sg__t10.y + 1.0) * node_14_sg__t10.z;
	COLOR = vec4(node_14_sg__t11, 1.0);
}
