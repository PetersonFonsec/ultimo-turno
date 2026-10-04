extends Node2D
## Primeira fase: chegar até a bandeira no fim do mapa.

const FALL_LIMIT_Y := 900.0

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var goal: Area2D = $Goal
@onready var character_label: Label = %CharacterLabel
@onready var pause_menu: Control = %PauseMenu
@onready var resume_button: Button = %ResumeButton
@onready var menu_button: Button = %MenuButton
@onready var finish_label: Label = %FinishLabel


func _ready() -> void:
	player.global_position = spawn_point.global_position
	character_label.text = GameState.get_selected_character().name
	pause_menu.hide()
	finish_label.hide()
	goal.body_entered.connect(_on_goal_body_entered)
	resume_button.pressed.connect(_set_paused.bind(false))
	menu_button.pressed.connect(GameState.go_to.bind(GameState.SCENE_MAIN_MENU))


func _physics_process(_delta: float) -> void:
	if player.global_position.y > FALL_LIMIT_Y:
		player.global_position = spawn_point.global_position
		player.velocity = Vector2.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_set_paused(not get_tree().paused)
		get_viewport().set_input_as_handled()


func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	pause_menu.visible = paused
	if paused:
		resume_button.grab_focus()


func _on_goal_body_entered(body: Node2D) -> void:
	if body == player:
		finish_label.show()
