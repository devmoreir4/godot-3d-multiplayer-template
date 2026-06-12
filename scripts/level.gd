extends Node3D

@onready var players_container: Node3D = $PlayersContainer
@onready var main_menu: MainMenuUI = $MainMenuUI
@export var player_scene: PackedScene

@onready var multiplayer_chat: MultiplayerChatUI = $MultiplayerChatUI
@onready var inventory_ui: InventoryUI = $InventoryUI
@onready var health_bar: HealthBar = $HealthBar

var chat_visible = false
var inventory_visible = false

const MAX_CHAT_MESSAGE_LENGTH := 160

func _ready():
	
	after_ready()
	
	if DisplayServer.get_name() == "headless":
		Network.start_host("", "")
		spawn_loot()

	multiplayer_chat.hide()
	main_menu.show_menu()
	health_bar.hide()
	multiplayer_chat.set_process_input(true)

	main_menu.host_pressed.connect(_on_host_pressed)
	main_menu.join_pressed.connect(_on_join_pressed)
	main_menu.quit_pressed.connect(_on_quit_pressed)

	if inventory_ui:
		inventory_ui.inventory_closed.connect(_on_inventory_closed)

	if multiplayer_chat:
		multiplayer_chat.message_sent.connect(_on_chat_message_sent)

	Network.server_disconnected.connect(_on_server_disconnected)
	Network.connect("player_connected", Callable(self, "_on_player_connected"))
	multiplayer.peer_disconnected.connect(_remove_player)
	
func after_ready():
	var ip_address :String
	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			ip_address =  IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),IP.TYPE_IPV4)
	elif OS.has_feature("x11"):
		if OS.has_environment("HOSTNAME"):
			ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),IP.TYPE_IPV4)
	elif OS.has_feature("OSX"):
		if OS.has_environment("HOSTNAME"):
			ip_address =  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),IP.TYPE_IPV4)
	get_node("/root/Level/MainMenuUI/MainContainer/MainMenu/Option3/AddressInput").text = ip_address


func spawn_loot():
	if multiplayer.is_server():
		var lootRoot = get_node("Environment/ItemContainer")
		
		var magic_gem = load("res://scenes/items/gems/magic_gem.tscn")
		var loot_item = magic_gem.instantiate()
		loot_item.position = Vector3( -17.43, 0.025, 5.114 )
		lootRoot.add_child(loot_item, true)
		
		loot_item = magic_gem.instantiate()
		loot_item.position = Vector3( 0, 1.276, 17.786 )
		lootRoot.add_child(loot_item, true)
		
		loot_item = magic_gem.instantiate()
		loot_item.position = Vector3( 12.454, 0, 0 )
		lootRoot.add_child(loot_item, true)
		
		loot_item = magic_gem.instantiate()
		loot_item.position = Vector3( 0, 0, -6.283 )
		lootRoot.add_child(loot_item, true)
	
		var pickaxe = load("res://scenes/items/weapons/pickaxe.tscn")
		loot_item = pickaxe.instantiate()
		loot_item.position = Vector3( 1.2, 7.6, 4.7 )
		lootRoot.add_child(loot_item, true)
		
func _on_server_disconnected():
	for child in players_container.get_children():
		child.queue_free()
	
	chat_visible = false
	inventory_visible = false
	multiplayer_chat.hide()
	if inventory_ui:
		inventory_ui.close_inventory()
		inventory_ui.current_player = null
	health_bar.hide()
	
	main_menu.show_menu()

func _on_player_connected(peer_id, player_info):
	var player = _add_player(peer_id, player_info)
	if multiplayer.is_server() and player:
		player.call_deferred("_sync_inventory_to_owner")

func _on_host_pressed(nickname: String, skin: String):
	var error = Network.start_host(nickname, skin)
	if error:
		push_warning("Failed to host game. Error: " + str(error))
		main_menu.show_menu()
		return
	main_menu.hide_menu()
	spawn_loot()


func _on_join_pressed(nickname: String, skin: String, address: String):
	var error = Network.join_game(nickname, skin, address)
	if error:
		push_warning("Failed to join game. Error: " + str(error))
		main_menu.show_menu()
		return
	main_menu.hide_menu()

func _add_player(id: int, player_info : Dictionary) -> Character:
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
	return player

func get_spawn_point(id: int) -> Vector3:
	var spawn_angle := fmod(float(id) * 2.399963229728653, 2.0 * PI)
	var spawn_point := Vector2.from_angle(spawn_angle) * 10
	return Vector3(spawn_point.x, 0, spawn_point.y)

func _remove_player(id):
	if not players_container.has_node(str(id)):
		return
	var player_node = players_container.get_node(str(id))
	if player_node:
		player_node.queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()

func toggle_chat():
	if main_menu.is_menu_visible():
		return

	multiplayer_chat.toggle_chat()
	chat_visible = multiplayer_chat.is_chat_visible()

func is_chat_visible() -> bool:
	return multiplayer_chat.is_chat_visible()

func _input(event):
	if event.is_action_pressed("toggle_chat"):
		toggle_chat()
	elif chat_visible and multiplayer_chat.message.has_focus():
		if event is InputEventKey and event.keycode == KEY_ENTER and event.pressed:
			multiplayer_chat._on_send_pressed()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		toggle_inventory()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F1:
		_debug_add_item()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		_debug_print_inventory()

func _on_chat_message_sent(message_text: String) -> void:
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
	if main_menu.is_menu_visible():
		return

	var local_player = _get_local_player()
	if not local_player:
		return

	inventory_visible = !inventory_visible
	if inventory_visible:
		inventory_ui.open_inventory(local_player)
	else:
		inventory_ui.close_inventory()

func is_inventory_visible() -> bool:
	return inventory_visible

func _on_inventory_closed():
	inventory_visible = false

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
		var test_items = ["iron_sword", "health_potion", "viking_helmet", "magic_gem", "iron_pickaxe", "apple"]
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
