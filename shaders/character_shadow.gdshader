shader_type canvas_item;

// 角色投影阴影：把当前动画帧渲染成一层压扁/倾斜在地面上的黑色半透明剪影。
// 与树的 tree_shadow 同一套视觉语言，但专门为「动画帧 + 图集(AtlasTexture)」做了适配：
// UV 此时位于整张图集内，所以由脚本每帧把当前帧的 region_min / region_size 传进来，
// 软边采样时才不会越界串到相邻帧。

uniform vec4 shadow_color : source_color = vec4(0.0, 0.0, 0.0, 0.45);
// 软边模糊半径（当前帧的像素数）。0 = 硬边剪影。
uniform float softness : hint_range(0.0, 8.0) = 1.0;
// 当前帧在整张图集里的归一化区域（普通贴图就是 (0,0)~(1,1)）。
uniform vec2 region_min = vec2(0.0, 0.0);
uniform vec2 region_size = vec2(1.0, 1.0);

void fragment() {
	vec2 luv = (UV - region_min) / region_size;
	// 一个「帧像素」在帧内坐标(luv)里的大小。
	vec2 step_ = TEXTURE_PIXEL_SIZE * softness / region_size;

	// 9 点软边采样；越界处 clamp 到帧边缘，避免图集串帧。
	// 注：TEXTURE 是内置 uniform，不能放进自定义函数，只能内联在 fragment() 里。
	vec2 c;
	float a = 0.0;

	c = clamp(luv + vec2(-step_.x, -step_.y), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(0.0, -step_.y), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(step_.x, -step_.y), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(-step_.x, 0.0), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv, vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(step_.x, 0.0), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(-step_.x, step_.y), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(0.0, step_.y), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;
	c = clamp(luv + vec2(step_.x, step_.y), vec2(0.0), vec2(1.0));
	a += texture(TEXTURE, region_min + c * region_size).a;

	a /= 9.0;
	COLOR = vec4(shadow_color.rgb, a * shadow_color.a);
}
