shader_type canvas_item;

// 颜色扩散填充（纹理版，用于 Sprite2D）。
// 保持原始贴图，颜色从靠近玩家的边缘开始沿径向扩散，把贴图逐步染成目标色。

uniform vec4 base_color : source_color = vec4(1.0);
uniform vec4 fill_color : source_color = vec4(0.25, 0.85, 0.35, 1.0);

// 扩散起点（玩家世界坐标）
uniform vec2 fill_origin = vec2(0.0);
// 当前扩散半径（世界单位）。<0 表示尚未开始，保持 base_color。
uniform float fill_front = -1.0;
// 过渡带宽度（世界单位），让扩散边缘柔和
uniform float fill_softness = 14.0;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float t = 0.0;
	if (fill_front >= 0.0) {
		float d = distance(world_pos, fill_origin);
		t = 1.0 - smoothstep(fill_front - fill_softness, fill_front + fill_softness, d);
	}
	vec3 tint = mix(base_color.rgb, fill_color.rgb, t);
	COLOR.rgb = tex.rgb * tint;
	COLOR.a = tex.a * mix(base_color.a, fill_color.a, t);
}
