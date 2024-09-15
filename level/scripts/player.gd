extends CharacterBody3D
class_name Character

const NORMAL_SPEED = 5.0
const SPRINT_SPEED = 9.0
const JUMP_VELOCITY = 10

var _current_speed: float

@export_category("Objects")
@export var _body: Node3D = null
@export var _spring_arm_offset: Node3D = null
@onready var camera_3d = $SpringArmOffset/SpringArm3D/Camera3D

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$SpringArmOffset/SpringArm3D/Camera3D.current = is_multiplayer_authority()

func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
		_body.animate(velocity)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			#rpc_id(1, "_on_jump", velocity.y)
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta
	
	if Input.is_action_just_pressed("quit"):
		$"../".exit_game(name.to_int())
	
	_move()
	move_and_slide()
	_body.animate(velocity)

func _move() -> void:
	var _input_direction: Vector2 = Vector2.ZERO
	if is_multiplayer_authority():
		_input_direction = Input.get_vector(
			"move_left", "move_right",
			"move_forward", "move_backward"
			)

	var _direction: Vector3 = transform.basis * Vector3(
		_input_direction.x,
		0,
		_input_direction.y
	).normalized()
	
	is_running()
	_direction = _direction.rotated(Vector3.UP, _spring_arm_offset.rotation.y)
	
	if _direction:
		velocity.x = _direction.x * _current_speed
		velocity.z = _direction.z * _current_speed
		_body.apply_rotation(velocity)
		return
	
	velocity.x = move_toward(velocity.x, 0, _current_speed)
	velocity.z = move_toward(velocity.z, 0, _current_speed)
	
func is_running() -> bool:
	if Input.is_action_pressed("shift"):
		_current_speed = SPRINT_SPEED
		return true
	else:
		_current_speed = NORMAL_SPEED
		return false

#@rpc("any_peer", "call_local")
#func _on_jump(jump_velocity):
	#velocity.y = jump_velocity
