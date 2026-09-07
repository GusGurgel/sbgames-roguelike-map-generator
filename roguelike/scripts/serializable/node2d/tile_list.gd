extends SerializableNode2D
class_name TileList

var tiles: Dictionary[String, Tile]
var layer: Layer


func _init(_layer: Layer):
	layer = _layer


func get_tile(pos: Vector2i) -> Tile:
	return tiles.get(Utils.vector2i_to_string(pos))


func set_tile(tile: Tile) -> void:
	var pos_key: String = Utils.vector2i_to_string(tile.grid_position)

	if tiles.has(pos_key):
		erase_tile(tile.grid_position)
	tiles[pos_key] = tile

	## Add tile or reparent to the current layer.
	if tile.get_parent():
		tile.reparent(self)
	else:
		add_child(tile)


	layer.astar_grid.set_point_solid(tile.grid_position, tile.has_collision)


func erase_tile(pos: Vector2i) -> bool:
	var pos_key: String = Utils.vector2i_to_string(pos)

	if tiles.has(pos_key):
		tiles[pos_key].queue_free()
		tiles.erase(pos_key)
		layer.astar_grid.set_point_solid(pos, false)
		return true
	else:
		return false

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)
	
	for tile_key in data:
		var tile: Tile = Tile.new()
		var tile_data: Dictionary = data[tile_key]
		var grid_position: Vector2i = Utils.string_to_vector2i(tile_key)
		tile_data["grid_position"] = {
			x = grid_position.x,
			y = grid_position.y
		}
		tile.load(tile_data)
		set_tile(tile)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	for tile_key in tiles:
		result[tile_key] = tiles[tile_key].serialize()

	return result

################################################################################
# Painting
################################################################################

func set_tile_by_preset(
	preset_key: String,
	pos: Vector2i,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	if not Globals.tile_preset_list.tiles_presets.has(preset_key):
		Utils.print_warning("Tile preset '%s' won't exists." % preset_key)

	var current_tile = get_tile(pos)
	if current_tile != null:
		if current_tile.has_collision \
		and set_tile_mode == Globals.SetTileMode.OVERRIDE_ONLY_WITH_NOT_COLLISION:
			return

		if not current_tile.has_collision \
		and set_tile_mode == Globals.SetTileMode.OVERRIDE_ONLY_WITH_COLLISION:
			return

		erase_tile(pos)
	
	var tile: Tile = Tile.from_tile_preset(preset_key)
	tile.grid_position = pos
	set_tile(tile)


## Set a rectangle of tiles. [br][br]
func set_rect(
	rect: Rect2i,
	border_tile_key: String,
	fill_tile_key: String = "",
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	set_rect_random(rect, [border_tile_key], [fill_tile_key], set_tile_mode)


## Set a rectangle of tiles. Tiles are chosen randomly. [br][br]
func set_rect_random(
	rect: Rect2i,
	border_tiles: Array[String],
	fill_tiles: Array[String] = [],
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	if len(border_tiles) == 0:
		Utils.print_warning("g_tile_map_layer.gd: setting a rect with no border_tiles")
		border_tiles.append("default")

	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			## Routine of erase rectangle
			if len(border_tiles) == 1 and border_tiles[0] == "" \
			and len(fill_tiles) == 1 and fill_tiles[0] == "":
				erase_tile(Vector2i(x, y))
				continue


			if Utils.is_border(rect, Vector2i(x, y)):
				if len(border_tiles) == 1:
					set_tile_by_preset(border_tiles[0], Vector2i(x, y), set_tile_mode)
				else:
					set_tile_by_preset(border_tiles.pick_random(), Vector2i(x, y), set_tile_mode)
			elif len(fill_tiles) >= 1:
				if len(fill_tiles) == 1:
					set_tile_by_preset(fill_tiles[0], Vector2i(x, y), set_tile_mode)
				else:
					set_tile_by_preset(fill_tiles.pick_random(), Vector2i(x, y), set_tile_mode)

## Create a line of tiles going from start_pos to end_pos with the specified
## thickness.
func set_line_without_borders(
	start_pos: Vector2i,
	end_pos: Vector2i,
	tile_key: String,
	thickness: int = 1,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	# This function use circles to draw a line
	var diff: Vector2 = end_pos - start_pos
	var line_length: float = diff.length()

	if is_equal_approx(line_length, 0):
		return

	var direction: Vector2 = diff.normalized()
	var radius: float = thickness / 2.0

	for i in range(int(line_length) + 1):
		var current_pos: Vector2 = Vector2(start_pos) + direction * i

		for y in range(-int(radius), int(radius) + 1):
			for x in range(-int(radius), int(radius) + 1):
				if Vector2(x, y).length_squared() <= radius * radius:
					var tile_pos = Vector2i(round(current_pos.x + x), round(current_pos.y + y))
					if tile_key != "":
						set_tile_by_preset(tile_key, tile_pos, set_tile_mode)
					else:
						erase_tile(tile_pos)

## Create a bordered line of tiles going from start_pos to end_pos with the
## specified thickness.
func set_line_with_borders(
	start_pos: Vector2i,
	end_pos: Vector2i,
	border_tile_key: String,
	fill_tile_key: String,
	thickness: int = 2,
	border_width: int = 1,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	thickness = clamp(thickness, 2, thickness)
	border_width = clamp(border_width, 1, thickness - 1)

	set_line_without_borders(start_pos, end_pos, border_tile_key, thickness, set_tile_mode)
	set_line_without_borders(
		start_pos, end_pos, fill_tile_key, thickness - border_width, set_tile_mode
	)

func set_path(
	path: Array[Vector2i],
	border_tile: String,
	fill_tile: String = "",
	thickness: int = 5,
	border_width: int = 3,
) -> void:
	var set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ONLY_WITH_COLLISION

	if len(path) <= 1:
		Utils.print_warning("setting a path with 1 or less path")
		return

	for i in range(1, len(path)):
		var start: Vector2i = path[i - 1]
		var end: Vector2i = path[i]
		set_line_with_borders(start, end, border_tile, fill_tile, thickness, border_width, set_tile_mode)


func connect_rects_by_l_shape_path(
	rect1: Rect2i,
	rect2: Rect2i,
	border_tile_key: String,
	fill_tile_key: String,
	thickness: int = 5,
	border_width: int = 3,
):
	var rect1_center: Vector2i = rect1.get_center()
	var rect2_center: Vector2i = rect2.get_center()

	var path: Array[Vector2i] = []

	if randi() % 2 == 1:
		path = [
			rect1_center,
			Vector2i(rect2_center.x, rect1_center.y),
			rect2_center
		]
	else:
		path = [
			rect1_center,
			Vector2i(rect1_center.x, rect2_center.y),
			rect2_center
		]

	set_path(path, border_tile_key, fill_tile_key, thickness, border_width)

## Draws a basic dungeon with rects and paths. Return the rects of the created
## rooms.
func generate_basic_dungeon(
	dungeon_rect: Rect2i,
	max_of_rooms: int,
	min_room_size: int,
	max_room_size: int,
	wall_tile_key: String,
	floor_tile_key: String
) -> Array[Rect2i]:
	var _rng := RandomNumberGenerator.new()
	
	# if dungeon_rect.size.x / min_room_size < max_room_size:
	# 	printerr("level_layer.gd: dungeon_rect.size.x is too small or max_room_size is too large")
	# 	return []

	var rooms: Array[Rect2i] = []
	
	for _i in range(max_of_rooms):
		var room_width: int = _rng.randi_range(min_room_size, max_room_size)
		var room_height: int = _rng.randi_range(min_room_size, max_room_size)
		
		var x: int = _rng.randi_range(0, dungeon_rect.size.x - room_width - 1)
		var y: int = _rng.randi_range(0, dungeon_rect.size.y - room_height - 1)

		var new_room: Rect2i = Rect2i(x, y, room_width, room_height)
		
		var has_intersections := false
		for room in rooms:
			if room.intersects(new_room.grow(-1)):
				has_intersections = true
				break
		if has_intersections:
			continue

		set_rect(new_room, wall_tile_key, floor_tile_key, Globals.SetTileMode.OVERRIDE_ONLY_WITH_COLLISION)
		
		if not rooms.is_empty():
			connect_rects_by_l_shape_path(
				rooms.back(),
				new_room,
				wall_tile_key,
				floor_tile_key
			)
		
		rooms.append(new_room)

	return rooms
