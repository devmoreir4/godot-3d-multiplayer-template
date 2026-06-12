class_name PlayerInventory
extends RefCounted

const INVENTORY_SIZE = 20
var slots: Array[InventorySlot] = []
var equipped_weapon: InventorySlot = InventorySlot.new()
var equipped_armor: InventorySlot = InventorySlot.new()

func _init():
	_initialize_slots()

func _initialize_slots():
	slots.clear()
	for i in range(INVENTORY_SIZE):
		slots.append(InventorySlot.new())

func get_slot(index: int) -> InventorySlot:
	if index >= 0 and index < slots.size():
		return slots[index]
	return null

func get_equipped_slot(item_type: Item.ItemType) -> InventorySlot:
	match item_type:
		Item.ItemType.WEAPON:
			return equipped_weapon
		Item.ItemType.ARMOR:
			return equipped_armor
		_:
			return null

func equip_from_slot(index: int, item_type: Item.ItemType) -> bool:
	var backpack_slot: InventorySlot = get_slot(index)
	var equipped_slot: InventorySlot = get_equipped_slot(item_type)
	if not backpack_slot or backpack_slot.is_empty() or not equipped_slot:
		return false

	var item: Item = ItemDatabase.get_item(backpack_slot.item_id)
	if not item or item.item_type != item_type:
		return false

	var previous_item_id: String = equipped_slot.item_id
	var previous_quantity: int = equipped_slot.quantity
	equipped_slot.item_id = backpack_slot.item_id
	equipped_slot.quantity = 1

	if previous_item_id.is_empty():
		backpack_slot.remove_item(1)
	else:
		backpack_slot.item_id = previous_item_id
		backpack_slot.quantity = previous_quantity
	return true

func unequip_to_slot(item_type: Item.ItemType, destination_index: int = -1) -> bool:
	var equipped_slot: InventorySlot = get_equipped_slot(item_type)
	if not equipped_slot or equipped_slot.is_empty():
		return false

	if destination_index < 0:
		destination_index = get_first_empty_slot()
	var destination: InventorySlot = get_slot(destination_index)
	if not destination or not destination.is_empty():
		return false

	destination.item_id = equipped_slot.item_id
	destination.quantity = equipped_slot.quantity
	equipped_slot.clear()
	return true

func add_item(item: Item, quantity: int = 1) -> int:
	var remaining = quantity

	if item.stackable:
		for slot in slots:
			if slot.item_id == item.id:
				remaining = slot.add_item(item, remaining)
				if remaining <= 0:
					break

	if remaining > 0:
		for slot in slots:
			if slot.is_empty():
				remaining = slot.add_item(item, remaining)
				if remaining <= 0:
					break

	return remaining

func remove_item(item_id: String, quantity: int = 1) -> int:
	var removed = 0
	for slot in slots:
		if slot.item_id == item_id:
			var slot_removed = slot.remove_item(quantity - removed)
			removed += slot_removed
			if removed >= quantity:
				break
	return removed

func move_item(from_index: int, to_index: int, quantity: int = -1) -> bool:
	if from_index == to_index:
		return false

	var from_slot = get_slot(from_index)
	var to_slot = get_slot(to_index)

	if not from_slot or not to_slot or from_slot.is_empty():
		return false

	var move_amount = quantity if quantity > 0 else from_slot.quantity
	move_amount = min(move_amount, from_slot.quantity)

	var item = ItemDatabase.get_item(from_slot.item_id)
	if not item:
		return false

	if to_slot.can_add_item(item, move_amount):
		from_slot.remove_item(move_amount)
		to_slot.add_item(item, move_amount)
		return true

	if to_slot.is_empty():
		from_slot.remove_item(move_amount)
		to_slot.add_item(item, move_amount)
		return true
	else:
		var remaining_after_stack = try_stack_item(item, move_amount, from_index)
		if remaining_after_stack < move_amount:
			var moved_amount = move_amount - remaining_after_stack
			from_slot.remove_item(moved_amount)

			if remaining_after_stack > 0:
				to_slot.add_item(item, remaining_after_stack)
			return true

	return false

func swap_items(from_index: int, to_index: int) -> bool:
	var from_slot = get_slot(from_index)
	var to_slot = get_slot(to_index)

	if not from_slot or not to_slot:
		return false

	if from_slot.item_id == to_slot.item_id and not from_slot.is_empty() and not to_slot.is_empty():
		var item = ItemDatabase.get_item(from_slot.item_id)
		if item and item.stackable:
			var total_quantity = from_slot.quantity + to_slot.quantity
			if total_quantity <= item.max_stack:
				to_slot.quantity = total_quantity
				from_slot.clear()
				return true
			else:
				var space_available = item.max_stack - to_slot.quantity
				var amount_to_move = min(space_available, from_slot.quantity)
				to_slot.quantity += amount_to_move
				from_slot.quantity -= amount_to_move
				if from_slot.quantity <= 0:
					from_slot.clear()
				return true

	var temp_item_id = from_slot.item_id
	var temp_quantity = from_slot.quantity

	from_slot.item_id = to_slot.item_id
	from_slot.quantity = to_slot.quantity

	to_slot.item_id = temp_item_id
	to_slot.quantity = temp_quantity

	return true

func get_item_count(item_id: String) -> int:
	var total = 0
	for slot in slots:
		if slot.item_id == item_id:
			total += slot.quantity
	return total

func has_item(item_id: String, quantity: int = 1) -> bool:
	return get_item_count(item_id) >= quantity

func get_first_empty_slot() -> int:
	for i in range(slots.size()):
		if slots[i].is_empty():
			return i
	return -1

func get_free_space_for_item(item: Item) -> int:
	var free_space = 0

	if item.stackable:
		for slot in slots:
			if slot.item_id == item.id:
				free_space += item.max_stack - slot.quantity

	for slot in slots:
		if slot.is_empty():
			free_space += item.max_stack if item.stackable else 1

	return free_space

func try_stack_item(item: Item, quantity: int, exclude_slot: int = -1) -> int:
	if not item.stackable:
		return quantity

	var remaining = quantity

	for i in range(slots.size()):
		if i == exclude_slot:
			continue

		var slot = slots[i]
		if slot.item_id == item.id and not slot.is_empty():
			var space_available = item.max_stack - slot.quantity
			if space_available > 0:
				var amount_to_stack = min(remaining, space_available)
				slot.quantity += amount_to_stack
				remaining -= amount_to_stack
				if remaining <= 0:
					break

	return remaining

func to_dict() -> Dictionary:
	var data = []
	for slot in slots:
		data.append(slot.to_dict())
	return {
		"slots": data,
		"equipped_weapon": equipped_weapon.to_dict(),
		"equipped_armor": equipped_armor.to_dict()
	}

func from_dict(data: Dictionary) -> void:
	var slots_data = data.get("slots", [])
	for i in range(min(slots_data.size(), slots.size())):
		slots[i].from_dict(slots_data[i])
	for i in range(slots_data.size(), slots.size()):
		slots[i].clear()
	equipped_weapon.from_dict(data.get("equipped_weapon", {}))
	equipped_armor.from_dict(data.get("equipped_armor", {}))
