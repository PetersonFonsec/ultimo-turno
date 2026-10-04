class_name KazeGuard
extends CharacterBody2D
## Agente de segurança da Kaze Corp. Patrulha entre dois pontos e,
## quando vê o jogador ao alcance, para, mira e atira.

signal died

@export_group("Patrulha")
@export var speed: float = 35.0
## Pontos da patrulha, relativos à posição inicial (eixo X).
@export var patrol_left: float = -48.0
@export var patrol_right: float = 48.0
@export var gravity: float = 980.0

@export_group("Combate")
@export var max_health: int = 3
@export var detection_range: float = 200.0
## Diferença de altura máxima para considerar o jogador na linha de tiro.
@export var vertical_tolerance: float = 28.0
## Segundos entre disparos.
@export var fire_interval: float = 1.3
## Aviso visual antes do disparo, em segundos.
@export var windup_time: float = 0.35
@export var projectile_damage: int = 1
@export var projectile_scene: PackedScene
@export var death_effect: PackedScene

var health: int
var facing: float = 1.0

var _origin_x: float
var _fire_timer: float = 0.0
var _flash_timer: float = 0.0
var _player: Player

@onready var visual: Node2D = $Visual
@onready var muzzle: Marker2D = $Visual/Muzzle
@onready var muzzle_flash: Node2D = $Visual/MuzzleFlash
@onready var alert_mark: Node2D = $AlertMark


func _ready() -> void:
	health = max_health
	_origin_x = global_position.x
	_fire_timer = fire_interval
	muzzle_flash.hide()
	alert_mark.hide()


func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Player
	_flash_timer -= delta
	velocity.y += gravity * delta

	if _can_see_player():
		_attack(delta)
	else:
		_patrol()

	visual.scale.x = facing
	move_and_slide()


func _process(_delta: float) -> void:
	visual.modulate = Color(3.0, 3.0, 3.0) if _flash_timer > 0.0 else Color.WHITE


func _patrol() -> void:
	alert_mark.hide()
	muzzle_flash.hide()
	# Recarrega devagar enquanto não vê o jogador, para o primeiro tiro ter aviso.
	_fire_timer = maxf(_fire_timer, windup_time + 0.3)
	if global_position.x >= _origin_x + patrol_right:
		facing = -1.0
	elif global_position.x <= _origin_x + patrol_left:
		facing = 1.0
	elif is_on_wall():
		facing = -facing
	velocity.x = facing * speed


func _attack(delta: float) -> void:
	alert_mark.show()
	velocity.x = 0.0
	facing = signf(_player.global_position.x - global_position.x)
	_fire_timer -= delta
	# Telegrafa o tiro acendendo o cano.
	muzzle_flash.visible = _fire_timer <= windup_time
	if _fire_timer <= 0.0:
		_shoot()
		_fire_timer = fire_interval


func _can_see_player() -> bool:
	if _player == null or _player.is_dead:
		return false
	var to_player := _player.global_position - global_position
	if absf(to_player.x) > detection_range or absf(to_player.y) > vertical_tolerance:
		return false
	# Linha de visão: só o cenário (camada 1) bloqueia.
	var query := PhysicsRayQueryParameters2D.create(
		muzzle.global_position, _player.global_position + Vector2(0, -12), 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()


func _shoot() -> void:
	var bullet := projectile_scene.instantiate() as Projectile
	bullet.damage = projectile_damage
	bullet.launch(global_position + Vector2(0, -13), muzzle.global_position, Vector2(facing, 0.0))
	get_parent().add_child(bullet)


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health -= amount
	_flash_timer = 0.06
	if health <= 0:
		if death_effect:
			var effect := death_effect.instantiate() as Node2D
			effect.global_position = global_position + Vector2(0, -12)
			get_parent().add_child.call_deferred(effect)
		died.emit()
		queue_free()
