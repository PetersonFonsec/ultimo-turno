@tool
extends StaticBody2D
## Bloco retangular placeholder (chão, parede, caixa ou passarela).
## Ajuste "size" e "color" no Inspetor; visual e colisão acompanham.

@export var size: Vector2 = Vector2(64, 16):
	set(value):
		size = value
		_rebuild()
@export var color: Color = Color("2b3140"):
	set(value):
		color = value
		queue_redraw()
## Passarela: dá para subir por baixo e ficar em cima.
@export var one_way: bool = false:
	set(value):
		one_way = value
		_rebuild()


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = size / 2.0
	collision.one_way_collision = one_way
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 2)), color.lightened(0.35))
	if one_way:
		# Treliça de passarela industrial.
		var x := 4.0
		while x < size.x:
			draw_rect(Rect2(x, 2, 1, size.y - 2), color.darkened(0.4))
			x += 8.0
