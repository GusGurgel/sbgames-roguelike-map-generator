extends Tile
class_name Item

var usable: bool = false
var equippable: bool = false
var equipped: bool = false
var rarity: int = 1
var weight: int = 1

signal on_unequip


func _init():
	super._init(true, 0)

	z_index = 1
	z_as_relative = false


func _ready():
	super._ready()
	is_transparent = true
	has_collision = false


func use() -> void:
	queue_free()


func equip() -> void:
	equipped = true


func unequip() -> void:
	equipped = false
	on_unequip.emit()


func drop() -> bool:
	grid_position = Globals.game.player.grid_position
	var item_was_drop = Globals.game.layers.get_current_layer().items.add_item(grid_position, self, false)

	return item_was_drop


func copy(item) -> void:
	super.copy(item)

	usable = item.usable
	equippable = item.equippable
	equipped = item.equipped
	rarity = item.rarity
	weight = item.weight


static func clone(item) -> Variant:
	var result_item = Item.new()
	result_item.copy(item)

	return result_item


func get_info() -> String:
	var info: String = super.get_info()

	info = Utils.append_info_line(info, {
		"Rarity": str(rarity),
		"Weight": str(weight)
	})

	return info

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)
	Utils.copy_from_dict_if_exists(
		self,
		data,
		[
			"usable",
			"equippable",
			"equipped",
			"rarity",
			"weight"
		]
	)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	result["usable"] = usable
	result["equippable"] = equippable
	result["equipped"] = equipped
	result["rarity"] = rarity
	result["weight"] = weight

	return result
