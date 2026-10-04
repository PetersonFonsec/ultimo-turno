extends SceneTree
## Teste de fumaça: percorre menu -> seleção -> fase e verifica que o personagem anda.
## Rode com: godot --headless --script res://tests/smoke_test.gd

func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game_state := root.get_node("GameState")

	# Menu principal -> seleção de personagem.
	change_scene_to_file(game_state.SCENE_MAIN_MENU)
	await _frames(3)
	_check(current_scene.name == "MainMenu", "menu principal abriu")
	current_scene.get_node("%StartButton").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "CharacterSelect", "seleção de personagem abriu")

	# Escolhe o segundo personagem e começa.
	var cards: HBoxContainer = current_scene.get_node("%Cards")
	_check(cards.get_child_count() == game_state.CHARACTERS.size(), "um card por personagem")
	cards.get_child(1).pressed.emit()
	_check(game_state.selected_character_index == 1, "personagem 2 selecionado")
	current_scene.get_node("%ConfirmButton").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "Level01", "primeira fase abriu")

	# Deixa cair no chão e anda para a direita.
	var player: CharacterBody2D = current_scene.get_node("Player")
	_check(is_equal_approx(player.speed, game_state.CHARACTERS[1].speed), "atributos do personagem aplicados")
	await _physics_frames(60)
	_check(player.is_on_floor(), "personagem está no chão")
	var start_x := player.global_position.x
	Input.action_press("move_right")
	await _physics_frames(30)
	Input.action_release("move_right")
	_check(player.global_position.x > start_x + 50.0, "personagem se moveu para a direita")

	# Pulo.
	Input.action_press("jump")
	await _physics_frames(5)
	Input.action_release("jump")
	_check(player.velocity.y < 0.0 or not player.is_on_floor(), "personagem pulou")

	print("SMOKE TEST OK")
	quit(0)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - ", label)
	else:
		push_error("FALHOU: " + label)
		quit(1)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics_frames(n: int) -> void:
	for i in n:
		await physics_frame
