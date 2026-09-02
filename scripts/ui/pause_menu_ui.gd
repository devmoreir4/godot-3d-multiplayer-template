class_name PauseMenuUI
extends Control

signal resume_pressed
signal main_menu_pressed
signal quit_pressed

const SAFE_AREA_MARGIN := 16.0

@onready var resume_button: Button = $Overlay/Panel/MarginContainer/Buttons/Resume
@onready var panel: PanelContainer = $Overlay/Panel


func _ready() -> void:
	resized.connect(_update_responsive_layout)
	call_deferred("_update_responsive_layout")
	hide()


func show_menu() -> void:
	show()
	call_deferred("_update_responsive_layout")
	resume_button.grab_focus()


func hide_menu() -> void:
	hide()


func is_menu_visible() -> bool:
	return visible


func _update_responsive_layout() -> void:
	if not panel:
		return
	var available_size := Vector2(
		maxf(1.0, size.x - SAFE_AREA_MARGIN * 2.0), maxf(1.0, size.y - SAFE_AREA_MARGIN * 2.0)
	)
	var panel_size := panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return
	var scale_factor := minf(1.0, minf(available_size.x / panel_size.x, available_size.y / panel_size.y))
	panel.pivot_offset = panel_size * 0.5
	panel.scale = Vector2.ONE * scale_factor


func _on_resume_pressed() -> void:
	resume_pressed.emit()


func _on_main_menu_pressed() -> void:
	main_menu_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
