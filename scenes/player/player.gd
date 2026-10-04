class_name Player
extends CharacterBody2D
## Trabalhador da resistência: anda, pula, atira e recebe dano.
## O visual fica no nó "Visual" para ser trocado por sprites depois.

signal health_changed(current: int, maximum: int)
signal died

@export_group("Movimento")
@export var speed: float = 110.0
@export var jump_velocity: float = -330.0
@export var gravity: float = 980.0
@export var max_fall_speed: float = 420.0
## Tempo após sair de uma borda em que ainda dá para pular.
@export var coyote_time: float = 0.08
## Tempo que um aperto de pulo fica guardado antes de tocar o chão.
@export var jump_buffer_time: float = 0.1

@export_group("Vida")
@export var max_health: int = 5
@export var invulnerability_time: float = 1.0
@export var knockback: Vector2 = Vector2(90.0, -120.0)

@export_group("Arma")
## Tiros por segundo segurando o botão.
@export var fire_rate: float = 7.0
@export var projectile_damage: int = 1
@export var projectile_scene: PackedScene

var health: int
var facing: float = 1.0
var is_dead: bool = false
var controls_enabled: bool = true

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _fire_cooldown: float = 0.0
var _invulnerable_timer: float = 0.0
var _flash_timer: float = 0.0

@onready var visual: Node2D = $Visual
@onready var muzzle: Marker2D = $Visual/Muzzle
@onready var muzzle_flash: Node2D = $Visual/MuzzleFlash
@onready var camera: Camera2D = $Camera2D


func _ready() -> void:
	add_to_group("player")
	health = max_health
	muzzle_flash.hide()


func _physics_process(delta: float) -> void:
	_update_timers(delta)

	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)

	if is_dead or not controls_enabled:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		move_and_slide()
		return

	# Coyote time e buffer de pulo.
	if is_on_floor():
		_coyote_timer = coyote_time
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = jump_buffer_time
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	# Soltar o pulo cedo corta a subida.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	var direction := Input.get_axis("move_left", "move_right")
	# Durante o knockback o controle horizontal é reduzido.
	var control := 0.35 if _invulnerable_timer > invulnerability_time - 0.15 else 1.0
	velocity.x = lerpf(velocity.x, direction * speed, control)
	if direction != 0.0:
		facing = signf(direction)
		visual.scale.x = facing

	if Input.is_action_pressed("shoot") and _fire_cooldown <= 0.0:
		_shoot()

	move_and_slide()


func _process(_delta: float) -> void:
	# Pisca enquanto invulnerável; fica vermelho logo após o golpe.
	if _invulnerable_timer > 0.0 and not is_dead:
		visual.visible = fmod(_invulnerable_timer, 0.12) > 0.05
	else:
		visual.visible = true
	visual.modulate = Color(1.0, 0.35, 0.35) if _flash_timer > 0.0 else Color.WHITE


func _update_timers(delta: float) -> void:
	_coyote_timer -= delta
	_jump_buffer_timer -= delta
	_fire_cooldown -= delta
	_invulnerable_timer -= delta
	_flash_timer -= delta
	if muzzle_flash.visible and _fire_cooldown < 1.0 / fire_rate - 0.05:
		muzzle_flash.hide()


func _shoot() -> void:
	_fire_cooldown = 1.0 / fire_rate
	var bullet := projectile_scene.instantiate() as Projectile
	bullet.damage = projectile_damage
	bullet.launch(global_position + Vector2(0, -14), muzzle.global_position, Vector2(facing, 0.0))
	get_parent().add_child(bullet)
	muzzle_flash.show()


func take_damage(amount: int) -> void:
	if is_dead or _invulnerable_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	health_changed.emit(health, max_health)
	if health == 0:
		die()
		return
	_invulnerable_timer = invulnerability_time
	_flash_timer = 0.12
	velocity = Vector2(-facing * knockback.x, knockback.y)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	if health > 0:
		health = 0
		health_changed.emit(health, max_health)
	visual.modulate = Color(1.0, 0.35, 0.35)
	visual.rotation_degrees = -90.0 * facing
	died.emit()
