@tool
extends Node2D
## Silhueta de prédios desenhada por código (placeholder até existirem
## as camadas de parallax em pixel art). Usada dentro de um Parallax2D.

@export var width: float = 640.0
@export var base_y: float = 360.0
@export var min_height: float = 60.0
@export var max_height: float = 180.0
@export var min_building_width: float = 24.0
@export var max_building_width: float = 64.0
@export var color: Color = Color("161a2e")
@export var window_colors: Array[Color] = [Color("e8a33a"), Color("3fb7c9")]
@export_range(0.0, 1.0) var window_chance: float = 0.12
@export var seed_value: int = 1


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var x := 0.0
	while x < width:
		var w := roundf(rng.randf_range(min_building_width, max_building_width))
		w = minf(w, width - x)
		var h := roundf(rng.randf_range(min_height, max_height))
		draw_rect(Rect2(x, base_y - h, w, h), color)
		_draw_windows(rng, Rect2(x, base_y - h, w, h))
		x += w
	

func _draw_windows(rng: RandomNumberGenerator, building: Rect2) -> void:
	if window_colors.is_empty():
		return
	var y := building.position.y + 6.0
	while y < building.end.y - 6.0:
		var x := building.position.x + 4.0
		while x < building.end.x - 5.0:
			if rng.randf() < window_chance:
				var c: Color = window_colors[rng.randi() % window_colors.size()]
				draw_rect(Rect2(x, y, 2, 3), Color(c, 0.7))
			x += 6.0
		y += 8.0
