extends SerializableNode2D
class_name ItemsList

var items: Dictionary[String, Item]

var layer: Layer


func _init(_layer: Layer):
	layer = _layer


func get_item(pos: Vector2i) -> Item:
	return items.get(Utils.vector2i_to_string(pos))


## Return if the item was drop or not.
func add_item(pos: Vector2i, item: Item, clone: bool = true) -> bool:
	var item_to_add: Item

	if clone:
		if item is MeleeWeapon:
			item_to_add = MeleeWeapon.clone(item)
		elif item is RangeWeapon:
			item_to_add = RangeWeapon.clone(item)
		elif item is HealingPotion:
			item_to_add = HealingPotion.clone(item)
		else:
			item_to_add = Item.clone(item)
	else:
		item_to_add = item

	item_to_add.grid_position = pos
	var pos_key: String = Utils.vector2i_to_string(item_to_add.grid_position)

	if items.has(pos_key):
		Utils.print_warning("An item already exists in the position (%s)" % pos_key)
		return false
	items[pos_key] = item_to_add

	if item_to_add.get_parent():
		item_to_add.reparent(self)
	else:
		add_child(item_to_add)

	return true

## Returns if the item was remove or not.
func erase_item(pos: Vector2i) -> bool:
	var pos_key: String = Utils.vector2i_to_string(pos)

	if items.has(pos_key):
		items.erase(pos_key)
		return true
	else:
		return false

################################################################################
# Serialization
################################################################################
func load(data: Dictionary) -> void:
	super.load(data)
	for item_key in data:
		var item_data: Dictionary = data[item_key]
		var grid_position: Vector2i = Utils.string_to_vector2i(item_key)
		item_data["grid_position"] = {
			x = grid_position.x,
			y = grid_position.y
		}
		var item: Item

		if not item_data.has("type"):
			item_data["type"] = "default"
		
		match Utils.string_to_item_type(item_data["type"]):
			Globals.ItemType.HEALING_POTION:
				item = HealingPotion.new()
			Globals.ItemType.MELEE_WEAPON:
				item = MeleeWeapon.new()
			Globals.ItemType.RANGE_WEAPON:
				item = RangeWeapon.new()
			_:
				item = Item.new()

		item.load(item_data)
		add_item(item.grid_position, item, false)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	for item_key in items:
		result[item_key] = items[item_key].serialize()

	return result
