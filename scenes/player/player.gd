extends CharacterBody2D
## Jogador de plataforma. Os atributos vêm do personagem escolhido em GameState.

@export var speed: float = 300.0
@export var jump_velocity: float = -560.0
@export var acceleration: float = 2400.0
@export var friction: float = 2800.0

@onready var body: Polygon2D = $Body

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")


func _ready() -> void:
	apply_character(GameState.get_selected_character())


func apply_character(character: Dictionary) -> void:
	speed = character.speed
	jump_velocity = character.jump_velocity
	body.color = character.color


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	# Pulo variável: soltar o botão cedo corta a subida.
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
		body.scale.x = signf(direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	move_and_slide()
