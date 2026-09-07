extends SerializableNode2D
class_name Game
## Represents a parsed playable game. This contains everything the game needs to
## run.

var field_of_view: FieldOfView = FieldOfView.new()

## Just file/string JSON parsed to a Dictionary.
var raw_data: Dictionary

var layers: LayerList = LayerList.new()
var layer: Layer:
	get():
		return layers.get_current_layer()
	set(new_layer):
		pass

var player: Player = Player.new()
## Dictionary of game textures.
var textures: TextureList = TextureList.new()
## Dictionary of presets of tiles
var tiles_presets: TilePresetList = TilePresetList.new()

var turn: int = 0:
	set(new_turn):
		layers.get_current_layer().entities.alert_entities_new_turn(turn, new_turn)
		Globals.game_ui.turn_value_label.text = str(new_turn)
		turn = new_turn
	
@onready var tile_painter: TilePainter = TilePainter.new()


func _ready() -> void:
	field_of_view.name = "FieldOfView"
	add_child(field_of_view)
	tile_painter.name = "TilePainter"
	add_child(tile_painter)
	layers.name = "Layers"
	add_child(layers)

	## Add player
	player.name = "Player"
	add_child(player)
	player.tile_grid_position_change.connect(Globals.game_ui.debug_ui._on_player_change_grid_position)
	player.grid_position = player.grid_position


## Set a tile by a preset. [br]
## If preset == "", nothing happens.
func set_tile_by_preset(
	preset_key: String,
	pos: Vector2i,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	if preset_key == "":
		return

	var tile: Tile

	if set_tile_mode == Globals.SetTileMode.OVERRIDE_ONLY_WITH_COLLISION:
		var current_tiles: Array[Tile] = get_tiles(pos)
		## There are no tiles with has_collision == true.
		if not Utils.any_of_array_has_propriety_with_value(current_tiles, "has_collision", true):
			return
	
	if set_tile_mode == Globals.SetTileMode.OVERRIDE_ONLY_WITH_NOT_COLLISION:
		var current_tiles: Array[Tile] = get_tiles(pos)
		## There are no tiles with has_collision == false.
		if not Utils.any_of_array_has_propriety_with_value(current_tiles, "has_collision", false):
			return
	
	tile = Tile.from_tile_preset(preset_key)
	tile.grid_position = pos
	layers.get_current_layer().tiles.set_tile(tile)


## Return tiles from current layer on pos
func get_tiles(pos: Vector2i) -> Array[Tile]:
	return layers.get_current_layer().get_tiles(pos)

################################################################################
# Serialization
################################################################################

## Load object property from `dict` parameter. 
func load(data: Dictionary) -> void:
	raw_data = data

	for value in [["textures", textures], ["tiles_presets", tiles_presets], ["layer_list", layers], ["player", player]]:
		var key = value[0]
		var object = value[1]

		if data.has(key):
			object.load(data[key])
		else:
			Utils.print_warning("Game data is missing a %s information." % key)


	Utils.copy_from_dict_if_exists(
		self,
		data,
		["turn"],
		["turn"]
	)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()
	return result
