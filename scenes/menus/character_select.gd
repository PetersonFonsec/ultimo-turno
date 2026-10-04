extends Control
## Seleção de personagem: um card por personagem de GameState.CHARACTERS.

@onready var cards: HBoxContainer = %Cards
@onready var description_label: Label = %Description
@onready var confirm_button: Button = %ConfirmButton
@onready var back_button: Button = %BackButton

var _buttons: Array[Button] = []


func _ready() -> void:
	var group := ButtonGroup.new()
	for i in GameState.CHARACTERS.size():
		var button := _create_card(GameState.CHARACTERS[i], group)
		button.pressed.connect(_select.bind(i))
		button.focus_entered.connect(_select.bind(i))
		cards.add_child(button)
		_buttons.append(button)

	confirm_button.pressed.connect(_on_confirm_pressed)
	back_button.pressed.connect(_on_back_pressed)

	_select(GameState.selected_character_index)
	_buttons[GameState.selected_character_index].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()


func _create_card(character: Dictionary, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = group
	button.custom_minimum_size = Vector2(200, 260)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 16)
	button.add_child(box)

	# Retrato placeholder: retângulo na cor do personagem.
	var portrait := ColorRect.new()
	portrait.color = character.color
	portrait.custom_minimum_size = Vector2(64, 96)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)

	var name_label := Label.new()
	name_label.text = character.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	box.add_child(name_label)

	return button


func _select(index: int) -> void:
	GameState.selected_character_index = index
	_buttons[index].button_pressed = true
	description_label.text = GameState.CHARACTERS[index].description


func _on_confirm_pressed() -> void:
	GameState.go_to(GameState.SCENE_FIRST_LEVEL)


func _on_back_pressed() -> void:
	GameState.go_to(GameState.SCENE_MAIN_MENU)
