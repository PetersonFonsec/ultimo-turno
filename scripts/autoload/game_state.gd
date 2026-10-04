extends Node
## Estado global do jogo (autoload "GameState").
## Guarda a lista de personagens jogáveis e qual foi escolhido.

const SCENE_MAIN_MENU := "res://scenes/menus/main_menu.tscn"
const SCENE_CHARACTER_SELECT := "res://scenes/menus/character_select.tscn"
const SCENE_FIRST_LEVEL := "res://scenes/levels/level_01.tscn"

## Personagens placeholder: cor no lugar do sprite e atributos de movimento.
const CHARACTERS: Array[Dictionary] = [
	{
		"id": "equilibrado",
		"name": "Personagem 1",
		"description": "Equilibrado em velocidade e pulo.",
		"color": Color("e0a43a"),
		"speed": 300.0,
		"jump_velocity": -560.0,
	},
	{
		"id": "rapido",
		"name": "Personagem 2",
		"description": "Mais rápido, pula menos.",
		"color": Color("4fb0c6"),
		"speed": 400.0,
		"jump_velocity": -480.0,
	},
	{
		"id": "saltador",
		"name": "Personagem 3",
		"description": "Mais lento, pula mais alto.",
		"color": Color("c65f8f"),
		"speed": 230.0,
		"jump_velocity": -680.0,
	},
]

var selected_character_index: int = 0


func get_selected_character() -> Dictionary:
	return CHARACTERS[selected_character_index]


func go_to(scene_path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
