extends Control
class_name InventoryUI

@onready var grid_container: GridContainer = $Panel/MarginContainer/VBoxContainer/GridContainer
@onready var title_label: Label = $Panel/MarginContainer/VBoxContainer/TitleBar/Title
@onready var close_button: Button = $Panel/MarginContainer/VBoxContainer/TitleBar/CloseButton
@onready var tooltip: Control = $ItemTooltip
@onready var tooltip_label: RichTextLabel = $ItemTooltip/Panel/MarginContainer/TooltipText
@onready var menubar: MenuBar = $MenuBar

const SLOT_INDEX_WEAPON := -1
const SLOT_INDEX_ARMOR := -2

var current_player: Character
var slot_ui_scene: PackedScene
var slot_uis: Array[InventorySlotUI] = []
var current_item : Item
var current_slot_index : int
var armor_slot_ui : InventorySlotUI
var weapon_slot_ui : InventorySlotUI


signal inventory_closed

func _ready():
	slot_ui_scene = preload("res://scenes/ui/inventory_slot_ui.tscn")
	grid_container.columns = 4
	close_button.pressed.connect(_on_close_pressed)
	tooltip.visible = false
	_create_slot_uis()
	_create_armor_slot_ui()
	_create_weapon_slot_ui()

func _create_armor_slot_ui():
	armor_slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
	armor_slot_ui.custom_minimum_size = Vector2(64, 64)
	armor_slot_ui.parent_inventory = self
	armor_slot_ui.slot_type = armor_slot_ui.TYPE.ARMOR
	armor_slot_ui.slot_clicked.connect(_on_slot_clicked)
	armor_slot_ui.item_hovered.connect(_on_item_hovered)
	armor_slot_ui.item_unhovered.connect(_on_item_unhovered)
	get_node( "Armor/MarginContainer/VBoxContainer" ).add_child( armor_slot_ui )
	
func _create_weapon_slot_ui():
	weapon_slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
	weapon_slot_ui.custom_minimum_size = Vector2(64, 64)
	weapon_slot_ui.parent_inventory = self
	weapon_slot_ui.slot_type = InventorySlotUI.TYPE.WEAPON
	weapon_slot_ui.slot_clicked.connect(_on_slot_clicked)
	weapon_slot_ui.item_hovered.connect(_on_item_hovered)
	weapon_slot_ui.item_unhovered.connect(_on_item_unhovered)
	get_node( "Weapon/MarginContainer/VBoxContainer" ).add_child( weapon_slot_ui )

func _create_slot_uis():
	for child in grid_container.get_children():
		child.queue_free()
	slot_uis.clear()

	for i in range(PlayerInventory.INVENTORY_SIZE):
		var slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
		slot_ui.custom_minimum_size = Vector2(64, 64)
		slot_ui.parent_inventory = self

		slot_ui.slot_clicked.connect(_on_slot_clicked)
		slot_ui.item_hovered.connect(_on_item_hovered)
		slot_ui.item_unhovered.connect(_on_item_unhovered)

		slot_ui.set_slot_data(null, i)

		grid_container.add_child(slot_ui)
		slot_uis.append(slot_ui)

func update_inventory_display():
	if not current_player or not current_player.get_inventory():
		return

	var player_inventory = current_player.get_inventory()
	for i in range(slot_uis.size()):
		if i < PlayerInventory.INVENTORY_SIZE:
			slot_uis[i].set_slot_data(player_inventory.get_slot(i), i)
	weapon_slot_ui.set_slot_data(player_inventory.equipped_weapon, SLOT_INDEX_WEAPON)
	armor_slot_ui.set_slot_data(player_inventory.equipped_armor, SLOT_INDEX_ARMOR)

func _on_slot_clicked(slot_index: int, button: int):
	match button:
		MOUSE_BUTTON_LEFT:
			pass
		MOUSE_BUTTON_RIGHT:
			_handle_right_click(slot_index)

func _handle_right_click(slot_index: int):
	if not current_player or not current_player.get_inventory():
		return

	var player_inventory = current_player.get_inventory()
	current_slot_index = slot_index
	var slot: InventorySlot
	if slot_index == SLOT_INDEX_WEAPON:
		slot = player_inventory.equipped_weapon
	elif slot_index == SLOT_INDEX_ARMOR:
		slot = player_inventory.equipped_armor
	else:
		slot = player_inventory.get_slot(slot_index)
	if slot and not slot.is_empty():
		current_item = ItemDatabase.get_item(slot.item_id)
		if current_item:
			_hide_tooltip()
			var context_menu = PopupMenu.new()
			menubar.add_child( context_menu )
			context_menu.popup_hide.connect(context_menu.queue_free)
			context_menu.id_pressed.connect( _on_item_selected )
			if slot_index == SLOT_INDEX_WEAPON or slot_index == SLOT_INDEX_ARMOR:
				context_menu.add_item(_get_context_menu_string(Item.ContextOptions.UNEQUIP), Item.ContextOptions.UNEQUIP)
			else:
				for item_option in current_item.context_options:
					context_menu.add_item( _get_context_menu_string(item_option), item_option )
			
			context_menu.set_position( get_viewport().get_mouse_position() )
			context_menu.popup()


func _on_item_selected(index: int):
	if not current_player or not current_player.get_inventory():
		return
	 
	if index == Item.ContextOptions.DRINK:
		var result = current_item.context_callable[Item.ContextOptions.DRINK].call()
		if result:
			current_player.request_remove_item.rpc_id( 1,  current_item.id, 1 )
			refresh_display()
	elif index == Item.ContextOptions.EXAMINE:
		current_item.context_callable[Item.ContextOptions.EXAMINE].call()
	elif index == Item.ContextOptions.EAT:
		var result = current_item.context_callable[Item.ContextOptions.EAT].call()
		if result:
			current_player.request_remove_item.rpc_id( 1,  current_item.id, 1 )
			refresh_display()
	elif index == Item.ContextOptions.EQUIP:
		current_player.request_equip_item.rpc_id(1, current_slot_index, current_item.item_type)
	elif index == Item.ContextOptions.UNEQUIP:
		current_player.request_unequip_item.rpc_id(1, current_item.item_type)
	elif index == Item.ContextOptions.THROW:
		current_item.context_callable[Item.ContextOptions.THROW].call()
	elif index == Item.ContextOptions.READ:
		current_item.context_callable[Item.ContextOptions.READ].call()
	elif index == Item.ContextOptions.DROP:
		if current_item.scene_path.is_empty() or not ResourceLoader.exists(current_item.scene_path):
			push_warning("Cannot drop item '" + current_item.id + "': invalid scene path '" + current_item.scene_path + "'")
			return
		current_player.add_world_item.rpc_id( 1, current_item.scene_path,  current_player.get_node("GodotRobot3D/InfrontArea3D").global_position )
		current_player.request_remove_item.rpc_id( 1,  current_item.id, 1 )
		refresh_display()

func _on_item_hovered(_slot_index: int, item: Item):
	_show_tooltip(item)

func _on_item_unhovered():
	_hide_tooltip()

func _show_tooltip(item: Item):
	if not item:
		return

	var tooltip_content = "[b][color=#FFD700]" + item.name + "[/color][/b]\n"
	tooltip_content += "[color=#CCCCCC]" + item.description + "[/color]\n\n"
	tooltip_content += "[color=#87CEEB]Type:[/color] " + _get_item_type_string(item.item_type) + "\n"
	tooltip_content += "[color=#FF69B4]Rarity:[/color] " + _get_rarity_string(item.rarity) + "\n"
	tooltip_content += "[color=#FFD700]Value:[/color] " + str(item.value) + " gold"

	if item.stackable:
		tooltip_content += "\n[color=#98FB98]Max Stack:[/color] " + str(item.max_stack)

	tooltip_label.text = tooltip_content
	tooltip.visible = true

	_position_tooltip_smartly()

func _hide_tooltip():
	tooltip.visible = false

func _position_tooltip_smartly():
	var mouse_pos = get_global_mouse_position()
	var tooltip_size = tooltip.size

	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_pos = mouse_pos + Vector2(10, 10)

	if tooltip_pos.x + tooltip_size.x > viewport_size.x:
		tooltip_pos.x = mouse_pos.x - tooltip_size.x - 10

	if tooltip_pos.y + tooltip_size.y > viewport_size.y:
		tooltip_pos.y = mouse_pos.y - tooltip_size.y - 10

	if tooltip_pos.x < 0:
		tooltip_pos.x = 10

	if tooltip_pos.y < 0:
		tooltip_pos.y = 10

	tooltip.global_position = tooltip_pos

func _get_item_type_string(type: Item.ItemType) -> String:
	match type:
		Item.ItemType.WEAPON: return "Weapon"
		Item.ItemType.ARMOR: return "Armor"
		Item.ItemType.CONSUMABLE: return "Consumable"
		Item.ItemType.TOOL: return "Tool"
		Item.ItemType.MISC: return "Miscellaneous"
		_: return "Unknown"

func _get_rarity_string(rarity: Item.ItemRarity) -> String:
	match rarity:
		Item.ItemRarity.COMMON: return "Common"
		Item.ItemRarity.UNCOMMON: return "Uncommon"
		Item.ItemRarity.RARE: return "Rare"
		Item.ItemRarity.EPIC: return "Epic"
		Item.ItemRarity.LEGENDARY: return "Legendary"
		_: return "Unknown"

func _get_context_menu_string( context: Item.ContextOptions ) -> String:
	match context:
		Item.ContextOptions.DRINK: return "Drink"
		Item.ContextOptions.EAT: return "Eat"
		Item.ContextOptions.DROP: return "Drop"
		Item.ContextOptions.EQUIP: return "Equip"
		Item.ContextOptions.THROW: return "Throw"
		Item.ContextOptions.READ: return "Read"
		Item.ContextOptions.UNEQUIP: return "Unequip"
		_: return "Unknown"


func handle_item_drop(from_slot: int, to_slot: int, _item_id: String):
	if not current_player:
		return
	if from_slot == SLOT_INDEX_WEAPON:
		current_player.request_unequip_item.rpc_id(1, Item.ItemType.WEAPON, to_slot)
	elif from_slot == SLOT_INDEX_ARMOR:
		current_player.request_unequip_item.rpc_id(1, Item.ItemType.ARMOR, to_slot)
	else:
		current_player.request_move_item.rpc_id(1, from_slot, to_slot)

func _on_close_pressed():
	inventory_closed.emit()
	visible = false

func open_inventory(player: Character = null):
	if player:
		current_player = player
		update_inventory_display()
	visible = true

func close_inventory():
	visible = false

func refresh_display():
	update_inventory_display()

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and visible:
			_on_close_pressed()

func handle_weapon_equip(from_slot: int, item: Dictionary):
	if current_player and from_slot >= 0 and item.inventory_type == Item.ItemType.WEAPON:
		current_player.request_equip_item.rpc_id(1, from_slot, Item.ItemType.WEAPON)

func handle_armor_equip(from_slot: int, item: Dictionary):
	if current_player and from_slot >= 0 and item.inventory_type == Item.ItemType.ARMOR:
		current_player.request_equip_item.rpc_id(1, from_slot, Item.ItemType.ARMOR)
