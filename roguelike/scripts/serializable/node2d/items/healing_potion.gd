extends Item
class_name HealingPotion

@export var health_increase: int = 0

func _ready() -> void:
	super._ready()
	equippable = false
	usable = true


func use() -> void:
	Globals.game.player.health += health_increase


func copy(healing_potion) -> void:
	super.copy(healing_potion)

	health_increase = healing_potion.health_increase


static func clone(healing_potion) -> Variant:
	var result_healing_potion = HealingPotion.new()
	result_healing_potion.copy(healing_potion)

	return result_healing_potion


func get_info() -> String:
	var info: String = super.get_info()

	info = Utils.append_info_line(info, {
		"Health Regeneration": str(health_increase)
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
			"health_increase"
		]
	)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	result["type"] = "healing_potion"
	result["health_increase"] = health_increase

	return result
