class_name InventoryUI
extends Control

signal inventory_closed

const SAFE_AREA_MARGIN := 16.0
const TOOLTIP_MAX_WIDTH := 280.0
const TOOLTIP_MAX_HEIGHT := 240.0
const TOOLTIP_SCREEN_MARGIN := 10.0
const TOOLTIP_HORIZONTAL_PADDING := 16.0
const TOOLTIP_VERTICAL_PADDING := 16.0

const SLOT_INDEX_WEAPON := -1
const SLOT_INDEX_HAT := -2
const SLOT_INDEX_BACKPACK := -3

var current_player: Character
var slot_ui_scene: PackedScene
var slot_uis: Array[InventorySlotUI] = []
var current_item: Item
var current_slot_index: int
var weapon_slot_ui: InventorySlotUI
var hat_slot_ui: InventorySlotUI
var backpack_slot_ui: InventorySlotUI
var _tooltip_layout_request := 0
var _tooltip_should_be_visible := false

@onready var grid_container: GridContainer = get_node(
	"SafeArea/CenterContainer/InventoryPanels/InventoryPanel/MarginContainer/VBoxContainer/GridContainer"
)
@onready var close_button: Button = get_node(
	"SafeArea/CenterContainer/InventoryPanels/InventoryPanel/MarginContainer/VBoxContainer/TitleBar/CloseButton"
)
@onready var tooltip: Control = $ItemTooltip
@onready var tooltip_label: RichTextLabel = $ItemTooltip/Panel/MarginContainer/TooltipText
@onready var inventory_panels: HBoxContainer = $SafeArea/CenterContainer/InventoryPanels


func _ready():
	slot_ui_scene = preload("res://scenes/ui/inventory_slot_ui.tscn")
	grid_container.columns = 4
	close_button.pressed.connect(_on_close_pressed)
	tooltip.visible = false
	_create_slot_uis()
	_create_hat_slot_ui()
	_create_weapon_slot_ui()
	_create_backpack_slot_ui()
	resized.connect(_update_responsive_layout)
	call_deferred("_update_responsive_layout")


func _create_hat_slot_ui():
	hat_slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
	hat_slot_ui.custom_minimum_size = Vector2(64, 64)
	hat_slot_ui.parent_inventory = self
	hat_slot_ui.slot_type = InventorySlotUI.TYPE.HAT
	hat_slot_ui.slot_clicked.connect(_on_slot_clicked)
	hat_slot_ui.item_hovered.connect(_on_item_hovered)
	hat_slot_ui.item_unhovered.connect(_on_item_unhovered)
	(
		get_node(
			"SafeArea/CenterContainer/InventoryPanels/EquipmentPanel/MarginContainer/VBoxContainer/HatSlotContainer"
		)
		. add_child(hat_slot_ui)
	)


func _create_weapon_slot_ui():
	weapon_slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
	weapon_slot_ui.custom_minimum_size = Vector2(64, 64)
	weapon_slot_ui.parent_inventory = self
	weapon_slot_ui.slot_type = InventorySlotUI.TYPE.WEAPON
	weapon_slot_ui.slot_clicked.connect(_on_slot_clicked)
	weapon_slot_ui.item_hovered.connect(_on_item_hovered)
	weapon_slot_ui.item_unhovered.connect(_on_item_unhovered)
	(
		get_node(
			"SafeArea/CenterContainer/InventoryPanels/EquipmentPanel/MarginContainer/VBoxContainer/WeaponSlotContainer"
		)
		. add_child(weapon_slot_ui)
	)


func _create_backpack_slot_ui() -> void:
	backpack_slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
	backpack_slot_ui.custom_minimum_size = Vector2(64, 64)
	backpack_slot_ui.parent_inventory = self
	backpack_slot_ui.slot_type = InventorySlotUI.TYPE.BACKPACK
	backpack_slot_ui.slot_clicked.connect(_on_slot_clicked)
	backpack_slot_ui.item_hovered.connect(_on_item_hovered)
	backpack_slot_ui.item_unhovered.connect(_on_item_unhovered)
	(
		get_node(
			"SafeArea/CenterContainer/InventoryPanels/EquipmentPanel/MarginContainer/VBoxContainer/BackpackSlotContainer"
		)
		. add_child(backpack_slot_ui)
	)


func _create_slot_uis():
	for child in grid_container.get_children():
		child.queue_free()
	slot_uis.clear()

	for i in range(PlayerInventory.MAX_INVENTORY_SIZE):
		var slot_ui = slot_ui_scene.instantiate() as InventorySlotUI
		slot_ui.custom_minimum_size = Vector2(64, 64)
		slot_ui.parent_inventory = self
		slot_ui.visible = i < PlayerInventory.BASE_INVENTORY_SIZE

		slot_ui.slot_clicked.connect(_on_slot_clicked)
		slot_ui.slot_double_clicked.connect(_on_slot_double_clicked)
		slot_ui.item_hovered.connect(_on_item_hovered)
		slot_ui.item_unhovered.connect(_on_item_unhovered)

		slot_ui.set_slot_data(null, i)

		grid_container.add_child(slot_ui)
		slot_uis.append(slot_ui)


func update_inventory_display():
	if not current_player or not current_player.get_inventory():
		return

	var player_inventory = current_player.get_inventory()
	var active_slot_count := player_inventory.get_active_slot_count()
	for i in range(slot_uis.size()):
		slot_uis[i].visible = i < active_slot_count
		if i < active_slot_count:
			slot_uis[i].set_slot_data(player_inventory.get_slot(i), i)
		else:
			slot_uis[i].set_slot_data(null, i)
	weapon_slot_ui.set_slot_data(player_inventory.equipped_weapon, SLOT_INDEX_WEAPON)
	hat_slot_ui.set_slot_data(player_inventory.equipped_hat, SLOT_INDEX_HAT)
	backpack_slot_ui.set_slot_data(player_inventory.equipped_backpack, SLOT_INDEX_BACKPACK)
	call_deferred("_update_responsive_layout")


func _on_slot_clicked(slot_index: int, button: int):
	if button == MOUSE_BUTTON_RIGHT:
		_handle_right_click(slot_index)


func _on_slot_double_clicked(slot_index: int) -> void:
	if not current_player or not current_player.get_inventory():
		return
	if slot_index < 0 or not current_player.get_inventory().is_slot_active(slot_index):
		return

	var slot := current_player.get_inventory().get_slot(slot_index)
	if not slot or slot.is_empty():
		return

	var item := ItemDatabase.get_item(slot.item_id)
	if not item or not item.context_options.has(Item.ContextOptions.EQUIP):
		return
	if (
		item.item_type != Item.ItemType.WEAPON
		and item.item_type != Item.ItemType.HAT
		and item.item_type != Item.ItemType.BACKPACK
	):
		return

	current_player.request_equip_item.rpc_id(1, slot_index, item.item_type)


func _handle_right_click(slot_index: int):
	if not current_player or not current_player.get_inventory():
		return

	var player_inventory = current_player.get_inventory()
	current_slot_index = slot_index
	var slot: InventorySlot
	if slot_index == SLOT_INDEX_WEAPON:
		slot = player_inventory.equipped_weapon
	elif slot_index == SLOT_INDEX_HAT:
		slot = player_inventory.equipped_hat
	elif slot_index == SLOT_INDEX_BACKPACK:
		slot = player_inventory.equipped_backpack
	else:
		slot = player_inventory.get_slot(slot_index)
	if slot and not slot.is_empty():
		current_item = ItemDatabase.get_item(slot.item_id)
		if current_item:
			_hide_tooltip()
			var context_menu = PopupMenu.new()
			add_child(context_menu)
			context_menu.popup_hide.connect(context_menu.queue_free)
			context_menu.id_pressed.connect(_on_item_selected)
			if slot_index == SLOT_INDEX_WEAPON or slot_index == SLOT_INDEX_HAT or slot_index == SLOT_INDEX_BACKPACK:
				context_menu.add_item(
					_get_context_menu_string(Item.ContextOptions.UNEQUIP), Item.ContextOptions.UNEQUIP
				)
			else:
				for item_option in current_item.context_options:
					context_menu.add_item(_get_context_menu_string(item_option), item_option)

			context_menu.set_position(get_viewport().get_mouse_position())
			context_menu.popup()


func _on_item_selected(index: int):
	if not current_player or not current_player.get_inventory():
		return

	if index == Item.ContextOptions.EQUIP:
		current_player.request_equip_item.rpc_id(1, current_slot_index, current_item.item_type)
	elif index == Item.ContextOptions.UNEQUIP:
		current_player.request_unequip_item.rpc_id(1, current_item.item_type)
	elif index == Item.ContextOptions.DROP:
		if current_item.scene_path.is_empty() or not ResourceLoader.exists(current_item.scene_path):
			push_warning(
				"Cannot drop item '" + current_item.id + "': invalid scene path '" + current_item.scene_path + "'"
			)
			return
		current_player.add_world_item.rpc_id(
			1, current_item.scene_path, current_player.get_node("GodotRobot3D/InfrontArea3D").global_position
		)
		current_player.request_remove_item.rpc_id(1, current_item.id, 1)
		refresh_display()


func _on_item_hovered(_slot_index: int, item: Item):
	_show_tooltip(item)


func _on_item_unhovered():
	_hide_tooltip()


func _show_tooltip(item: Item):
	if not item:
		return

	var tooltip_content = "[font_size=18][b][color=#FFD700]" + item.name + "[/color][/b][/font_size]\n"
	tooltip_content += "[color=#CCCCCC]" + item.description + "[/color]\n"
	tooltip_content += "[color=#87CEEB]Type:[/color] " + _get_item_type_string(item.item_type) + "\n"
	tooltip_content += "[color=#FF69B4]Rarity:[/color] " + _get_rarity_string(item.rarity) + "\n"
	tooltip_content += "[color=#FFD700]Value:[/color] " + str(item.value) + " gold"

	if item.stackable:
		tooltip_content += "\n[color=#98FB98]Max Stack:[/color] " + str(item.max_stack)

	tooltip_label.text = tooltip_content
	_tooltip_should_be_visible = true
	_queue_tooltip_layout()


func _hide_tooltip():
	_tooltip_should_be_visible = false
	_tooltip_layout_request += 1
	tooltip.visible = false
	tooltip.modulate = Color.WHITE


func _queue_tooltip_layout() -> void:
	_set_tooltip_width()
	_tooltip_layout_request += 1
	var request_id := _tooltip_layout_request
	tooltip.modulate = Color(1.0, 1.0, 1.0, 0.0)
	tooltip.visible = true
	_apply_tooltip_layout_after_frame(request_id)


func _apply_tooltip_layout_after_frame(request_id: int) -> void:
	await get_tree().process_frame
	if request_id != _tooltip_layout_request or not _tooltip_should_be_visible or not tooltip or not tooltip_label:
		return

	var tooltip_size := tooltip.size
	var available_height := minf(TOOLTIP_MAX_HEIGHT, maxf(1.0, size.y - TOOLTIP_SCREEN_MARGIN * 2.0))
	tooltip_size.y = minf(float(tooltip_label.get_content_height()) + TOOLTIP_VERTICAL_PADDING, available_height)
	tooltip.size = tooltip_size
	_position_tooltip_smartly()
	tooltip.modulate = Color.WHITE


func _set_tooltip_width() -> void:
	var tooltip_size := tooltip.size
	var available_width := maxf(1.0, size.x - TOOLTIP_SCREEN_MARGIN * 2.0)
	tooltip_size.x = minf(TOOLTIP_MAX_WIDTH, available_width)
	tooltip.size = tooltip_size
	var label_minimum_size := tooltip_label.custom_minimum_size
	label_minimum_size.x = maxf(1.0, tooltip_size.x - TOOLTIP_HORIZONTAL_PADDING)
	tooltip_label.custom_minimum_size = label_minimum_size
	var label_size := tooltip_label.size
	label_size.x = label_minimum_size.x
	tooltip_label.size = label_size


func _position_tooltip_smartly():
	var mouse_pos = get_global_mouse_position()
	var tooltip_size = tooltip.size

	var viewport_size = get_viewport().get_visible_rect().size
	var tooltip_pos = mouse_pos + Vector2.ONE * TOOLTIP_SCREEN_MARGIN
	if tooltip_pos.x + tooltip_size.x > viewport_size.x - TOOLTIP_SCREEN_MARGIN:
		tooltip_pos.x = mouse_pos.x - tooltip_size.x - TOOLTIP_SCREEN_MARGIN
	if tooltip_pos.y + tooltip_size.y > viewport_size.y - TOOLTIP_SCREEN_MARGIN:
		tooltip_pos.y = mouse_pos.y - tooltip_size.y - TOOLTIP_SCREEN_MARGIN

	var max_x := maxf(TOOLTIP_SCREEN_MARGIN, viewport_size.x - tooltip_size.x - TOOLTIP_SCREEN_MARGIN)
	var max_y := maxf(TOOLTIP_SCREEN_MARGIN, viewport_size.y - tooltip_size.y - TOOLTIP_SCREEN_MARGIN)
	tooltip_pos.x = clampf(tooltip_pos.x, TOOLTIP_SCREEN_MARGIN, max_x)
	tooltip_pos.y = clampf(tooltip_pos.y, TOOLTIP_SCREEN_MARGIN, max_y)

	tooltip.global_position = tooltip_pos


func _update_responsive_layout() -> void:
	if not inventory_panels or not tooltip:
		return
	var available_size := Vector2(
		maxf(1.0, size.x - SAFE_AREA_MARGIN * 2.0), maxf(1.0, size.y - SAFE_AREA_MARGIN * 2.0)
	)
	var content_size := inventory_panels.size
	if content_size.x > 0.0 and content_size.y > 0.0:
		var scale_factor := minf(1.0, minf(available_size.x / content_size.x, available_size.y / content_size.y))
		inventory_panels.pivot_offset = content_size * 0.5
		inventory_panels.scale = Vector2.ONE * scale_factor

	_set_tooltip_width()
	if _tooltip_should_be_visible:
		_queue_tooltip_layout()


func _get_item_type_string(type: Item.ItemType) -> String:
	var type_name := "Unknown"
	match type:
		Item.ItemType.WEAPON:
			type_name = "Weapon"
		Item.ItemType.HAT:
			type_name = "Hat"
		Item.ItemType.BACKPACK:
			type_name = "Backpack"
		Item.ItemType.CONSUMABLE:
			type_name = "Consumable"
		Item.ItemType.TOOL:
			type_name = "Tool"
		Item.ItemType.MISC:
			type_name = "Miscellaneous"
	return type_name


func _get_rarity_string(rarity: Item.ItemRarity) -> String:
	match rarity:
		Item.ItemRarity.COMMON:
			return "Common"
		Item.ItemRarity.UNCOMMON:
			return "Uncommon"
		Item.ItemRarity.RARE:
			return "Rare"
		Item.ItemRarity.EPIC:
			return "Epic"
		Item.ItemRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"


func _get_context_menu_string(context: Item.ContextOptions) -> String:
	match context:
		Item.ContextOptions.DROP:
			return "Drop"
		Item.ContextOptions.EQUIP:
			return "Equip"
		Item.ContextOptions.UNEQUIP:
			return "Unequip"
		_:
			return "Unknown"


func handle_item_drop(from_slot: int, to_slot: int):
	if not current_player:
		return
	if from_slot == SLOT_INDEX_WEAPON:
		current_player.request_unequip_item.rpc_id(1, Item.ItemType.WEAPON, to_slot)
	elif from_slot == SLOT_INDEX_HAT:
		current_player.request_unequip_item.rpc_id(1, Item.ItemType.HAT, to_slot)
	elif from_slot == SLOT_INDEX_BACKPACK:
		current_player.request_unequip_item.rpc_id(1, Item.ItemType.BACKPACK, to_slot)
	else:
		current_player.request_move_item.rpc_id(1, from_slot, to_slot)


func _on_close_pressed():
	_hide_tooltip()
	inventory_closed.emit()
	visible = false


func open_inventory(player: Character = null):
	_hide_tooltip()
	if player:
		current_player = player
		update_inventory_display()
	visible = true


func close_inventory():
	_hide_tooltip()
	visible = false


func refresh_display():
	update_inventory_display()


func handle_weapon_equip(from_slot: int, item: Dictionary):
	if current_player and from_slot >= 0 and item.inventory_type == Item.ItemType.WEAPON:
		current_player.request_equip_item.rpc_id(1, from_slot, Item.ItemType.WEAPON)


func handle_hat_equip(from_slot: int, item: Dictionary):
	if current_player and from_slot >= 0 and item.inventory_type == Item.ItemType.HAT:
		current_player.request_equip_item.rpc_id(1, from_slot, Item.ItemType.HAT)


func handle_backpack_equip(from_slot: int, item: Dictionary) -> void:
	if current_player and from_slot >= 0 and item.inventory_type == Item.ItemType.BACKPACK:
		current_player.request_equip_item.rpc_id(1, from_slot, Item.ItemType.BACKPACK)
