extends Control
## Menu principal: iniciar o jogo ou sair.

@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	# Na web não existe "sair" do jogo.
	quit_button.visible = not OS.has_feature("web")
	start_button.grab_focus()


func _on_start_pressed() -> void:
	GameState.go_to(GameState.SCENE_CHARACTER_SELECT)


func _on_quit_pressed() -> void:
	get_tree().quit()
