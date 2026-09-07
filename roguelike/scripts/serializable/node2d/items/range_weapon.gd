extends Item
class_name RangeWeapon

var damage: int = 0
var mana_cost: int = 0


func _ready() -> void:
	super._ready()
	equippable = true
	usable = false


func equip() -> void:
	if equipped:
		return
	super.equip()
	if Globals.game.player.range_weapon != null:
		Globals.game.player.range_weapon.unequip()

	Globals.game.player.range_weapon = self


func unequip() -> void:
	if not equipped:
		return
	super.unequip()
	Globals.game.player.range_weapon = null


func drop() -> bool:
	unequip()
	return super.drop()


func copy(range_weapon) -> void:
	super.copy(range_weapon)

	damage = range_weapon.damage
	mana_cost = range_weapon.mana_cost


static func clone(range_weapon) -> Variant:
	var result_range_weapon = RangeWeapon.new()
	result_range_weapon.copy(range_weapon)

	return result_range_weapon


func get_info() -> String:
	var info: String = super.get_info()

	info = Utils.append_info_line(info, {
		"Damage": str(damage),
		"Mana Cost": str(mana_cost)
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
			"damage",
			"mana_cost"
		]
	)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	result["damage"] = damage
	result["mana_cost"] = mana_cost
	result["type"] = "range_weapon"

	return result
