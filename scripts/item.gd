class_name Item
extends Resource

@export var id: String = ""
@export var name: String = ""
@export var description: String = ""
@export var description_identified: String = ""
@export var icon: Texture2D

@export var identified: bool = false
@export var blessed: Blessed = Blessed.NORMAL
@export var stackable: bool = true
@export var max_stack: int = 99

@export var item_type: ItemType = ItemType.MISC
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var value: int = 0
@export var context_options: Array[Item.ContextOptions] = []
@export var context_callable: Dictionary

@export var scene_path: String = ""

enum Blessed { 
	CURSED,
	NORMAL,
	BLESSED
}
enum ItemType {
	WEAPON,
	ARMOR,
	CONSUMABLE,
	TOOL,
	MISC
}

enum ItemRarity {
	COMMON,
	UNCOMMON, 
	RARE,
	EPIC,
	LEGENDARY
}

enum ContextOptions { 
	DRINK,
	EAT, 
	DROP,
	EQUIP,
	THROW,
	READ,
	EXAMINE,
	UNEQUIP,
}

func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"description_identified": description_identified, 
		"stackable": stackable,
		"max_stack": max_stack,
		"item_type": item_type,
		"rarity": rarity,
		"value": value,
		"context_options": context_options,
		"context_callable": context_callable,
		"scene_path": scene_path
	}

func from_dict(data: Dictionary) -> void:
	id = data.get("id", "")
	name = data.get("name", "")
	description = data.get("description", "")
	description_identified = data.get("description_identified", "")
	stackable = data.get("stackable", true)
	max_stack = data.get("max_stack", 99)
	item_type = data.get("item_type", ItemType.MISC)
	rarity = data.get("rarity", ItemRarity.COMMON)
	value = data.get("value", 0)
	context_options = data.get("context_options", [ContextOptions.EXAMINE,ContextOptions.DROP])
	context_callable = data.get("context_callable", {ContextOptions.EXAMINE:examine, ContextOptions.DROP:drop})
	scene_path = data.get("scene_path", "")
	
 
func can_stack_with(other_item: Item) -> bool:
	return stackable && other_item.stackable && id == other_item.id

static func examine():
	pass
	
static func drop():
	pass

static func equip():
	pass

static func throw():
	pass

static func read():
	pass
	
static func drink() -> bool:
	return false
	
static func static_drop():
	pass
		
func set_context_options( val : Array[Item.ContextOptions]):
	context_options = val
	
func set_context_callable( val : Dictionary):
	context_callable = val
