extends Area3D

func _on_body_entered(body: Node3D) -> void:
	var local_player = Network.getPlayer()
	if not local_player or not local_player.is_multiplayer_authority():
		return
	if body is Character and body != local_player:
		local_player.request_attack_hit.rpc_id(1, body.get_path(), "iron_pickaxe")
