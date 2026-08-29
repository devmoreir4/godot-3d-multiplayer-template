extends Node

const BUCKET_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/bucket_hat.png")
const COWBOY_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/cowboy_hat.png")
const WITCH_HAT_ICON: Texture2D = preload("res://assets/items/hats/icons/witch_hat.png")
const ARMOR_GOLDEN_ICON: Texture2D = preload("res://assets/items/armor/icons/armor_golden.png")
const ARMOR_METAL_ICON: Texture2D = preload("res://assets/items/armor/icons/armor_metal.png")
const SWORD_ICON: Texture2D = preload("res://assets/items/weapons/icons/sword.png")
const SWORD_BIG_ICON: Texture2D = preload("res://assets/items/weapons/icons/sword_big.png")
const CHICKEN_LEG_ICON: Texture2D = preload("res://assets/items/misc/icons/chicken_leg.png")

var items: Dictionary = {}

func _ready():
	_load_items()

func get_item(item_id: String) -> Item:
	return items.get(item_id)

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func get_all_items() -> Dictionary:
	return items

func _load_items():
	_create_sample_items()

func _create_sample_items():
	_create_hat_item("bucket_hat", "Bucket Hat", "A casual bucket hat.", "res://scenes/items/hats/bucket_hat.tscn", BUCKET_HAT_ICON)
	_create_hat_item("cowboy_hat", "Cowboy Hat", "A wide-brimmed cowboy hat.", "res://scenes/items/hats/cowboy_hat.tscn", COWBOY_HAT_ICON)
	_create_hat_item("witch_hat", "Witch Hat", "A pointed witch hat.", "res://scenes/items/hats/witch_hat.tscn", WITCH_HAT_ICON)
	_create_item("armor_golden", "Golden Armor", "A polished golden armor.", Item.ItemType.ARMOR, "res://scenes/items/armor/armor_golden.tscn", ARMOR_GOLDEN_ICON, true, 150)
	_create_item("armor_metal", "Metal Armor", "A sturdy metal armor.", Item.ItemType.ARMOR, "res://scenes/items/armor/armor_metal.tscn", ARMOR_METAL_ICON, true, 100)
	_create_item("sword", "Sword", "A balanced hand sword.", Item.ItemType.WEAPON, "res://scenes/items/weapons/sword.tscn", SWORD_ICON, true, 80)
	_create_item("sword_big", "Big Sword", "A large two-handed sword.", Item.ItemType.WEAPON, "res://scenes/items/weapons/sword_big.tscn", SWORD_BIG_ICON, true, 120)
	_create_item("chicken_leg", "Chicken Leg", "A cooked chicken leg.", Item.ItemType.MISC, "res://scenes/items/misc/chicken_leg.tscn", CHICKEN_LEG_ICON, false, 5)

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
