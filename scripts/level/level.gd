extends Node3D

const MAX_CHAT_MESSAGE_LENGTH := 160
const MIN_NICKNAME_HEIGHT := 2.0
const MAX_NICKNAME_HEIGHT := 8.0

@export var player_scene: PackedScene

var chat_visible := false
var inventory_visible := false
var player_list_visible := false

var _player_nickname_heights: Dictionary = {}
var _nickname_heights_requested := false
var _nickname_height_requesters: Dictionary = {}

@onready var players_container: Node3D = $PlayersContainer
@onready var main_menu: MainMenuUI = $MainMenuUI
@onready var multiplayer_chat: MultiplayerChatUI = $MultiplayerChatUI
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var player_list_ui: PlayerListUI = $PlayerListUI
@onready var pause_menu: PauseMenuUI = $PauseMenuUI


func _ready():
	after_ready()

	if DisplayServer.get_name() == "headless":
		Network.start_host("", "")

	pause_menu.hide_menu()
	main_menu.show_menu()
	multiplayer_chat.set_process_input(true)

	main_menu.host_pressed.connect(_on_host_pressed)
	main_menu.join_pressed.connect(_on_join_pressed)
	main_menu.quit_pressed.connect(_on_quit_pressed)
	pause_menu.resume_pressed.connect(_on_pause_resume_pressed)
	pause_menu.main_menu_pressed.connect(_on_pause_main_menu_pressed)
	pause_menu.quit_pressed.connect(_on_pause_quit_pressed)

	if inventory_ui:
		inventory_ui.inventory_closed.connect(_on_inventory_closed)

	if multiplayer_chat:
		multiplayer_chat.message_sent.connect(_on_chat_message_sent)

	Network.server_disconnected.connect(_on_server_disconnected)
	Network.connect("player_connected", Callable(self, "_on_player_connected"))
	multiplayer.peer_disconnected.connect(_remove_player)
	_update_mouse_mode()


func _process(_delta: float) -> void:
	var can_show_player_list := (
		not main_menu.is_menu_visible() and not pause_menu.is_menu_visible() and multiplayer.has_multiplayer_peer()
	)
	if Input.is_key_pressed(KEY_TAB) and can_show_player_list:
		if not player_list_visible:
			_show_player_list()
	elif player_list_visible:
		_hide_player_list()


func after_ready():
	var ip_address: String
	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			ip_address = IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")), IP.TYPE_IPV4)
	elif OS.has_feature("x11"):
		if OS.has_environment("HOSTNAME"):
			ip_address = IP.resolve_hostname(str(OS.get_environment("HOSTNAME")), IP.TYPE_IPV4)
	elif OS.has_feature("OSX"):
		if OS.has_environment("HOSTNAME"):
			ip_address = IP.resolve_hostname(str(OS.get_environment("HOSTNAME")), IP.TYPE_IPV4)
	main_menu.address_input.text = ip_address


func _on_server_disconnected():
	_reset_session_ui()


func _reset_session_ui() -> void:
	for child in players_container.get_children():
		child.queue_free()

	var loot_root := get_node_or_null("Environment/ItemContainer")
	if loot_root:
		for child in loot_root.get_children():
			child.queue_free()

	chat_visible = false
	inventory_visible = false
	_hide_player_list()
	_player_nickname_heights.clear()
	_nickname_heights_requested = false
	_nickname_height_requesters.clear()
	multiplayer_chat.close_chat()
	multiplayer_chat.clear_chat()
	if inventory_ui:
		inventory_ui.close_inventory()
		inventory_ui.current_player = null
	_hide_pause_menu(false)
	main_menu.show_menu()
	_update_mouse_mode()


func _on_player_connected(peer_id, player_info):
	var player = _add_player(peer_id, player_info)
	if multiplayer.is_server() and player:
		player.call_deferred("_sync_inventory_to_owner")
	if multiplayer.is_server():
		if peer_id != 1:
			call_deferred("_sync_nickname_heights_to_peer", peer_id)
	elif not _nickname_heights_requested:
		_nickname_heights_requested = true
		call_deferred("_request_nickname_heights")
	_refresh_player_list()


func _on_host_pressed(nickname: String, skin: String):
	var error = Network.start_host(nickname, skin)
	if error:
		push_warning("Failed to host game. Error: " + str(error))
		main_menu.show_menu()
		_update_mouse_mode()
		return
	main_menu.hide_menu()
	_update_mouse_mode()


func _on_join_pressed(nickname: String, skin: String, address: String):
	var error = Network.join_game(nickname, skin, address)
	if error:
		push_warning("Failed to join game. Error: " + str(error))
		main_menu.show_menu()
		_update_mouse_mode()
		return
	main_menu.hide_menu()
	_update_mouse_mode()


func _add_player(id: int, player_info: Dictionary) -> Character:
	if DisplayServer.get_name() == "headless" and id == 1:
		return null

	if players_container.has_node(str(id)):
		return players_container.get_node(str(id)) as Character

	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = get_spawn_point(id)
	players_container.add_child(player, true)

	var nick = Network.sanitize_nickname(str(player_info.get("nick", "")), "Player_" + str(id))
	player.nickname.text = nick

	var skin_enum = Network.sanitize_skin_value(player_info.get("skin", Character.SkinColor.BLUE))
	player.set_player_skin(skin_enum)
	_apply_player_nickname_height(id)
	return player


func get_spawn_point(id: int) -> Vector3:
	var spawn_angle := fmod(float(id) * 2.399963229728653, 2.0 * PI)
	var spawn_point := Vector2.from_angle(spawn_angle) * 10
	return Vector3(spawn_point.x, 0, spawn_point.y)


func _remove_player(id):
	_player_nickname_heights.erase(id)
	if not players_container.has_node(str(id)):
		call_deferred("_refresh_player_list")
		return
	var player_node = players_container.get_node(str(id))
	if player_node:
		player_node.queue_free()
	call_deferred("_refresh_player_list")


func _on_quit_pressed() -> void:
	Network.leave_game()
	get_tree().quit()


func toggle_chat():
	if main_menu.is_menu_visible() or is_gameplay_input_blocked():
		return

	multiplayer_chat.toggle_chat()
	chat_visible = multiplayer_chat.is_chat_visible()
	_update_mouse_mode()


func is_chat_visible() -> bool:
	return multiplayer_chat.is_chat_visible()


func _input(event):
	if event.is_action_pressed("pause"):
		_handle_pause_action()
		get_viewport().set_input_as_handled()
		return

	if is_gameplay_input_blocked():
		return

	if event.is_action_pressed("toggle_chat"):
		toggle_chat()
	elif chat_visible and multiplayer_chat.message.has_focus():
		pass
	elif event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug_add_item()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		_debug_print_inventory()


func _on_chat_message_sent(message_text: String) -> void:
	chat_visible = multiplayer_chat.is_chat_visible()
	_update_mouse_mode()

	var trimmed_message = _sanitize_chat_message(message_text)
	if trimmed_message.is_empty():
		return

	if multiplayer.is_server():
		_broadcast_chat_message(multiplayer.get_unique_id(), trimmed_message)
	else:
		submit_chat_message.rpc_id(1, trimmed_message)


@rpc("any_peer", "reliable")
func submit_chat_message(message_text: String):
	if not multiplayer.is_server():
		return
	var sender_id = multiplayer.get_remote_sender_id()
	var trimmed_message = _sanitize_chat_message(message_text)
	if trimmed_message.is_empty():
		return
	_broadcast_chat_message(sender_id, trimmed_message)


func _broadcast_chat_message(sender_id: int, message_text: String):
	var player_info = Network.players.get(sender_id, {})
	var nick = Network.sanitize_nickname(str(player_info.get("nick", "")), "Player_" + str(sender_id))
	show_chat_message.rpc(nick, message_text)


@rpc("authority", "call_local", "reliable")
func show_chat_message(nick: String, msg: String):
	multiplayer_chat.add_message(nick, msg)


func _sanitize_chat_message(message_text: String) -> String:
	var clean = message_text.strip_edges()
	if clean.length() > MAX_CHAT_MESSAGE_LENGTH:
		clean = clean.substr(0, MAX_CHAT_MESSAGE_LENGTH)
	return clean


func toggle_inventory():
	if main_menu.is_menu_visible() or is_gameplay_input_blocked():
		return

	var local_player = _get_local_player()
	if not local_player:
		return

	inventory_visible = !inventory_visible
	if inventory_visible:
		inventory_ui.open_inventory(local_player)
	else:
		inventory_ui.close_inventory()
	_update_mouse_mode()


func is_inventory_visible() -> bool:
	return inventory_visible


func _show_player_list() -> void:
	if main_menu.is_menu_visible() or pause_menu.is_menu_visible() or not multiplayer.has_multiplayer_peer():
		return
	player_list_visible = true
	player_list_ui.show_players(Network.players, multiplayer.get_unique_id())


func _hide_player_list() -> void:
	player_list_visible = false
	if player_list_ui:
		player_list_ui.hide_players()


func _refresh_player_list() -> void:
	if player_list_visible and player_list_ui:
		player_list_ui.refresh_players(Network.players, multiplayer.get_unique_id())


func register_player_nickname_height(player_id: int, height: float) -> void:
	if not multiplayer.is_server() or player_id <= 0:
		return
	var normalized_height := _normalize_nickname_height(height)
	_store_and_apply_player_nickname_height(player_id, normalized_height)
	sync_player_nickname_height.rpc(player_id, normalized_height)


@rpc("authority", "reliable")
func sync_player_nickname_height(player_id: int, height: float) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return
	_store_and_apply_player_nickname_height(player_id, _normalize_nickname_height(height))


func _request_nickname_heights() -> void:
	if multiplayer.is_server() or not multiplayer.has_multiplayer_peer():
		return
	request_nickname_heights.rpc_id(1)


@rpc("any_peer", "reliable")
func request_nickname_heights() -> void:
	if not multiplayer.is_server():
		return
	var requester_id := multiplayer.get_remote_sender_id()
	if requester_id <= 0 or _nickname_height_requesters.has(requester_id):
		return
	_nickname_height_requesters[requester_id] = true
	_sync_nickname_heights_to_peer(requester_id)


func _sync_nickname_heights_to_peer(peer_id: int) -> void:
	if not multiplayer.is_server() or peer_id <= 0:
		return
	for child in players_container.get_children():
		var player := child as Character
		if not player:
			continue
		var player_id := str(player.name).to_int()
		var height := float(_player_nickname_heights.get(player_id, player.get_current_nickname_height()))
		sync_player_nickname_height.rpc_id(peer_id, player_id, _normalize_nickname_height(height))


func _store_and_apply_player_nickname_height(player_id: int, height: float) -> void:
	if player_id <= 0:
		return
	_player_nickname_heights[player_id] = height
	_apply_player_nickname_height(player_id)


func _apply_player_nickname_height(player_id: int) -> void:
	if not _player_nickname_heights.has(player_id):
		return
	var player := players_container.get_node_or_null(str(player_id)) as Character
	if player:
		player.apply_synced_nickname_height(float(_player_nickname_heights[player_id]))


func _normalize_nickname_height(height: float) -> float:
	if is_nan(height) or is_inf(height):
		return MIN_NICKNAME_HEIGHT
	return clampf(height, MIN_NICKNAME_HEIGHT, MAX_NICKNAME_HEIGHT)


func _on_inventory_closed():
	inventory_visible = false
	_update_mouse_mode()


func is_gameplay_input_blocked() -> bool:
	return pause_menu.is_menu_visible()


func is_camera_input_blocked() -> bool:
	return is_gameplay_input_blocked() or inventory_visible or multiplayer_chat.is_chat_visible()


func _handle_pause_action() -> void:
	if inventory_visible:
		_close_inventory()
		return
	if multiplayer_chat.is_chat_visible():
		_close_chat()
		return
	if pause_menu.is_menu_visible():
		_hide_pause_menu()
		return
	if main_menu.is_menu_visible() or not multiplayer.has_multiplayer_peer():
		return
	_show_pause_menu()


func _show_pause_menu() -> void:
	pause_menu.show_menu()
	_update_mouse_mode()


func _hide_pause_menu(restore_mouse_mode: bool = true) -> void:
	if not pause_menu.is_menu_visible():
		return
	pause_menu.hide_menu()
	if restore_mouse_mode:
		_update_mouse_mode()


func _close_chat() -> void:
	multiplayer_chat.close_chat()
	chat_visible = false
	_update_mouse_mode()


func _close_inventory() -> void:
	inventory_ui.close_inventory()
	inventory_visible = false
	_update_mouse_mode()


func _update_mouse_mode() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var ui_requires_cursor := (
		main_menu.is_menu_visible()
		or pause_menu.is_menu_visible()
		or inventory_visible
		or not multiplayer.has_multiplayer_peer()
	)
	if ui_requires_cursor:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _on_pause_resume_pressed() -> void:
	_hide_pause_menu()


func _on_pause_main_menu_pressed() -> void:
	_hide_pause_menu(false)
	Network.leave_game()
	if not main_menu.is_menu_visible():
		_reset_session_ui()


func _on_pause_quit_pressed() -> void:
	Network.leave_game()
	get_tree().quit()


func update_local_inventory_display():
	if inventory_ui:
		inventory_ui.refresh_display()


func _get_local_player() -> Character:
	var local_player_id = multiplayer.get_unique_id()
	if players_container.has_node(str(local_player_id)):
		return players_container.get_node(str(local_player_id)) as Character
	return null


func _debug_add_item():
	if not OS.is_debug_build() or not multiplayer.is_server():
		return
	var local_player = _get_local_player()
	if local_player:
		var test_items: Array[String] = []
		for item_id in ItemDatabase.get_all_items():
			test_items.append(str(item_id))
		if test_items.is_empty():
			return
		var random_item = test_items[randi() % test_items.size()]
		local_player.request_add_item.rpc_id(1, random_item, 1)


func _debug_print_inventory():
	var local_player = _get_local_player()
	if local_player and local_player.get_inventory():
		var inventory = local_player.get_inventory()
		print("=== Inventory Debug ===")
		for i in range(inventory.slots.size()):
			var slot = inventory.get_slot(i)
			if slot and not slot.is_empty():
				print("Slot ", i, ": ", slot.item_id, " x", slot.quantity)
		print("=====================")
	else:
		print("No inventory found for local player")
