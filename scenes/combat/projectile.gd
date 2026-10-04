class_name Projectile
extends Area2D
## Projétil horizontal. Quem ele atinge é definido pela collision_mask da cena:
## player_bullet.tscn acerta cenário + inimigos; enemy_bullet.tscn acerta cenário + jogador.
## A colisão é checada com um raio entre a posição anterior e a atual, para que
## projéteis rápidos não atravessem paredes finas nem saiam de dentro delas.

@export var speed: float = 360.0
@export var damage: int = 1
@export var lifetime: float = 0.8
@export var impact_scene: PackedScene

var direction: Vector2 = Vector2.RIGHT

var _previous_position: Vector2
var _has_previous: bool = false


## Posiciona o projétil no cano. "origin" é o centro de quem atirou: o primeiro
## trecho checado vai dele até o cano, então encostar na parede não atravessa ela.
func launch(origin: Vector2, muzzle_position: Vector2, dir: Vector2) -> void:
	direction = dir
	global_position = muzzle_position
	_previous_position = origin
	_has_previous = true


func _ready() -> void:
	scale.x = signf(direction.x) if direction.x != 0.0 else 1.0
	if not _has_previous:
		_previous_position = global_position


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	var query := PhysicsRayQueryParameters2D.create(_previous_position, global_position, collision_mask)
	query.hit_from_inside = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		_hit(hit.collider, hit.position)
		return
	_previous_position = global_position
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()


func _hit(target: Object, at: Vector2) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage)
	if impact_scene:
		var impact := impact_scene.instantiate() as Node2D
		impact.global_position = at
		get_parent().add_child.call_deferred(impact)
	queue_free()
