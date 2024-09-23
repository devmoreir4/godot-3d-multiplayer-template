extends CharacterBody3D
class_name Character

const NORMAL_SPEED = 6.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 10

@onready var nickname = $PlayerNick/Nickname as Label3D

@export_category("Objects")
@export var _body: Node3D = null
@export var _spring_arm_offset: Node3D = null

var _current_speed: float
var _respawn_point = Vector3(0, 5, 0)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	$SpringArmOffset/SpringArm3D/Camera3D.current = is_multiplayer_authority()
	
func _ready():
	if multiplayer.is_server():
		$SpringArmOffset/SpringArm3D/Camera3D.current = false
		
	change_nick(Network.players[multiplayer.get_unique_id()]["nick"])
	
func _physics_process(delta):
	if not is_multiplayer_authority():
		return

	if not is_on_floor():
		velocity.y -= gravity * delta
		_body.animate(velocity)
	
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	else:
		velocity.y -= gravity * delta
	
	_move()
	move_and_slide()
	_body.animate(velocity)
	_check_fall_and_respawn()

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
		
func _check_fall_and_respawn():
	if global_transform.origin.y < -15.0:
		_respawn()
		
func _respawn():
	global_transform.origin = _respawn_point
	velocity = Vector3.ZERO
	
@rpc("any_peer", "reliable")
func change_nick(new_nick: String):
	if nickname:
		nickname.text = new_nick
	else:
		print("error: nickname is null")
