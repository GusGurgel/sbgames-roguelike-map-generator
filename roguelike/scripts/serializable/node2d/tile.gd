extends SerializableSprite2D
class_name Tile

signal tile_grid_position_change(old_pos: Vector2i, new_pos: Vector2i)


func _init(add_background: bool = false, background_z_index: int = -1):
	if add_background:
		var background = Sprite2D.new()
		background.texture = Globals.blank_atlas_texture
		background.self_modulate = Color(0, 0, 0, 0.4)
		background.z_index = background_z_index
		background.z_as_relative = false
		background.centered = false
		add_child(background)

var grid_position: Vector2i = Vector2i(0, 0):
	set(new_grid_position):
		var old_grid_position: Vector2i = grid_position
		position = Utils.grid_position_to_global_position(new_grid_position)
		grid_position = new_grid_position
		tile_grid_position_change.emit(old_grid_position, grid_position)


var is_explored: bool = false:
	set(new_is_explored):
		if new_is_explored and not visible:
			visible = true

		is_explored = new_is_explored


var is_in_view: bool = false:
	set(new_is_in_view):
		if new_is_in_view:
			is_explored = true
			visible = true
			self_modulate.a = 1
		else:
			if is_explored:
				self_modulate.a = 0.4
			else:
				visible = false

		is_in_view = new_is_in_view

var is_transparent = false
var has_collision = false

var preset_name: String = ""
var texture_name: String = ""

var tile_name: String = ""
var tile_description: String = ""
var tile_color_hex: String = ""


func _ready():
	centered = false
	# This triggers the modulate modification of tile.
	is_in_view = is_in_view


func copy(tile) -> void:
	texture = tile.texture
	has_collision = tile.has_collision
	is_transparent = tile.is_transparent
	self_modulate = tile.self_modulate
	tile_name = tile.tile_name
	tile_description = tile.tile_description
	texture_name = tile.texture_name
	tile_color_hex = tile.tile_color_hex


## Copy information from a preset.
static func from_tile_preset(preset_key: String) -> Tile:
	var tile_preset: Tile = Globals.tile_preset_list.get_tile_preset(preset_key)
	var result_tile = Tile.new()
	result_tile.copy(tile_preset)
	result_tile.preset_name = preset_key

	return result_tile


func get_info() -> String:
	var info: String

	info = Utils.append_info_line(info, {
		"Name": tile_name,
		"Description": tile_description
	})

	if Globals.verbose_tile_info:
		info = Utils.append_info_line(info, {
			"Texture Name": texture_name,
			"Has Collision": str(has_collision),
			"Preset Name": preset_name
		})

	return info

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)

	var game: Game = Globals.game
	var warnings: PackedStringArray = []

	if not game:
		return

	if data.has("grid_position"):
		if Utils.dict_has_all(data["grid_position"], ["x", "y"]):
			grid_position = Vector2i(data["grid_position"]["x"], data["grid_position"]["y"])
		else:
			grid_position = Vector2i.ZERO
			Utils.print_warning("Grid position of a tile is missing x or y.")

	if data.has("preset_name"):
		var tile_preset: Tile = game.tiles_presets.get_tile_preset(data["preset_name"])
		if tile_preset != null:
			texture = tile_preset.texture
			texture_name = tile_preset.texture_name
			has_collision = tile_preset.has_collision
			is_transparent = tile_preset.is_transparent
			self_modulate = tile_preset.self_modulate
			tile_name = tile_preset.tile_name
			tile_description = tile_preset.tile_description
		else:
			Utils.print_warning("Preset '%s' not exists." % data["preset_name"])
			data.erase("preset_name")
	
	# All textures that do not have a preset name need to have this properties
	# explicitly defined.
	if not data.has("preset_name"):
		warnings = ["grid_position", "texture", "tile_name"]

	if data.has("texture"):
		if game.textures.textures.has(data["texture"]):
			texture_name = data["texture"]
		else:
			texture_name = "default"
		texture = game.textures.get_texture(data["texture"])

	if data.has("color"):
		if not Globals.hex_color_regex.search(data["color"]):
			Utils.print_warning("Invalid color hex '%s' on tile." % data["color"])
		if data.has("texture"):
			texture = game.textures.get_texture_monochrome(data["texture"])
		self_modulate = Color(data["color"])
	
	Utils.copy_from_dict_if_exists(
		self,
		data,
		[
			"preset_name",
			"is_transparent",
			"has_collision",
			"is_explored",
			"tile_name",
			"tile_description"
		],
		warnings
	)

func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	if preset_name != "":
		result["preset_name"] = preset_name
		result["is_explored"] = is_explored
	else:
		result["texture"] = texture_name
		result["has_collision"] = has_collision
		result["is_explored"] = is_explored
		result["is_in_view"] = is_in_view
		result["is_transparent"] = is_transparent
		result["tile_name"] = tile_name
		result["tile_description"] = tile_description
		if tile_color_hex != "":
			result["color"] = tile_color_hex
	
	result["grid_position"] = {
		x = self.grid_position.x,
		y = self.grid_position.y
	}

	return result
