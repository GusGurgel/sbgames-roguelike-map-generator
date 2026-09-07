extends SerializableResource
class_name TilePresetList

var tiles_presets: Dictionary[String, Tile]


func get_tile_preset(tile_preset_key: String) -> Tile:
	if tiles_presets.has(tile_preset_key):
		return tiles_presets[tile_preset_key]
	else:
		return tiles_presets["default"]

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)

	# Adds default tile preset
	tiles_presets["default"] = Tile.new()
	tiles_presets["default"].texture = Globals.game.textures.get_texture("default")

	for tile_preset_key in data:
		var tile_preset_data: Dictionary = data[tile_preset_key]
		var tile: Tile = Tile.new()
		tile_preset_data["grid_position"] = {x = 0, y = 0}
		tile.load(tile_preset_data)
		tiles_presets[tile_preset_key] = tile


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	for tile_preset_key in tiles_presets:
		result[tile_preset_key] = tiles_presets[tile_preset_key].serialize()

	return result
