extends Node3D

const SPAWN_RADIUS : float = 10.0
const MAX_PLAYERS : int = 10
const PORT : int = 1027
const IP_DEFAULT : String = "127.0.0.1"

@onready var menu = $Menu
@export var player_scene : PackedScene

var peer = ENetMultiplayerPeer.new()

func _unhandled_input(_event):
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
		
func _on_host_pressed():
	menu.hide()
	peer.create_server(PORT, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(multiplayer.get_unique_id())

func _on_client_pressed():
	menu.hide()
	peer.create_client(IP_DEFAULT, PORT)
	multiplayer.multiplayer_peer = peer

func add_player(id: int):
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

func remove_player(id: int):
	var player = get_node_or_null(str(id))
	if player:
		player.queue_free()
