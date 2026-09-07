extends Item
class_name MeleeWeapon

var damage: int = 0
var turns_to_use: int = 1


func _ready() -> void:
	super._ready()
	equippable = true
	usable = false


func equip() -> void:
	if equipped:
		return
	super.equip()
	if Globals.game.player.melee_weapon != null:
		Globals.game.player.melee_weapon.unequip()

	Globals.game.player.melee_weapon = self


func unequip() -> void:
	if not equipped:
		return
	super.unequip()
	Globals.game.player.melee_weapon = null


func drop() -> bool:
	unequip()
	return super.drop()


func copy(melee_weapon) -> void:
	super.copy(melee_weapon)

	damage = melee_weapon.damage
	turns_to_use = melee_weapon.turns_to_use


static func clone(melee_weapon) -> Variant:
	var result_melee_weapon = MeleeWeapon.new()
	result_melee_weapon.copy(melee_weapon)

	return result_melee_weapon


func get_info() -> String:
	var info: String = super.get_info()

	info = Utils.append_info_line(info, {
		"Damage": str(damage),
		"Turns to Use": str(turns_to_use)
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
			"damage"
		]
	)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	result["damage"] = damage
	result["turns_to_use"] = turns_to_use
	result["type"] = "melee_weapon"

	return result
