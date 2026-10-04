extends Node2D
## Faísca curta de impacto, desenhada por código (placeholder).

@export var color: Color = Color("ffe08a")
@export var duration: float = 0.12
@export var max_radius: float = 6.0

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	if _time >= duration:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var t := _time / duration
	var r := roundf(lerpf(2.0, max_radius, t))
	var c := Color(color, 1.0 - t)
	draw_rect(Rect2(-r, -1, r * 2.0, 2), c)
	draw_rect(Rect2(-1, -r, 2, r * 2.0), c)
