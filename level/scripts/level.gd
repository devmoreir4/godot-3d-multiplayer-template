extends Node3D

const SPAWN_RADIUS := 10.0
const PORT = 1027
const IP_DEFAULT = "127.0.0.1"

@export var player_scene : PackedScene

var peer = ENetMultiplayerPeer.new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		exit_game()
		
func _on_host_pressed():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	$Menu.hide()
	add_player(multiplayer.get_unique_id()) #add server as first player

func _on_client_pressed():
	peer.create_client(IP_DEFAULT, PORT)
	multiplayer.multiplayer_peer = peer
	$Menu.hide()

func add_player(id: int):
	var player = player_scene.instantiate()
	var pos := Vector2.from_angle(randf() * 2 * PI) * SPAWN_RADIUS
	player.position = Vector3(pos.x, 0, pos.y)
	player.name = str(id)
	add_child(player)
	#player.add_to_group("players")

	if multiplayer.is_server():
		rpc("sync_player_position", id, player.position)

@rpc("any_peer", "call_local")
func sync_player_position(id: int, new_position: Vector3):
	var player = get_node(str(id))
	if player:
		player.position = new_position

func remove_player(id: int):
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
	
func exit_game():
	if multiplayer.is_server():
		print("Server is shutting down.")
		rpc("remove_all_players")
	else:
		remove_player(multiplayer.get_unique_id())

	#multiplayer.multiplayer_peer = null
	get_tree().quit()
	
#@rpc("any_peer", "call_local")
#func remove_all_players():
	#for player in get_tree().get_nodes_in_group("players"):
		#player.queue_free()
		
@rpc("any_peer", "call_local")
func remove_all_players():
	for player in get_children():
		if player.name.is_valid_int():
			player.queue_free()
			
