class_name HUD
extends CanvasLayer
## Vida, mensagens centrais (morte, conclusão, pausa) e dica de controles.

const PIP_FULL := Color("ff4d5e")
const PIP_EMPTY := Color("3a2630")

@onready var health_pips: HBoxContainer = %HealthPips
@onready var message_box: Control = %MessageBox
@onready var message_title: Label = %MessageTitle
@onready var message_subtitle: Label = %MessageSubtitle


func _ready() -> void:
	hide_message()


func set_health(current: int, maximum: int) -> void:
	while health_pips.get_child_count() < maximum:
		var pip := ColorRect.new()
		pip.custom_minimum_size = Vector2(8, 8)
		health_pips.add_child(pip)
	for i in health_pips.get_child_count():
		var pip := health_pips.get_child(i) as ColorRect
		pip.visible = i < maximum
		pip.color = PIP_FULL if i < current else PIP_EMPTY


func show_message(title: String, subtitle: String) -> void:
	message_title.text = title
	message_subtitle.text = subtitle
	message_box.show()


func hide_message() -> void:
	message_box.hide()
