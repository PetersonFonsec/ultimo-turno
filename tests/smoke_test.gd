extends SceneTree
## Teste automático do protótipo. Rode com:
##   godot --headless --script res://tests/smoke_test.gd
## Sai com código 1 se alguma verificação falhar.

const LEVEL := "res://scenes/levels/test_level.tscn"
const MENU := "res://scenes/main_menu/main_menu.tscn"

var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Menu -> fase.
	change_scene_to_file(MENU)
	await _frames(3)
	_check(current_scene.name == "MainMenu", "menu abre")
	current_scene.get_node("%StartButton").pressed.emit()
	await _frames(3)
	_check(current_scene.name == "TestLevel", "botão Iniciar abre a fase")

	var level := current_scene
	var player: Player = level.get_node("Player")
	await _physics(30)
	_check(player.is_on_floor(), "jogador cai e para no chão")

	# Movimento.
	var x0 := player.global_position.x
	await _hold("move_right", 20)
	_check(player.global_position.x > x0 + 20.0, "anda para a direita")
	_check(player.visual.scale.x > 0.0, "visual vira para a direita")
	x0 = player.global_position.x
	await _hold("move_left", 20)
	_check(player.global_position.x < x0 - 20.0, "anda para a esquerda")
	_check(player.visual.scale.x < 0.0, "visual vira para a esquerda")

	# Pulo.
	var y0 := player.global_position.y
	Input.action_press("jump")
	await _physics(10)
	_check(player.global_position.y < y0 - 15.0, "pula")
	Input.action_release("jump")
	await _physics(60)
	_check(player.is_on_floor(), "volta ao chão")

	# Buffer de pulo: apertar pouco antes de tocar o chão ainda pula.
	player.global_position.y -= 20.0
	player.velocity = Vector2.ZERO
	await _physics(1)
	while player.velocity.y < 300.0 and not player.is_on_floor():
		await _physics(1)
	Input.action_press("jump")
	await _physics(1)
	Input.action_release("jump")
	await _physics(12)
	_check(player.global_position.y < y0 - 5.0, "buffer de pulo funciona")
	await _physics(60)

	# Coyote time: pular logo depois de sair da borda da pilha de caixas ainda funciona.
	player.global_position = Vector2(436, 290)
	await _physics(20)
	_check(player.is_on_floor(), "jogador em cima da pilha de caixas")
	Input.action_press("move_right")
	while player.is_on_floor():
		await _physics(1)
	await _physics(2)
	Input.action_release("move_right")
	Input.action_press("jump")
	await _physics(2)
	Input.action_release("jump")
	_check(player.velocity.y < 0.0, "coyote time permite pular após sair da borda")
	await _physics(60)

	# Parede esquerda bloqueia o jogador.
	player.global_position = Vector2(20, 320)
	await _hold("move_left", 30)
	_check(player.global_position.x >= 4.0, "parede bloqueia o jogador")

	# Tiro nas duas direções; a parede esquerda (x=0) e a caixa (x=220) bloqueiam.
	_check(_bullets(level).size() == 0, "sem projéteis no início")
	player.global_position = Vector2(100, 320)
	await _physics(20)
	await _hold("move_left", 2)
	Input.action_press("shoot")
	await _physics(2)
	Input.action_release("shoot")
	var left_bullets := _bullets(level)
	_check(left_bullets.size() == 1 and left_bullets[0].direction.x < 0.0, "atira para a esquerda")
	await _physics(30)
	_check(_bullets(level).size() == 0, "parede destrói o projétil")

	player.global_position = Vector2(20, 320)
	await _hold("move_left", 20)
	Input.action_press("shoot")
	await _physics(2)
	Input.action_release("shoot")
	await _physics(2)
	_check(_bullets(level).size() == 0, "encostado na parede, o tiro não atravessa")

	player.global_position = Vector2(100, 320)
	await _physics(20)
	await _hold("move_right", 2)
	Input.action_press("shoot")
	await _physics(2)
	Input.action_release("shoot")
	var right_bullets := _bullets(level)
	_check(right_bullets.size() == 1 and right_bullets[0].direction.x > 0.0, "atira para a direita")
	await _physics(30)
	_check(_bullets(level).size() == 0, "caixa bloqueia o projétil")

	# Cadência: segurar 1 s dá ~fire_rate tiros.
	player.global_position = Vector2(100, 320)
	var shots := 0
	Input.action_press("shoot")
	for i in 60:
		await _physics(1)
		for b in _bullets(level):
			if not b.has_meta("counted"):
				b.set_meta("counted", true)
				shots += 1
	Input.action_release("shoot")
	_check(shots >= int(player.fire_rate) - 1 and shots <= int(player.fire_rate) + 1, "cadência de %d tiros/s (contou %d)" % [player.fire_rate, shots])

	# Inimigo vê o jogador, atira e causa dano; invulnerabilidade evita dano em sequência.
	var guard1: KazeGuard = level.get_node("Enemies/Guard1")
	player.global_position = Vector2(guard1.global_position.x - 120.0, 320)
	player.velocity = Vector2.ZERO
	var hp := player.health
	for i in 240:
		await _physics(1)
		if player.health < hp:
			break
	_check(player.health == hp - 1, "inimigo acerta o jogador")
	player.take_damage(1)
	_check(player.health == hp - 1, "invulnerabilidade bloqueia dano imediato")

	# Linha de visão: atrás da pilha de caixas o inimigo não vê o jogador.
	player.global_position = Vector2(400, 320)
	await _physics(5)
	_check(not guard1._can_see_player(), "caixas bloqueiam a linha de visão")

	# Jogador derrota o inimigo.
	player.global_position = Vector2(guard1.global_position.x - 80.0, 320)
	await _hold("move_right", 2)
	var guard_died := [false]
	guard1.died.connect(func(): guard_died[0] = true)
	Input.action_press("shoot")
	for i in 120:
		await _physics(1)
		if guard_died[0]:
			break
	Input.action_release("shoot")
	_check(guard_died[0], "inimigo recebe dano e morre")

	# Câmera respeita os limites da fase.
	player.global_position = Vector2(30, 320)
	await _physics(90)
	var center := player.camera.get_screen_center_position()
	_check(center.x >= 320.0 - 1.0, "câmera não passa do limite esquerdo (centro %.0f)" % center.x)
	player.global_position = Vector2(2390, 320)
	await _physics(120)
	center = player.camera.get_screen_center_position()
	_check(center.x <= level.level_width - 320.0 + 1.0, "câmera não passa do limite direito (centro %.0f)" % center.x)
	_check(is_equal_approx(center.y, 180.0), "câmera não passa dos limites verticais")

	# Pausa.
	await _tap("pause")
	_check(paused, "Esc pausa")
	var px := player.global_position
	await _frames(10)
	_check(player.global_position == px, "jogo parado durante a pausa")
	await _tap("pause")
	_check(not paused, "Esc despausa")

	# Chegada.
	var completed := [false]
	level.level_completed.connect(func(): completed[0] = true)
	player.global_position = Vector2(2340, 320)
	await _physics(5)
	_check(completed[0], "chegar na saída conclui a fase")
	_check(level.get_node("HUD").message_box.visible, "mensagem de conclusão aparece")

	# Reiniciar.
	await _tap("restart")
	await _frames(3)
	_check(current_scene != level and current_scene.name == "TestLevel", "R reinicia a fase")
	level = current_scene
	player = level.get_node("Player")
	_check(player.health == player.max_health and level.get_node("Enemies").get_child_count() == 3, "fase volta ao estado inicial")

	# Morte por queda no primeiro buraco.
	var died := [false]
	player.died.connect(func(): died[0] = true)
	player.global_position = Vector2(748, 300)
	await _physics(30)
	_check(died[0] and player.is_dead, "cair no buraco mata")
	_check(level.get_node("HUD").message_box.visible, "mensagem de morte aparece")

	# Morte por dano.
	await _tap("restart")
	await _frames(3)
	player = current_scene.get_node("Player")
	for i in player.max_health:
		player._invulnerable_timer = 0.0
		player.take_damage(1)
	_check(player.is_dead, "perder toda a vida mata")
	_check(current_scene.get_node("HUD").message_box.visible, "mensagem de morte aparece após dano")

	# Percurso completo: um "bot" segura direita + tiro e pula em paredes e buracos.
	await _tap("restart")
	await _frames(3)
	level = current_scene
	player = level.get_node("Player")
	player.health = 99
	var finished := [false]
	level.level_completed.connect(func(): finished[0] = true)
	Input.action_press("move_right")
	Input.action_press("shoot")
	for i in 60 * 40:
		await _physics(1)
		if finished[0] or player.is_dead:
			break
		var ahead := PhysicsRayQueryParameters2D.create(
			player.global_position + Vector2(14, -2), player.global_position + Vector2(14, 40), 1)
		var gap: bool = level.get_world_2d().direct_space_state.intersect_ray(ahead).is_empty()
		if player.is_on_floor() and (player.is_on_wall() or gap):
			Input.action_press("jump")
		elif not player.is_on_floor() and player.velocity.y > 0.0:
			Input.action_release("jump")
	Input.action_release("move_right")
	Input.action_release("shoot")
	Input.action_release("jump")
	_check(finished[0], "dá para atravessar a fase até a saída (x=%.0f)" % player.global_position.x)
	_check(level.get_node("Enemies").get_child_count() == 0, "bot derrotou os 3 inimigos no caminho")

	if _failures == 0:
		print("SMOKE TEST OK")
		quit(0)
	else:
		printerr("%d verificação(ões) falharam" % _failures)
		quit(1)


func _bullets(level: Node) -> Array:
	return level.get_children().filter(func(n): return n is Projectile and not n.is_queued_for_deletion())


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok - ", label)
	else:
		_failures += 1
		printerr("  FALHOU - ", label)


func _hold(action: String, physics_frames: int) -> void:
	Input.action_press(action)
	await _physics(physics_frames)
	Input.action_release(action)


func _tap(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await _frames(2)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _physics(n: int) -> void:
	for i in n:
		await physics_frame
