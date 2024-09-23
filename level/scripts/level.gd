extends Node3D

@onready var nick_input: LineEdit = $Menu/MainContainer/MainMenu/Option1/NickInput
@onready var address_input = $Menu/MainContainer/MainMenu/Option3/AddressInput
@onready var players_container = $PlayersContainer
@onready var menu = $Menu
@export var player_scene : PackedScene

func _ready():
	if not multiplayer.is_server():
		return
		
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)

func _on_host_pressed():
	menu.hide()
	Network.start_host()

func _on_client_pressed():
	menu.hide()
	Network.join_game(address_input.text, nick_input.text)
	
func _add_player(id: int):
	if not multiplayer.is_server() or id == 1:
		return
		
	if players_container.has_node(str(id)):
		return
		
	print("-------------- ADDING ------------------")
	print("Player id: ", id)
	print(Network.players)
	print("---------------------------------------")

	var player = player_scene.instantiate()
	player.name = str(id)
	player.position = get_spawn_point()
	players_container.add_child(player, true)
	
	if multiplayer.is_server():
		rpc("sync_player_position", id, player.position)
		
func get_spawn_point():
	var spawn_point = Vector2.from_angle(randf() * 2 * PI) * 10 # SPAWN_RADIUS
	return Vector3(spawn_point.x, 0, spawn_point.y)
	
func _remove_player(id):
	if not multiplayer.is_server():
		return
	
	if not players_container.has_node(str(id)):
		return
		
	var player_node = players_container.get_node(str(id))
	if player_node:
		player_node.queue_free()
	
@rpc("any_peer", "call_local")
func sync_player_position(id: int, new_position: Vector3):
	var player = players_container.get_node(str(id))
	if player:
		player.position = new_position
		
