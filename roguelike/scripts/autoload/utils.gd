extends Node

################################################################################
# Functions
################################################################################

var dict_string_to_enemy_type: Dictionary[String, Globals.EntityType] = {
	"default" = Globals.EntityType.ENTITY,
	"entity" = Globals.EntityType.ENTITY,
	"enemy" = Globals.EntityType.ENEMY
}
func string_to_enemy_type(string: String) -> Globals.EntityType:
	return dict_string_to_enemy_type.get(string.strip_edges().to_lower(), dict_string_to_enemy_type["default"])

var dict_string_to_item_type: Dictionary[String, Globals.ItemType] = {
	"default" = Globals.ItemType.ITEM,
	"item" = Globals.ItemType.ITEM,
	"healing_potion" = Globals.ItemType.HEALING_POTION,
	"melee_weapon" = Globals.ItemType.MELEE_WEAPON,
	"range_weapon" = Globals.ItemType.RANGE_WEAPON
}
func string_to_item_type(string: String) -> Globals.ItemType:
	return dict_string_to_item_type.get(string.strip_edges().to_lower(), dict_string_to_item_type["default"])

## Return true if any element of array has propriety == value. Else, returns false.
func any_of_array_has_propriety_with_value(
	array: Array, propriety: String, value: Variant
) -> bool:
	for element in array:
		if element and element.get(propriety) == value:
			return true
	
	return false


## Print a rich warning message on the terminal.
func print_warning(message: String):
	print_rich("[color=#ffff00]⚠ Warning: %s[/color]" % message)


## Return if a index is a border of a Rect2i.
func is_border(rect: Rect2i, pos: Vector2i) -> bool:
	return (
		pos.x == rect.position.x
		|| pos.y == rect.position.y
		|| pos.x == rect.position.x + rect.size.x - 1
		|| pos.y == rect.position.y + rect.size.y - 1
	)

func append_info_line(info_text: String, values: Dictionary[String, String]) -> String:
	for key in values:
		if values[key] == "":
			continue
		if info_text != "":
			info_text += "\n"
		info_text += "• [b]%s[/b]: [i]%s[/i]" % [key, values[key]]
	
	return info_text

## Return a random Vector2i direction.
func get_random_direction() -> Vector2i:
	return Vector2i(Globals.rng.randi_range(-1, 1), Globals.rng.randi_range(-1, 1))

func get_random_point_in_rect(rect_area: Rect2i) -> Vector2i:
	# Generate a random x-coordinate within the rect's horizontal range
	var random_x = Globals.rng.randi_range(rect_area.position.x, rect_area.position.x + rect_area.size.x)
	
	# Generate a random y-coordinate within the rect's vertical range
	var random_y = Globals.rng.randi_range(rect_area.position.y, rect_area.position.y + rect_area.size.y)
	
	# Return the new Vector2 point
	return Vector2i(random_x, random_y)


########################################
# Position
########################################

## Converts integer grid position to a global position.
func grid_position_to_global_position(grid_position: Vector2i) -> Vector2:
	return grid_position * Globals.tile_size


## Converts float global position to a integer grid_position.
func global_position_to_grid_position(global_position: Vector2) -> Vector2i:
	return Vector2(
		ceili(global_position.x / float(Globals.tile_size.x)),
		ceili(global_position.y / float(Globals.tile_size.y))
	)

## Serialize a Vector2i.
func vector2i_to_string(pos: Vector2i) -> String:
	return "%s,%s" % [pos.x, pos.y]


func string_to_vector2i(pos: String) -> Vector2i:
	if pos == "":
		return Vector2i.ZERO

	var regex_result: RegExMatch = Globals.vector2i_string_regex.search(pos)
	var grid_position: Vector2i = Vector2i.ZERO

	if not regex_result:
		Globals.print_warning("Invalid vector2i string '%s'" % pos)
		return grid_position

	grid_position.x = regex_result.strings[1].to_int()
	grid_position.y = regex_result.strings[2].to_int()
	return grid_position

func rect2i_to_string(rect: Rect2i) -> String:
	return "%s,%s,%s,%s" % [rect.position.x, rect.position.y, rect.size.x, rect.size.y]

func string_to_rect2i(rect: String) -> Rect2i:
	var regex_result: RegExMatch = Globals.rect2i_string_regex.search(rect)
	var rect_result: Rect2i = Rect2i()

	if rect == "":
		return rect_result

	if not regex_result:
		Globals.print_warning("Invalid rect2i string '%s'" % rect)
		return rect_result

	rect_result.position.x = regex_result.strings[1].to_int()
	rect_result.position.y = regex_result.strings[2].to_int()
	rect_result.size.x = regex_result.strings[3].to_int()
	rect_result.size.y = regex_result.strings[4].to_int()

	return rect_result

########################################
# Dictionary 
########################################

## Checks if a dictionary has all keys.
func dict_has_all(dict: Dictionary, keys: Array[String]) -> bool:
	for key in keys:
		if not dict.has(key):
			return false
	
	return true

## Tests if dict.has(key) and str(dict[key]).to_lower == value
func dict_has_and_is_equal_lower_string(dict: Dictionary, key: String, value: String) -> bool:
	return dict.has(key) and str(dict[key]).to_lower() == value


## Updates an node using values from a dictionary, based on a list of properties.
## If the property exists in the dictionary and is in properties, it is copied.
## If it doesn't exist and is in warning, a warning is logged.
func copy_from_dict_if_exists(
		node: Object,
		dictionary: Dictionary,
		properties: PackedStringArray = [],
		warning: PackedStringArray = []
) -> void:
	for key in properties:
		if dictionary.has(key):
			if node.get(key) != null:
				node.set(key, dictionary.get(key))
			else:
				print_warning("Object %s does not have property '%s'." % [node, key])
		elif warning.has(key):
			print_warning("Tried to copy property '%s' to node '%s', but dictionary is missing it." % [key, node.name])
