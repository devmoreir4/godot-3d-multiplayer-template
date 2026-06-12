extends CharacterBody3D
class_name Character

const NORMAL_SPEED = 6.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 7.5
const FALL_GRAVITY_MULTIPLIER = 1.6
const MAX_HEALTH := 10
const RESPAWN_DELAY_SECONDS: float = 8.0
const ATTACK_WINDOW_SECONDS := 1.25
const MAX_ATTACK_DISTANCE := 3.5
const BASIC_ATTACK_ID := "unarmed"
const ALLOWED_ANIMATION_STATES := {
	&"Idle": true,
	&"Run": true,
	&"Sprint": true,
	&"Jump": true,
	&"Jump2": true,
	&"Fall": true,
	&"Attack1": true,
	&"Emote2": true
}
const SERVER_ANIMATION_STATES := {
	&"Hurt": true,
	&"Death": true,
	&"Respawn": true
}
const ATTACK_DAMAGE := {
	BASIC_ATTACK_ID: 1,
	"iron_sword": 3,
	"iron_pickaxe": 2
}

enum SkinColor { BLUE, YELLOW, GREEN, RED }

@onready var nickname: Label3D = $PlayerNick/Nickname
@export var skin_color  : SkinColor = SkinColor.BLUE

var player_inventory: PlayerInventory

@export_category("Objects")
@export var _body: Node3D = null
@export var _spring_arm_offset: Node3D = null

@export_category("Skin Colors")
@export var blue_texture : CompressedTexture2D
@export var yellow_texture : CompressedTexture2D
@export var green_texture : CompressedTexture2D
@export var red_texture : CompressedTexture2D

@onready var _bottom_mesh: MeshInstance3D = get_node("GodotRobot3D/RobotArmature/Skeleton3D/Bottom")
@onready var _chest_mesh: MeshInstance3D = get_node("GodotRobot3D/RobotArmature/Skeleton3D/Chest")
@onready var _face_mesh: MeshInstance3D = get_node("GodotRobot3D/RobotArmature/Skeleton3D/Face")
@onready var _limbs_head_mesh: MeshInstance3D = get_node("GodotRobot3D/RobotArmature/Skeleton3D/LimbsAndHead")

@export_category("Character Info")
@export var player_health : int = 10


var _current_speed: float
var _respawn_point = Vector3(0, 5, 0)
var is_dead: bool = false
var is_hurt: bool = false
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var can_double_jump = true
var has_double_jumped = false
var is_attacking := false
var is_collecting := false
var _server_attack_started_at := 0
var _server_attack_id := 0
var _server_attack_active := false
var _server_hit_targets: Dictionary = {}
var _animation_sequence := 0
var _last_applied_animation_sequence := 0
var _last_requested_animation: StringName = &""
var _death_animation_finished := false
var _respawn_timer_active := false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	$SpringArmOffset/SpringArm3D/Camera3D.current = is_multiplayer_authority()

func _ready():
	var is_local_player = is_multiplayer_authority()

	if multiplayer.is_server():
		player_inventory = PlayerInventory.new()
		_add_starting_items()
		if not is_local_player:
			call_deferred("_sync_inventory_to_owner")

	if is_local_player:
		var level_scene = get_tree().get_current_scene()
		var health_bar = level_scene.get_node_or_null("HealthBar")
		if health_bar:
			health_bar.visible = true
			health_bar.set_bar(player_health)

	set_player_skin(skin_color)
	var animation_player := get_node_or_null("GodotRobot3D/AnimationPlayer") as AnimationPlayer
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	weapon_disabled()
	_body.play_animation_state(&"Idle")

func _physics_process(delta):
	if is_dead:
		velocity = Vector3.ZERO
		return
	if not multiplayer.has_multiplayer_peer(): return
	if not is_multiplayer_authority(): return

	if is_hurt:
		velocity.x = 0
		velocity.z = 0
		_apply_gravity(delta)
		move_and_slide()
		return

	var current_scene = get_tree().get_current_scene()
	var should_freeze = false
	if current_scene:
		if current_scene.has_method("is_chat_visible") and current_scene.is_chat_visible():
			should_freeze = true
		elif current_scene.has_method("is_inventory_visible") and current_scene.is_inventory_visible():
			should_freeze = true

	if is_attacking:
		velocity.x = 0
		velocity.z = 0
		_apply_gravity(delta)
		move_and_slide()
		return

	if is_collecting:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	if should_freeze:
		freeze()
		return

	if Input.is_action_just_pressed("pickup") and is_on_floor():
		is_collecting = true
		_request_animation(&"Emote2", true)
		return

	if Input.is_action_just_pressed("attack") and is_on_floor():
		_start_attack()
		return

	if is_on_floor():
		can_double_jump = true
		has_double_jumped = false

		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			can_double_jump = true
			_request_animation(&"Jump", true)
	else:
		_apply_gravity(delta)

		if can_double_jump and not has_double_jumped and Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			has_double_jumped = true
			can_double_jump = false
			_request_animation(&"Jump2", true)

	_move()
	var collided = move_and_slide()
	if collided:
		collision()

	_request_animation(_body.get_movement_animation(velocity))

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var gravity_multiplier = FALL_GRAVITY_MULTIPLIER if velocity.y < 0 else 1.0
	velocity.y -= gravity * gravity_multiplier * delta

func _start_attack() -> void:
	if is_attacking or is_collecting or not is_on_floor():
		return
	is_attacking = true
	velocity.x = 0
	velocity.z = 0
	_request_animation(&"Attack1", true)
	if multiplayer.is_server():
		request_start_attack()
	else:
		request_start_attack.rpc_id(1)

func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		&"Attack1":
			is_attacking = false
			weapon_disabled()
		&"Emote2":
			is_collecting = false
		&"Hurt":
			if is_dead:
				_death_animation_finished = true
				_body.pause_death_pose()
			else:
				is_hurt = false

func _request_animation(state: StringName, restart: bool = false) -> void:
	if not ALLOWED_ANIMATION_STATES.has(state) or is_dead:
		return
	if not restart and _last_requested_animation == state:
		return
	_last_requested_animation = state
	_body.play_animation_state(state, restart)
	if multiplayer.is_server():
		request_animation_state(state)
	else:
		request_animation_state.rpc_id(1, state)

@rpc("any_peer", "call_local", "reliable")
func request_animation_state(state: StringName) -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if not ALLOWED_ANIMATION_STATES.has(state) or is_dead:
		return
	_server_publish_animation(state)

func _server_publish_animation(state: StringName) -> void:
	if not multiplayer.is_server():
		return
	_animation_sequence += 1
	sync_animation_state.rpc(state, _animation_sequence)
	sync_animation_state(state, _animation_sequence)

@rpc("any_peer", "call_local", "reliable")
func sync_animation_state(state: StringName, sequence: int) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id != 1 and not (sender_id == 0 and multiplayer.is_server()):
		return
	if sequence <= _last_applied_animation_sequence:
		return
	_last_applied_animation_sequence = sequence

	if state == &"Death":
		is_dead = true
		is_attacking = false
		is_collecting = false
		is_hurt = false
		velocity = Vector3.ZERO
		_death_animation_finished = false
		weapon_disabled()
	elif state == &"Respawn":
		_last_requested_animation = &"Idle"
	elif state == &"Hurt":
		is_hurt = true
		if is_multiplayer_authority():
			_last_requested_animation = &""
	elif not ALLOWED_ANIMATION_STATES.has(state) and not SERVER_ANIMATION_STATES.has(state):
		return

	# The owner already played input-driven states immediately.
	if is_multiplayer_authority() and ALLOWED_ANIMATION_STATES.has(state):
		return
	_body.play_animation_state(state, true)


func collision():
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody3D:
			applyForceToServerObject.rpc_id( 1, c.get_collider().name, -1 * c.get_normal() )

func _process(_delta):
	if not multiplayer.has_multiplayer_peer(): return
	if not is_multiplayer_authority(): return
	_check_fall_and_respawn()

func freeze():
	velocity.x = 0
	velocity.z = 0
	_current_speed = 0
	_request_animation(&"Idle")

func _move() -> void:
	var _input_direction: Vector2 = Vector2.ZERO
	if is_multiplayer_authority():
		_input_direction = Input.get_vector(
			"move_left", "move_right",
			"move_forward", "move_backward"
			)

	var _direction: Vector3 = transform.basis * Vector3(_input_direction.x, 0, _input_direction.y).normalized()

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

func _start_respawn_timer() -> void:
	if _respawn_timer_active:
		return
	_respawn_timer_active = true
	var timer = get_tree().create_timer(RESPAWN_DELAY_SECONDS)
	timer.timeout.connect(_server_respawn)

func _server_respawn() -> void:
	if not multiplayer.is_server():
		return
	_respawn_timer_active = false
	player_health = MAX_HEALTH
	sync_health.rpc(player_health)
	sync_health(player_health)
	respawn_player.rpc()
	respawn_player()
	_server_publish_animation(&"Respawn")

@rpc("any_peer", "call_local", "reliable")
func respawn_player() -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 1 and not (sender_id == 0 and multiplayer.is_server()):
		return
	global_transform.origin = _respawn_point
	velocity = Vector3.ZERO
	is_dead = false
	is_hurt = false
	is_attacking = false
	is_collecting = false
	_server_attack_active = false
	_death_animation_finished = false
	weapon_disabled()

@rpc("any_peer", "reliable")
func change_nick(new_nick: String):
	if nickname:
		nickname.text = new_nick

func get_texture_from_name(color: SkinColor) -> CompressedTexture2D:
	match color:
		SkinColor.BLUE:
			return blue_texture
		SkinColor.GREEN:
			return green_texture
		SkinColor.RED:
			return red_texture
		SkinColor.YELLOW:
			return yellow_texture
		_: return blue_texture

func set_player_skin(skin_name: SkinColor) -> void:
	var texture = get_texture_from_name(skin_name)

	set_mesh_texture(_bottom_mesh, texture)
	set_mesh_texture(_chest_mesh, texture)
	set_mesh_texture(_face_mesh, texture)
	set_mesh_texture(_limbs_head_mesh, texture)

func set_mesh_texture(mesh_instance: MeshInstance3D, texture: CompressedTexture2D) -> void:
	if mesh_instance:
		var new_material := StandardMaterial3D.new()
		new_material.albedo_texture = texture
		mesh_instance.set_surface_override_material(0, new_material)

@rpc("any_peer", "call_local", "reliable")
func request_inventory_sync():
	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if not _is_owner_request():
		push_warning("Client " + str(requesting_client) + " tried to request inventory for player " + str(get_multiplayer_authority()))
		return

	if player_inventory:
		_sync_inventory_to_owner()

@rpc("any_peer", "call_local", "reliable")
func sync_inventory_to_owner(inventory_data: Dictionary):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 1 and not (sender_id == 0 and multiplayer.is_server()):
		return

	if not is_multiplayer_authority():
		return

	if not player_inventory:
		player_inventory = PlayerInventory.new()
	player_inventory.from_dict(inventory_data)

	var level_scene = get_tree().get_current_scene()
	if level_scene:
		if is_multiplayer_authority() or get_multiplayer_authority() == multiplayer.get_unique_id():
			if level_scene.has_method("update_local_inventory_display"):
				level_scene.update_local_inventory_display()
			if level_scene.has_node("InventoryUI"):
				var inventory_ui = level_scene.get_node("InventoryUI")
				if inventory_ui.visible and inventory_ui.has_method("refresh_display"):
					inventory_ui.refresh_display()

@rpc("any_peer", "call_local", "reliable")
func request_move_item(from_slot: int, to_slot: int, quantity: int = -1):
	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if not _is_owner_request():
		push_warning("Client " + str(requesting_client) + " tried to modify inventory for player " + str(get_multiplayer_authority()))
		return

	if not player_inventory:
		return

	if from_slot < 0 or from_slot >= PlayerInventory.INVENTORY_SIZE or to_slot < 0 or to_slot >= PlayerInventory.INVENTORY_SIZE:
		push_warning("Invalid slot indices: from=" + str(from_slot) + " to=" + str(to_slot))
		return

	var success = false
	if quantity == -1:
		success = player_inventory.move_item(from_slot, to_slot)
		if not success:
			success = player_inventory.swap_items(from_slot, to_slot)
	else:
		success = player_inventory.move_item(from_slot, to_slot, quantity)

	if success:
		_sync_inventory_to_owner()

@rpc("any_peer", "call_local", "reliable")
func request_add_item(item_id: String, quantity: int = 1):
	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	var is_local_server_call = requesting_client == 0 and multiplayer.get_unique_id() == 1
	if requesting_client != 1 and not is_local_server_call:
		push_warning("Client " + str(requesting_client) + " tried to add items to player " + str(get_multiplayer_authority()))
		return

	if not player_inventory:
		return

	if quantity <= 0:
		push_warning("Invalid quantity: " + str(quantity))
		return

	var item = ItemDatabase.get_item(item_id)
	if not item:
		push_warning("Item not found: " + item_id)
		return

	var remaining = player_inventory.add_item(item, quantity)
	var added = quantity - remaining

	if added > 0:
		_sync_inventory_to_owner()

func request_add_single_item(item_id: String) -> bool:
	if not multiplayer.is_server():
		return false

	if player_inventory == null:
		return false

	var item = ItemDatabase.get_item(item_id)
	if not item:
		push_warning("Item not found: " + item_id)
		return false

	var remaining = player_inventory.add_item(item, 1)

	if remaining == 0:
		_sync_inventory_to_owner()
		return true
	return false


@rpc("any_peer", "call_local", "reliable")
func request_remove_item(item_id: String, quantity: int = 1):
	if not multiplayer.is_server():
		return

	var requesting_client = multiplayer.get_remote_sender_id()
	if not _is_owner_request():
		push_warning("Client " + str(requesting_client) + " tried to remove items from player " + str(get_multiplayer_authority()))
		return

	if not player_inventory:
		return

	if quantity <= 0:
		push_warning("Invalid quantity: " + str(quantity))
		return

	var removed = player_inventory.remove_item(item_id, quantity)

	if removed > 0:
		_sync_inventory_to_owner()

@rpc("authority", "call_local", "reliable")
func add_world_item( scene_path:String, player_position:Vector3) -> void:
	var item_container = get_node_or_null("/root/Level/Environment/ItemContainer")
	if not item_container:
		push_warning("ItemContainer not found at /root/Level/Environment/ItemContainer")
		return
	if scene_path.is_empty() or not ResourceLoader.exists(scene_path):
		push_warning("Cannot add world item: invalid scene path '" + scene_path + "'")
		return
	var packed_scene = load(scene_path) as PackedScene
	if not packed_scene:
		push_warning("Cannot add world item: scene path is not a PackedScene '" + scene_path + "'")
		return
	var instance_item = packed_scene.instantiate()
	instance_item.position = player_position
	item_container.add_child(instance_item, true)

func get_inventory() -> PlayerInventory:
	return player_inventory

func _sync_inventory_to_owner() -> void:
	if not multiplayer.is_server() or not player_inventory:
		return
	var owner_id = get_multiplayer_authority()
	if owner_id == 1:
		sync_inventory_to_owner(player_inventory.to_dict())
	else:
		sync_inventory_to_owner.rpc_id(owner_id, player_inventory.to_dict())

@rpc("any_peer", "call_local", "reliable")
func request_equip_item(from_slot: int, item_type: Item.ItemType) -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if not player_inventory or from_slot < 0 or from_slot >= PlayerInventory.INVENTORY_SIZE:
		return
	if item_type != Item.ItemType.WEAPON and item_type != Item.ItemType.ARMOR:
		return
	if player_inventory.equip_from_slot(from_slot, item_type):
		_sync_inventory_to_owner()
		_sync_equipment_appearance()

@rpc("any_peer", "call_local", "reliable")
func request_unequip_item(item_type: Item.ItemType, destination_slot: int = -1) -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if not player_inventory:
		return
	if item_type != Item.ItemType.WEAPON and item_type != Item.ItemType.ARMOR:
		return
	if destination_slot < -1 or destination_slot >= PlayerInventory.INVENTORY_SIZE:
		return
	if player_inventory.unequip_to_slot(item_type, destination_slot):
		_sync_inventory_to_owner()
		_sync_equipment_appearance()

func _is_owner_request() -> bool:
	var sender := multiplayer.get_remote_sender_id()
	return sender == get_multiplayer_authority() or (sender == 0 and multiplayer.is_server())

func _sync_equipment_appearance() -> void:
	if not multiplayer.is_server() or not player_inventory:
		return
	var weapon_id := player_inventory.equipped_weapon.item_id
	var armor_id := player_inventory.equipped_armor.item_id
	sync_equipment_appearance.rpc(weapon_id, armor_id)
	sync_equipment_appearance(weapon_id, armor_id)

@rpc("any_peer", "reliable")
func sync_equipment_appearance(weapon_id: String, armor_id: String) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 1 and not (sender == 0 and multiplayer.is_server()):
		return
	_set_equipment_visibility(weapon_id, armor_id)

func _set_equipment_visibility(weapon_id: String, armor_id: String) -> void:
	var sword := get_node_or_null("GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/IronSword") as Node3D
	var pickaxe := get_node_or_null("GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/IronPickaxe") as Node3D
	var helmet := get_node_or_null("GodotRobot3D/RobotArmature/Skeleton3D/HeadAttach/VikingHelmet") as Node3D
	if sword:
		sword.visible = weapon_id == "iron_sword"
	if pickaxe:
		pickaxe.visible = weapon_id == "iron_pickaxe"
	if helmet:
		helmet.visible = armor_id == "viking_helmet"

func _add_starting_items():
	if not player_inventory:
		return

	var sword = ItemDatabase.get_item("iron_sword")
	var potion = ItemDatabase.get_item("health_potion")
	var gem = ItemDatabase.get_item("magic_gem")
	var armor = ItemDatabase.get_item("viking_helmet")
	
	if sword:
		player_inventory.add_item(sword, 1)
	if potion:
		player_inventory.add_item(potion, 3)
	if gem:
		player_inventory.add_item(gem, 5)
	if armor:
		player_inventory.add_item(armor, 1)

func pickup():
	if multiplayer.is_server():
		_server_pickup()
	else:
		request_pickup.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func request_pickup() -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if is_dead or is_hurt or not _is_grounded_on_server():
		return
	_server_pickup()

func _server_pickup() -> void:
	var array_of_items = get_node("GodotRobot3D/InfrontArea3D").get_overlapping_bodies()
	for item in array_of_items:
		if item.get("item_id") != null:
			var result = request_add_single_item(item.get("item_id"))
			if result:
				if item.is_inside_tree():
					item.queue_free()


@rpc("authority", "call_local", "reliable")
func delete_node_on_all(node_path: NodePath) -> void:
	var node = get_node_or_null(node_path)
	if node:
		node.queue_free()


@rpc("any_peer", "call_local", "reliable")
func applyForceToServerObject(nameOfObject: String, normal: Vector3):
	var object_node = get_node_or_null("/root/Level/Environment/ItemContainer")
	if object_node:
		for n in object_node.get_children():
			if n.name == nameOfObject:
				n.apply_force(normal * 100)

@rpc("any_peer", "call_local", "reliable")
func request_start_attack() -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if is_dead or is_hurt or not _is_grounded_on_server():
		return
	if _server_attack_active:
		if Time.get_ticks_msec() - _server_attack_started_at <= int(ATTACK_WINDOW_SECONDS * 1000.0):
			return
		_server_attack_active = false
	is_attacking = true
	_server_attack_active = true
	_server_attack_id += 1
	_server_attack_started_at = Time.get_ticks_msec()
	_server_hit_targets.clear()
	var current_attack_id := _server_attack_id
	get_tree().create_timer(ATTACK_WINDOW_SECONDS).timeout.connect(
		func():
			if current_attack_id == _server_attack_id:
				_server_attack_active = false
	)

@rpc("any_peer", "call_local", "reliable")
func request_attack_hit(target_path: NodePath, attack_source: String) -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if not _is_server_attack_active() or not _is_grounded_on_server():
		return
	var expected_source := _get_equipped_attack_source()
	if attack_source != expected_source or not ATTACK_DAMAGE.has(expected_source):
		return
	var target = get_node_or_null(target_path)
	if not target or not (target is Character) or target == self or target.is_dead:
		return
	if global_position.distance_to(target.global_position) > MAX_ATTACK_DISTANCE:
		return
	var target_id := target.get_instance_id()
	if _server_hit_targets.has(target_id):
		return
	_server_hit_targets[target_id] = _server_attack_id
	target.player_health = clampi(target.player_health - int(ATTACK_DAMAGE[expected_source]), 0, MAX_HEALTH)
	target.sync_health.rpc(target.player_health)
	target.sync_health(target.player_health)
	if target.player_health <= 0:
		target._server_enter_death()
	else:
		target._server_publish_animation(&"Hurt")

func _server_enter_death() -> void:
	if not multiplayer.is_server() or is_dead:
		return
	is_dead = true
	is_hurt = false
	is_attacking = false
	is_collecting = false
	velocity = Vector3.ZERO
	_server_attack_active = false
	weapon_disabled()
	_server_publish_animation(&"Death")
	_start_respawn_timer()

func _is_server_attack_active() -> bool:
	if not _server_attack_active:
		return false
	if Time.get_ticks_msec() - _server_attack_started_at > int(ATTACK_WINDOW_SECONDS * 1000.0):
		_server_attack_active = false
		return false
	return true

func _get_equipped_attack_source() -> String:
	if not player_inventory or player_inventory.equipped_weapon.is_empty():
		return BASIC_ATTACK_ID
	return player_inventory.equipped_weapon.item_id

func _is_grounded_on_server() -> bool:
	if not multiplayer.is_server() or not is_inside_tree():
		return false
	var query := PhysicsRayQueryParameters3D.new()
	query.from = global_position + Vector3.UP * 0.15
	query.to = global_position + Vector3.DOWN * 0.3
	query.collision_mask = 2
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

@rpc("any_peer", "call_local", "reliable")
func sync_health(new_health: int):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 1 and not (sender_id == 0 and multiplayer.is_server()):
		return
	player_health = clampi(new_health, 0, MAX_HEALTH)
	if is_multiplayer_authority():
		var level_scene = get_tree().get_current_scene()
		if level_scene and level_scene.has_node("HealthBar"):
			level_scene.get_node("HealthBar").set_bar(player_health)

func weapon_disabled():
	var hurt_area = get_node_or_null("GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/HurtArea")
	if hurt_area:
		hurt_area.monitoring = false
	var pickaxe_area = get_node_or_null("GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/IronPickaxe/HurtArea")
	if pickaxe_area:
		pickaxe_area.monitoring = false
	var sword_area = get_node_or_null("GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/IronSword/HurtArea")
	if sword_area:
		sword_area.monitoring = false

func weapon_enabled():
	if not is_multiplayer_authority():
		return
	weapon_disabled()
	var attack_source := BASIC_ATTACK_ID
	if player_inventory and not player_inventory.equipped_weapon.is_empty():
		attack_source = player_inventory.equipped_weapon.item_id
	var area_path := "GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/HurtArea"
	if attack_source == "iron_sword":
		area_path = "GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/IronSword/HurtArea"
	elif attack_source == "iron_pickaxe":
		area_path = "GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/IronPickaxe/HurtArea"
	var active_area := get_node_or_null(area_path) as Area3D
	if active_area:
		active_area.monitoring = true
	
