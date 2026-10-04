@tool
extends StaticBody2D
## Plataforma retangular placeholder. Ajuste "size" e "color" no Inspetor;
## o visual e a colisão são gerados a partir deles.

@export var size: Vector2 = Vector2(256, 32):
	set(value):
		size = value
		_rebuild()
@export var color: Color = Color("5b6b8c"):
	set(value):
		color = value
		queue_redraw()


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
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 4)), color.lightened(0.25))
