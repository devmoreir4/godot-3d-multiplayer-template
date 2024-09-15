extends Node3D

const SPAWN_RADIUS := 10.0
const PORT = 1027
const IP_DEFAULT = "127.0.0.1"

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func _on_host_pressed():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	$Menu.hide()

func _on_client_pressed():
	peer.create_client(IP_DEFAULT, PORT)
	multiplayer.multiplayer_peer = peer
	#multiplayer.peer_connected.connect(add_player)
	$Menu.hide()

func add_player(id: int):
	if multiplayer.is_server():
		rpc("create_player", id)
		create_player(id)

@rpc("any_peer", "call_local")
func create_player(id: int):
	var player = player_scene.instantiate()
	var pos := Vector2.from_angle(randf() * 2 * PI) * SPAWN_RADIUS
	player.position = Vector3(pos.x, 0, pos.y)
	player.name = str(id)
	add_child(player)

	if multiplayer.is_server():
		rpc("sync_player_position", id, player.position)

@rpc("any_peer", "call_local")
func sync_player_position(id: int, new_position: Vector3):
	var player = get_node(str(id))
	if player:
		player.position = new_position

func exit_game(id: int):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)
	get_tree().quit()

func del_player(id: int):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id: int):
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
