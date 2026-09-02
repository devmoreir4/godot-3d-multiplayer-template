extends Node

const FEDORA_ICON: Texture2D = preload("res://assets/items/hats/icons/fedora.png")
const HEADPHONES_ICON: Texture2D = preload("res://assets/items/hats/icons/headphones.png")
const PIRATE_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/pirate_hat.png")
const SHERIFF_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/sheriff_hat.png")
const SOMBRERO_ICON: Texture2D = preload("res://assets/items/hats/icons/sombrero.png")
const WIZARD_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/wizard_hat.png")
const BACKPACK_ICON: Texture2D = preload("res://assets/items/backpacks/icons/backpack.png")
const SWORD_ICON: Texture2D = preload("res://assets/items/weapons/icons/sword.png")
const SWORD_BIG_ICON: Texture2D = preload("res://assets/items/weapons/icons/sword_big.png")
const AXE_ICON: Texture2D = preload("res://assets/items/weapons/icons/axe.png")
const CHICKEN_LEG_ICON: Texture2D = preload("res://assets/items/misc/icons/chicken_leg.png")
const BONE_ICON: Texture2D = preload("res://assets/items/misc/icons/bone.png")
const CHALICE_ICON: Texture2D = preload("res://assets/items/misc/icons/chalice.png")

var items: Dictionary = {}


func _ready():
	_create_sample_items()


func get_item(item_id: String) -> Item:
	return items.get(item_id)


func get_all_items() -> Dictionary:
	return items


func _create_sample_items():
	_create_hat_item("fedora", "Fedora", "A timeless felt fedora.", "res://scenes/items/hats/fedora.tscn", FEDORA_ICON)
	_create_hat_item(
		"headphones",
		"Headphones",
		"Comfortable over-ear headphones.",
		"res://scenes/items/hats/headphones.tscn",
		HEADPHONES_ICON
	)
	_create_hat_item(
		"pirate_hat",
		"Pirate Hat",
		"A weathered hat for a daring pirate.",
		"res://scenes/items/hats/pirate_hat.tscn",
		PIRATE_HAT_ICON
	)
	_create_hat_item(
		"sheriff_hat",
		"Sheriff Hat",
		"A frontier hat with a sheriff badge.",
		"res://scenes/items/hats/sheriff_hat.tscn",
		SHERIFF_HAT_ICON
	)
	_create_hat_item(
		"sombrero", "Sombrero", "A broad and colorful sombrero.", "res://scenes/items/hats/sombrero.tscn", SOMBRERO_ICON
	)
	_create_hat_item(
		"wizard_hat",
		"Wizard Hat",
		"A pointed hat filled with arcane style.",
		"res://scenes/items/hats/wizard_hat.tscn",
		WIZARD_HAT_ICON
	)
	_create_item(
		"backpack",
		"Backpack",
		"A sturdy backpack worn on the back.",
		Item.ItemType.BACKPACK,
		"res://scenes/items/backpacks/backpack.tscn",
		BACKPACK_ICON,
		true,
		60
	)
	_create_item(
		"sword",
		"Sword",
		"A balanced hand sword.",
		Item.ItemType.WEAPON,
		"res://scenes/items/weapons/sword.tscn",
		SWORD_ICON,
		true,
		80
	)
	_create_item(
		"sword_big",
		"Big Sword",
		"A large two-handed sword.",
		Item.ItemType.WEAPON,
		"res://scenes/items/weapons/sword_big.tscn",
		SWORD_BIG_ICON,
		true,
		120
	)
	_create_item(
		"axe",
		"Small Axe",
		"A compact axe with a sharp steel head.",
		Item.ItemType.WEAPON,
		"res://scenes/items/weapons/axe.tscn",
		AXE_ICON,
		true,
		95
	)
	_create_item(
		"chicken_leg",
		"Chicken Leg",
		"A cooked chicken leg.",
		Item.ItemType.MISC,
		"res://scenes/items/misc/chicken_leg.tscn",
		CHICKEN_LEG_ICON,
		false,
		5
	)
	_create_item(
		"bone",
		"Bone",
		"A weathered bone.",
		Item.ItemType.MISC,
		"res://scenes/items/misc/bone.tscn",
		BONE_ICON,
		false,
		2
	)
	_create_item(
		"chalice",
		"Chalice",
		"A decorative golden chalice.",
		Item.ItemType.MISC,
		"res://scenes/items/misc/chalice.tscn",
		CHALICE_ICON,
		false,
		35
	)


func _create_item(
	item_id: String,
	item_name: String,
	item_description: String,
	item_type: Item.ItemType,
	scene_path: String,
	item_icon: Texture2D,
	equipable: bool,
	item_value: int
) -> void:
	var item := Item.new()
	item.id = item_id
	item.name = item_name
	item.description = item_description
	item.item_type = item_type
	item.rarity = Item.ItemRarity.COMMON
	item.stackable = not equipable
	item.max_stack = 99 if item.stackable else 1
	item.value = item_value
	item.icon = item_icon
	item.scene_path = scene_path
	if equipable:
		item.context_options.append(Item.ContextOptions.EQUIP)
	item.context_options.append(Item.ContextOptions.DROP)
	items[item.id] = item


func _create_hat_item(
	item_id: String, item_name: String, item_description: String, scene_path: String, item_icon: Texture2D
) -> void:
	var hat := Item.new()
	hat.id = item_id
	hat.name = item_name
	hat.description = item_description
	hat.item_type = Item.ItemType.HAT
	hat.rarity = Item.ItemRarity.COMMON
	hat.stackable = false
	hat.value = 25
	hat.icon = item_icon
	hat.scene_path = scene_path
	hat.context_options.append(Item.ContextOptions.EQUIP)
	hat.context_options.append(Item.ContextOptions.DROP)
	items[hat.id] = hat
