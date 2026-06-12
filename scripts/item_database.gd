extends Node

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
	var placeholder_icon = load("res://icon.png")

	var iron_sword = Item.new()
	iron_sword.id = "iron_sword"
	iron_sword.name = "Iron Sword"
	iron_sword.description = "A sturdy iron sword. Good for combat."
	iron_sword.item_type = Item.ItemType.WEAPON
	iron_sword.rarity = Item.ItemRarity.COMMON
	iron_sword.stackable = false
	iron_sword.value = 50
	iron_sword.icon = placeholder_icon
	iron_sword.set_context_options([Item.ContextOptions.THROW,Item.ContextOptions.EQUIP,Item.ContextOptions.DROP])
	iron_sword.set_context_callable({Item.ContextOptions.THROW:Item.throw,
									 Item.ContextOptions.EQUIP:Item.equip,
									 Item.ContextOptions.DROP:Item.static_drop})
	iron_sword.scene_path = "res://scenes/items/weapons/sword.tscn"
	items[iron_sword.id] = iron_sword

	var health_potion = Item.new()
	health_potion.id = "health_potion"
	health_potion.name = "Health Potion"
	health_potion.description = "Restores health when consumed."
	health_potion.item_type = Item.ItemType.CONSUMABLE
	health_potion.rarity = Item.ItemRarity.COMMON
	health_potion.stackable = true
	health_potion.max_stack = 10
	health_potion.value = 25
	health_potion.icon = placeholder_icon
	health_potion.scene_path = "res://scenes/items/potions/ruby_red_potion.tscn"
	health_potion.set_context_options([Item.ContextOptions.THROW,Item.ContextOptions.DRINK,Item.ContextOptions.DROP])
	health_potion.set_context_callable({Item.ContextOptions.THROW:Item.throw,
									 Item.ContextOptions.DRINK:RubyRedPotion3D.drink,
									 Item.ContextOptions.DROP:Item.static_drop})	
	items[health_potion.id] = health_potion

	var viking_helmet = Item.new()
	viking_helmet.id = "viking_helmet"
	viking_helmet.name = "Viking Helmet"
	viking_helmet.description = "A horned helmet that protects the head."
	viking_helmet.item_type = Item.ItemType.ARMOR
	viking_helmet.rarity = Item.ItemRarity.UNCOMMON
	viking_helmet.stackable = false
	viking_helmet.value = 75
	viking_helmet.icon = placeholder_icon
	viking_helmet.scene_path = "res://scenes/items/armors/viking_helmet.tscn"
	viking_helmet.set_context_options([Item.ContextOptions.EQUIP, Item.ContextOptions.DROP])
	viking_helmet.set_context_callable({Item.ContextOptions.EQUIP:Item.equip,
									 	Item.ContextOptions.DROP:Item.static_drop})	
	items[viking_helmet.id] = viking_helmet

	var magic_gem = Item.new()
	magic_gem.id = "magic_gem"
	magic_gem.name = "Magic Gem"
	magic_gem.description = "A mysterious gem that glows with inner light."
	magic_gem.item_type = Item.ItemType.MISC
	magic_gem.rarity = Item.ItemRarity.RARE
	magic_gem.stackable = true
	magic_gem.max_stack = 5
	magic_gem.value = 200
	magic_gem.icon = placeholder_icon
	magic_gem.scene_path = "res://scenes/items/gems/magic_gem.tscn"
	magic_gem.set_context_options([Item.ContextOptions.THROW,Item.ContextOptions.DROP])
	magic_gem.set_context_callable({Item.ContextOptions.THROW:Item.throw,
									 	Item.ContextOptions.DROP:Item.static_drop})	
	items[magic_gem.id] = magic_gem

	var pickaxe = Item.new()
	pickaxe.id = "iron_pickaxe"
	pickaxe.name = "Iron Pickaxe"
	pickaxe.description = "A mining tool for gathering resources."
	pickaxe.item_type = Item.ItemType.WEAPON
	pickaxe.rarity = Item.ItemRarity.COMMON
	pickaxe.stackable = false
	pickaxe.value = 100
	pickaxe.icon = placeholder_icon
	pickaxe.scene_path = "res://scenes/items/weapons/pickaxe.tscn"
	pickaxe.set_context_options([Item.ContextOptions.THROW,Item.ContextOptions.EQUIP,Item.ContextOptions.DROP])
	pickaxe.set_context_callable({Item.ContextOptions.THROW:Item.throw,
								Item.ContextOptions.EQUIP:Item.equip,
								Item.ContextOptions.DROP:Item.static_drop})	
	items[pickaxe.id] = pickaxe

	var apple = Item.new()
	apple.id = "apple"
	apple.name = "Apple"
	apple.description = "A fresh apple. Restores a little energy."
	apple.item_type = Item.ItemType.CONSUMABLE
	apple.rarity = Item.ItemRarity.COMMON
	apple.stackable = true
	apple.max_stack = 10
	apple.value = 5
	apple.icon = placeholder_icon
	apple.scene_path = "res://scenes/items/food/apple.tscn"
	apple.set_context_options([Item.ContextOptions.EAT,Item.ContextOptions.THROW,Item.ContextOptions.DROP])
	apple.set_context_callable({Item.ContextOptions.EAT:AppleRigidBody3D.eat,
								Item.ContextOptions.THROW:Item.throw,
								Item.ContextOptions.DROP:Item.static_drop})
	items[apple.id] = apple

func add_item_to_database(item: Item) -> bool:
	if item.id.is_empty():
		push_error("Cannot add item with empty ID to database")
		return false

	if items.has(item.id):
		push_warning("Item with ID '" + item.id + "' already exists in database. Overwriting.")

	items[item.id] = item
	return true

func remove_item_from_database(item_id: String) -> bool:
	if items.has(item_id):
		items.erase(item_id)
		return true
	return false
