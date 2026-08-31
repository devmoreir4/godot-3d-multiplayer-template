extends Node

const BUCKET_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/bucket_hat.png")
const COWBOY_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/cowboy_hat.png")
const WITCH_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/witch_hat.png")
const BEANIE_ICON: Texture2D = preload("res://assets/items/hats/icons/beanie.png")
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
	_create_hat_item("bucket_hat", "Bucket Hat", "A casual bucket hat.", "res://scenes/items/hats/bucket_hat.tscn", BUCKET_HAT_ICON)
	_create_hat_item("cowboy_hat", "Cowboy Hat", "A wide-brimmed cowboy hat.", "res://scenes/items/hats/cowboy_hat.tscn", COWBOY_HAT_ICON)
	_create_hat_item("witch_hat", "Witch Hat", "A pointed witch hat.", "res://scenes/items/hats/witch_hat.tscn", WITCH_HAT_ICON)
	_create_hat_item("beanie", "Beanie", "A warm knitted beanie.", "res://scenes/items/hats/beanie.tscn", BEANIE_ICON)
	_create_item("backpack", "Backpack", "A sturdy backpack worn on the back.", Item.ItemType.BACKPACK, "res://scenes/items/backpacks/backpack.tscn", BACKPACK_ICON, true, 60)
	_create_item("sword", "Sword", "A balanced hand sword.", Item.ItemType.WEAPON, "res://scenes/items/weapons/sword.tscn", SWORD_ICON, true, 80)
	_create_item("sword_big", "Big Sword", "A large two-handed sword.", Item.ItemType.WEAPON, "res://scenes/items/weapons/sword_big.tscn", SWORD_BIG_ICON, true, 120)
	_create_item("axe", "Small Axe", "A compact axe with a sharp steel head.", Item.ItemType.WEAPON, "res://scenes/items/weapons/axe.tscn", AXE_ICON, true, 95)
	_create_item("chicken_leg", "Chicken Leg", "A cooked chicken leg.", Item.ItemType.MISC, "res://scenes/items/misc/chicken_leg.tscn", CHICKEN_LEG_ICON, false, 5)
	_create_item("bone", "Bone", "A weathered bone.", Item.ItemType.MISC, "res://scenes/items/misc/bone.tscn", BONE_ICON, false, 2)
	_create_item("chalice", "Chalice", "A decorative golden chalice.", Item.ItemType.MISC, "res://scenes/items/misc/chalice.tscn", CHALICE_ICON, false, 35)

func _create_item(item_id: String, item_name: String, item_description: String, item_type: Item.ItemType, scene_path: String, item_icon: Texture2D, equipable: bool, item_value: int) -> void:
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

func _create_hat_item(item_id: String, item_name: String, item_description: String, scene_path: String, item_icon: Texture2D) -> void:
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
