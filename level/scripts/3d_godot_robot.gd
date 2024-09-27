extends Node3D
class_name Body

const LERP_VELOCITY: float = 0.15

@export_category("Objects")
@export var _character: CharacterBody3D = null
@export var animation_player: AnimationPlayer = null

func apply_rotation(_velocity: Vector3) -> void:
	rotation.y = lerp_angle(rotation.y, atan2(-_velocity.x, -_velocity.z), LERP_VELOCITY)
	
func animate(_velocity: Vector3) -> void:
	if not _character.is_on_floor():
		if _velocity.y < 0:
			animation_player.play("Fall")
		else:
			animation_player.play("Jump")
		return

	if _velocity: 
		if _character.is_running() and _character.is_on_floor():
			animation_player.play("Sprint")
			return
		
		animation_player.play("Run")
		return
	
	animation_player.play("Idle")
	
