extends Control
class_name PauseMenuUI

signal resume_pressed
signal main_menu_pressed
signal quit_pressed

@onready var resume_button: Button = $Overlay/Panel/MarginContainer/Buttons/Resume

func _ready() -> void:
	hide()

func show_menu() -> void:
	show()
	resume_button.grab_focus()

func hide_menu() -> void:
	hide()

func is_menu_visible() -> bool:
	return visible

func _on_resume_pressed() -> void:
	resume_pressed.emit()

func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()

func _on_quit_pressed() -> void:
	quit_pressed.emit()
