shader_type canvas_item;

// 选中提示描边：在物体自带黑色描边的中心，画一条非常细的虚线。
// 通过“不透明 + 暗色”识别自带描边，再用到轮廓边缘的距离把线收窄到描边中心。

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
// 虚线线宽（贴图像素）；配合 smooth 可小于 1 像素。
uniform float outline_width : hint_range(0.2, 3.0) = 0.7;
// 描边中心相对轮廓边缘向内偏移（贴图像素）：1px 描边填 1.0，2px 描边填 1.5。
uniform float center_offset : hint_range(0.0, 3.0) = 1.0;
// 虚线周期（世界单位）与实线占比。
uniform float dash_period : hint_range(2.0, 64.0) = 14.0;
uniform float dash_ratio : hint_range(0.1, 0.9) = 0.55;
// 判定“自带黑色描边”的亮度阈值。
uniform float dark_threshold : hint_range(0.0, 0.6) = 0.25;

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float a = tex.a;
	float lum = dot(tex.rgb, vec3(0.299, 0.587, 0.114));

	// 1) 自带黑色描边：不透明且足够暗。
	float dark = 1.0 - smoothstep(dark_threshold - 0.08, dark_threshold + 0.08, lum);
	float on_outline = step(0.5, a) * dark;

	// 2) 到轮廓边缘（透明像素）的切比雪夫距离。
	vec2 ts = TEXTURE_PIXEL_SIZE;
	float edge_dist = 8.0;
	for (int i = -2; i <= 2; i++) {
		for (int j = -2; j <= 2; j++) {
			float na = texture(TEXTURE, UV + vec2(float(i), float(j)) * ts).a;
			if (na < 0.5) {
				edge_dist = min(edge_dist, max(abs(float(i)), abs(float(j))));
			}
		}
	}

	// 3) 细线：中心在 center_offset 处、宽 outline_width 的窄带。
	float line = 1.0 - smoothstep(0.0, outline_width, abs(edge_dist - center_offset));

	// 4) 虚线（世界空间，45° 斜向重复）。
	float dash = step(fract((world_pos.x + world_pos.y) / dash_period), dash_ratio);

	COLOR = vec4(outline_color.rgb, outline_color.a * on_outline * line * dash);
}
