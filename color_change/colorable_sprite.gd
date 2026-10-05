class_name ColorableSprite
extends Sprite2D
## 可上色物体（Sprite 版）：初始保持原色，被上色后颜色从靠近玩家的一侧扩散直到填满整个贴图。

const FILL_SHADER := preload("res://shaders/color_fill_texture.gdshader")

@export var fill_duration := 0.5
@export var fill_softness := 14.0

var _mat: ShaderMaterial
var _tween: Tween
var _current_color: Color


func _ready() -> void:
	_current_color = modulate
	_mat = ShaderMaterial.new()
	_mat.shader = FILL_SHADER
	_mat.set_shader_parameter("base_color", _current_color)
	_mat.set_shader_parameter("fill_color", _current_color)
	_mat.set_shader_parameter("fill_origin", Vector2.ZERO)
	_mat.set_shader_parameter("fill_front", -1.0)
	_mat.set_shader_parameter("fill_softness", fill_softness)
	material = _mat
	# 颜色统一交给 shader 处理，避免 modulate 双重叠加。
	modulate = Color.WHITE


func apply_color(c: Color, from_pos: Vector2 = Vector2.INF) -> void:
	var origin := global_position if from_pos == Vector2.INF else from_pos
	_start_fill(c, origin)


func _start_fill(c: Color, origin: Vector2) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	var near_far := _compute_near_far(origin)

	_mat.set_shader_parameter("base_color", _current_color)
	_mat.set_shader_parameter("fill_color", c)
	_mat.set_shader_parameter("fill_origin", origin)

	var start := near_far.x - fill_softness
	var end := near_far.y + fill_softness
	_tween = create_tween()
	_tween.tween_method(_set_fill_front, start, end, fill_duration)
	_tween.tween_callback(_finish_fill.bind(c))


func _set_fill_front(v: float) -> void:
	_mat.set_shader_parameter("fill_front", v)


func _finish_fill(c: Color) -> void:
	_current_color = c
	_mat.set_shader_parameter("base_color", c)


func _compute_near_far(origin: Vector2) -> Vector2:
	var tex_size := Vector2.ZERO
	if texture != null:
		tex_size = texture.get_size()
	# 贴图在局部坐标中的包围矩形（含 centered / offset）。
	var rect_pos := offset - (tex_size * 0.5 if centered else Vector2.ZERO)
	var corners: Array[Vector2] = [
		rect_pos,
		rect_pos + Vector2(tex_size.x, 0.0),
		rect_pos + tex_size,
		rect_pos + Vector2(0.0, tex_size.y),
	]
	var near := INF
	var far := -INF
	for p in corners:
		var d := origin.distance_to(to_global(p))
		near = min(near, d)
		far = max(far, d)
	return Vector2(near, far)
