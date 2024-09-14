extends Node3D

const SPAWN_RANDOM := 10.0
const PORT = 1027
const IP_DEFAULT = "127.0.0.1"

var peer = ENetMultiplayerPeer.new()
@export var player_scene : PackedScene

func _on_host_pressed():
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$Menu.hide()

func _on_client_pressed():
	peer.create_client(IP_DEFAULT, PORT)
	multiplayer.multiplayer_peer = peer
	$Menu.hide()

func add_player(id = 1):
	var player = player_scene.instantiate()
	var pos := Vector2.from_angle(randf() * 2 * PI)
	player.position = Vector3(pos.x * SPAWN_RANDOM * randf(), 0, pos.y * SPAWN_RANDOM * randf())
	player.name = str(id)
	call_deferred("add_child", player)
	#rpc_id(id, "_set_player_position", player.position)

func exit_game(id):
	multiplayer.peer_disconnected.connect(del_player)
	del_player(id)

func del_player(id):
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id):
	var player = get_node(str(id))
	if player:
		player.queue_free()

#@rpc("any_peer", "call_local")
#func _set_player_position(id, position):
	#var player = get_node(str(id))
	#if player:
		#player.position = position
