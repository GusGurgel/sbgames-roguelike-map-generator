extends HBoxContainer
class_name ItemFrame

var item: Item

@export var name_label: Label
@export var use_button: Button
@export var equip_button: Button
@export var drop_button: Button
@export var texture_rect: TextureRect


func _ready() -> void:
	if item.usable:
		use_button.button_down.connect(_on_use_button_down)
	else:
		use_button.visible = false
	
	if item.equippable:
		equip_button.button_down.connect(_on_equip_button_down)
		item.on_unequip.connect(_on_unequip_item)

		if item.equipped:
			equip_button.text = "Unequip"
		else:
			equip_button.text = "Equip"
	else:
		equip_button.visible = false
	
	texture_rect.texture = item.texture
	texture_rect.self_modulate = item.self_modulate
	name_label.text = item.tile_name

	drop_button.button_down.connect(_on_drop_button_down)

	tooltip_text = item.get_info()


func _on_use_button_down() -> void:
	item.use()
	queue_free()


func _on_equip_button_down() -> void:
	if item.equipped:
		item.unequip()
		equip_button.text = "Equip"
	else:
		item.equip()
		equip_button.text = "Unequip"


func _on_drop_button_down() -> void:
	if item.drop():
		queue_free()


func _on_unequip_item() -> void:
	equip_button.text = "Equip"
