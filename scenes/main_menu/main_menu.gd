extends Control
## Menu inicial mínimo. O título vem de Projeto > Configurações > Application > Config > Name.

const FIRST_LEVEL := "res://scenes/levels/test_level.tscn"

@onready var title_label: Label = %Title
@onready var start_button: Button = %StartButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	title_label.text = str(ProjectSettings.get_setting("application/config/name")).to_upper()
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(get_tree().quit)
	quit_button.visible = not OS.has_feature("web")
	start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(FIRST_LEVEL)
