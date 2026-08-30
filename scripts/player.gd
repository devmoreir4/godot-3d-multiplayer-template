extends CharacterBody3D
class_name Character

const NORMAL_SPEED = 6.0
const SPRINT_SPEED = 10.0
const JUMP_VELOCITY = 7.5
const FALL_GRAVITY_MULTIPLIER = 1.6
const BASE_NICKNAME_HEIGHT := 2.0
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
const HAT_NODES_BY_ITEM := {
	"bucket_hat": "BucketHat",
	"cowboy_hat": "CowboyHat",
	"witch_hat": "WitchHat",
	"beanie": "Beanie"
}
const WEAPON_NODES_BY_ITEM := {
	"sword": "Sword",
	"sword_big": "SwordBig"
}
const BACKPACK_NODES_BY_ITEM := {
	"backpack": "Backpack"
}
const HEAD_EQUIPMENT_PATH := "GodotRobot3D/RobotArmature/Skeleton3D/HeadAttach/"
const HAND_EQUIPMENT_PATH := "GodotRobot3D/RobotArmature/Skeleton3D/LeftHandAttach/"
const BACK_EQUIPMENT_PATH := "GodotRobot3D/RobotArmature/Skeleton3D/BackAttach/"

enum SkinColor { BLUE, YELLOW, GREEN, RED }

@onready var nickname: Label3D = $PlayerNick/Nickname
@export var skin_color  : SkinColor = SkinColor.BLUE

@export_category("Nickname")
@export_range(0.0, 1.0, 0.01) var nickname_clearance: float = 0.2

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

var _current_speed: float
var _spawn_point = Vector3(0, 5, 0)
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var can_double_jump = true
var has_double_jumped = false
var is_attacking := false
var is_collecting := false
var _animation_sequence := 0
var _last_applied_animation_sequence := 0
var _last_requested_animation: StringName = &""
var _appearance_sync_requesters: Dictionary = {}

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())
	$SpringArmOffset/SpringArm3D/Camera3D.current = is_multiplayer_authority()

func _ready():
	if multiplayer.is_server():
		player_inventory = PlayerInventory.new()
		_add_starting_items()
		call_deferred("_sync_equipment_appearance")
		if not is_multiplayer_authority():
			call_deferred("_sync_inventory_to_owner")

	set_player_skin(skin_color)
	var animation_player := get_node_or_null("GodotRobot3D/AnimationPlayer") as AnimationPlayer
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)
	_body.play_animation_state(&"Idle")
	nickname.visible = true
	_set_nickname_height(BASE_NICKNAME_HEIGHT)
	call_deferred("_update_nickname_height")
	if not multiplayer.is_server():
		call_deferred("_request_equipment_appearance")

func _physics_process(delta):
	if not multiplayer.has_multiplayer_peer(): return
	if not is_multiplayer_authority(): return

	var current_scene = get_tree().get_current_scene()
	var should_freeze = false
	if current_scene:
		if current_scene.has_method("is_gameplay_input_blocked") and current_scene.is_gameplay_input_blocked():
			should_freeze = true
		elif current_scene.has_method("is_chat_visible") and current_scene.is_chat_visible():
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
		_apply_gravity(delta)
		move_and_slide()
		return

	if should_freeze:
		freeze()
		_apply_gravity(delta)
		move_and_slide()
		_request_animation(_body.get_movement_animation(velocity))
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

func _on_animation_finished(animation_name: StringName) -> void:
	match animation_name:
		&"Attack1":
			is_attacking = false
		&"Emote2":
			is_collecting = false

func _request_animation(state: StringName, restart: bool = false) -> void:
	if not ALLOWED_ANIMATION_STATES.has(state):
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
	if not ALLOWED_ANIMATION_STATES.has(state):
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

	if not ALLOWED_ANIMATION_STATES.has(state):
		return

	# The owner already played the input-driven state immediately.
	if is_multiplayer_authority():
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
	_check_out_of_bounds()

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

func _check_out_of_bounds():
	if global_transform.origin.y < -15.0:
		_reset_position_after_fall()

func _reset_position_after_fall():
	global_transform.origin = _spawn_point
	velocity = Vector3.ZERO

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

	if not player_inventory.is_slot_active(from_slot) or not player_inventory.is_slot_active(to_slot):
		push_warning("Invalid slot indices: from=" + str(from_slot) + " to=" + str(to_slot))
		return

	if quantity != -1 and quantity <= 0:
		push_warning("Invalid move quantity: " + str(quantity))
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
	if not player_inventory or not player_inventory.is_slot_active(from_slot):
		return
	if item_type != Item.ItemType.WEAPON and item_type != Item.ItemType.HAT and item_type != Item.ItemType.BACKPACK:
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
	if item_type != Item.ItemType.WEAPON and item_type != Item.ItemType.HAT and item_type != Item.ItemType.BACKPACK:
		return
	if destination_slot < -1 or destination_slot >= PlayerInventory.MAX_INVENTORY_SIZE:
		return
	if destination_slot >= 0 and not player_inventory.is_slot_active(destination_slot):
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
	var hat_id := player_inventory.equipped_hat.item_id
	var backpack_id := player_inventory.equipped_backpack.item_id
	var nickname_height := _calculate_nickname_height(hat_id)
	_broadcast_nickname_height(nickname_height)
	sync_equipment_appearance.rpc(weapon_id, hat_id, backpack_id)
	sync_equipment_appearance(weapon_id, hat_id, backpack_id)

func _request_equipment_appearance() -> void:
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		return
	request_equipment_appearance.rpc_id(1)

@rpc("any_peer", "reliable")
func request_equipment_appearance() -> void:
	if not multiplayer.is_server() or not player_inventory:
		return
	var requester_id := multiplayer.get_remote_sender_id()
	if requester_id <= 0:
		return
	if _appearance_sync_requesters.has(requester_id):
		return
	_appearance_sync_requesters[requester_id] = true
	_sync_equipment_appearance_to_peer(requester_id)

func _sync_equipment_appearance_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or not player_inventory or peer_id <= 0:
		return
	var weapon_id := player_inventory.equipped_weapon.item_id
	var hat_id := player_inventory.equipped_hat.item_id
	var backpack_id := player_inventory.equipped_backpack.item_id
	sync_equipment_appearance.rpc_id(
		peer_id,
		weapon_id,
		hat_id,
		backpack_id
	)

@rpc("any_peer", "reliable")
func sync_equipment_appearance(
	weapon_id: String,
	hat_id: String,
	backpack_id: String
) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if sender != 1 and not (sender == 0 and multiplayer.is_server()):
		return
	_set_equipment_visibility(weapon_id, hat_id, backpack_id)

func _set_equipment_visibility(
	weapon_id: String,
	hat_id: String,
	backpack_id: String
) -> void:
	_set_equipment_nodes_visibility(HEAD_EQUIPMENT_PATH, HAT_NODES_BY_ITEM, hat_id)
	_set_equipment_nodes_visibility(HAND_EQUIPMENT_PATH, WEAPON_NODES_BY_ITEM, weapon_id)
	_set_equipment_nodes_visibility(BACK_EQUIPMENT_PATH, BACKPACK_NODES_BY_ITEM, backpack_id)

func _broadcast_nickname_height(height: float) -> void:
	if not multiplayer.is_server():
		return
	var level_scene := get_tree().get_current_scene()
	if level_scene and level_scene.has_method("register_player_nickname_height"):
		level_scene.register_player_nickname_height(get_multiplayer_authority(), height)

func _set_equipment_nodes_visibility(
	parent_path: String,
	nodes_by_item: Dictionary,
	equipped_item_id: String
) -> void:
	for item_id in nodes_by_item:
		var equipment := get_node_or_null(parent_path + str(nodes_by_item[item_id])) as Node3D
		if equipment:
			equipment.visible = item_id == equipped_item_id

func _update_nickname_height(hat_id: String = "") -> void:
	if not nickname:
		return
	nickname.visible = true
	_set_nickname_height(_calculate_nickname_height(hat_id))

func _calculate_nickname_height(hat_id: String) -> float:
	var target_height := BASE_NICKNAME_HEIGHT
	var equipped_hat := _get_hat_node(hat_id)
	if equipped_hat:
		var hat_top := _get_visual_top(equipped_hat)
		if hat_top > -INF and hat_top < INF:
			target_height = max(BASE_NICKNAME_HEIGHT, hat_top + nickname_clearance)
	return target_height

func _set_nickname_height(height: float) -> void:
	var nickname_position := nickname.position
	nickname_position.y = height
	nickname.position = nickname_position

func apply_synced_nickname_height(height: float) -> void:
	if not nickname:
		return
	nickname.visible = true
	if height > -INF and height < INF:
		_set_nickname_height(maxf(BASE_NICKNAME_HEIGHT, height))
	else:
		_set_nickname_height(BASE_NICKNAME_HEIGHT)

func get_current_nickname_height() -> float:
	return nickname.position.y if nickname else BASE_NICKNAME_HEIGHT

func _get_hat_node(hat_id: String) -> Node3D:
	if HAT_NODES_BY_ITEM.has(hat_id):
		var requested_hat_path := HEAD_EQUIPMENT_PATH + str(HAT_NODES_BY_ITEM[hat_id])
		var requested_hat := get_node_or_null(requested_hat_path) as Node3D
		if requested_hat:
			return requested_hat
	return null

func _get_visual_top(root: Node3D) -> float:
	var visual_top := -INF
	if root is MeshInstance3D:
		visual_top = _get_mesh_top(root as MeshInstance3D)

	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance:
			visual_top = max(visual_top, _get_mesh_top(mesh_instance))
	return visual_top

func _get_mesh_top(mesh_instance: MeshInstance3D) -> float:
	var visual_top := -INF
	var mesh_bounds := mesh_instance.get_aabb()
	for endpoint_index in range(8):
		var endpoint_global := mesh_instance.to_global(mesh_bounds.get_endpoint(endpoint_index))
		visual_top = max(visual_top, to_local(endpoint_global).y)
	return visual_top

func _add_starting_items():
	if not player_inventory:
		return

	var backpack := ItemDatabase.get_item("backpack")
	if backpack:
		player_inventory.add_item(backpack, 1)

	var starting_item_ids: Array[String] = [
		"bucket_hat", "cowboy_hat", "witch_hat", "beanie",
		"sword", "sword_big",
		"chicken_leg", "bone", "chalice"
	]

	for item_id in starting_item_ids:
		var item = ItemDatabase.get_item(item_id)
		if item:
			player_inventory.add_item(item, 1)

func pickup():
	if multiplayer.is_server():
		_server_pickup()
	else:
		request_pickup.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func request_pickup() -> void:
	if not multiplayer.is_server() or not _is_owner_request():
		return
	if not _is_grounded_on_server():
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
	
