class_name Body
extends Node3D

const LERP_VELOCITY: float = 0.15

@export_category("Objects")
@export var _character: CharacterBody3D = null
@export var animation_player: AnimationPlayer = null

var _current_state: StringName = &""


func apply_rotation(_velocity: Vector3) -> void:
	var new_rotation_y = lerp_angle(rotation.y, atan2(-_velocity.x, -_velocity.z), LERP_VELOCITY)
	rotation.y = new_rotation_y


func get_movement_animation(_velocity: Vector3) -> StringName:
	if not _character.is_on_floor():
		if _velocity.y < 0:
			return &"Fall"
		if _current_state == &"Jump2":
			return &"Jump2"
		return &"Jump"

	if _velocity:
		if _character._is_running() and _character.is_on_floor():
			return &"Sprint"
		return &"Run"

	return &"Idle"


func play_animation_state(state: StringName, restart: bool = false) -> void:
	if not animation_player:
		return
	if not animation_player.has_animation(state):
		return
	if not restart and _current_state == state and animation_player.is_playing():
		return
	_current_state = state
	animation_player.play(state)
