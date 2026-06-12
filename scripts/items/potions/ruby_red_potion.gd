extends BaseRigidBody3D
class_name RubyRedPotion3D

var item_id = "health_potion"
static var current_player: Character

static func drink() -> bool:
	if not current_player or not current_player.get_inventory():
		return false
	return true
