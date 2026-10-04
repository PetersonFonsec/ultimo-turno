extends Node2D
## Fase de teste: atravessar o percurso até a saída.
## Cuida de morte por queda, pausa, reinício, conclusão e limites da câmera.

signal level_completed

@export var level_width: int = 2400
@export var level_height: int = 360
## Abaixo desta altura o jogador morre.
@export var fall_limit: float = 400.0

var _finished: bool = false

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var goal: Area2D = $Goal


func _ready() -> void:
	get_tree().paused = false
	player.health_changed.connect(hud.set_health)
	player.died.connect(_on_player_died)
	goal.body_entered.connect(_on_goal_body_entered)
	hud.set_health(player.health, player.max_health)

	player.camera.limit_left = 0
	player.camera.limit_top = 0
	player.camera.limit_right = level_width
	player.camera.limit_bottom = level_height
	player.camera.reset_smoothing()


func _physics_process(_delta: float) -> void:
	if not player.is_dead and player.global_position.y > fall_limit:
		player.die()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		restart()
	elif event.is_action_pressed("pause") and not _finished:
		_set_paused(not get_tree().paused)


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	if paused:
		hud.show_message("PAUSADO", "ESC continuar    R reiniciar")
	else:
		hud.hide_message()


func _on_player_died() -> void:
	if _finished:
		return
	_finished = true
	hud.show_message("VOCÊ MORREU", "Pressione R para tentar de novo")


func _on_goal_body_entered(body: Node2D) -> void:
	if body != player or _finished or player.is_dead:
		return
	_finished = true
	player.controls_enabled = false
	hud.show_message("FASE CONCLUÍDA", "Pressione R para jogar de novo")
	level_completed.emit()
