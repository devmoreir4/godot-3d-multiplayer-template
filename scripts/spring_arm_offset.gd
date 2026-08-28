extends Node3D
class_name SpringArmCharacter

const MOUSE_SENSIBILITY: float = 0.005

@export_category("Objects")
@export var _spring_arm: SpringArm3D = null

func _unhandled_input(_event) -> void:
	if not is_multiplayer_authority() or not (_event is InputEventMouseMotion):
		return

	var current_scene := get_tree().get_current_scene()
	if current_scene and current_scene.has_method("is_camera_input_blocked"):
		if current_scene.is_camera_input_blocked():
			return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	rotate_y(-_event.relative.x * MOUSE_SENSIBILITY)
	_spring_arm.rotate_x(-_event.relative.y * MOUSE_SENSIBILITY)
	_spring_arm.rotation.x = clamp(_spring_arm.rotation.x, -PI/4, PI/24)
