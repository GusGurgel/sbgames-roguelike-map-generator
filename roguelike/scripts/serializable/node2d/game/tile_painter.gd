extends Node
class_name TilePainter
## Used to paint forms like circles, rects, lines on the game tile layer


@export var game: Game


func _ready():
	pass

## Set a rectangle of tiles. [br][br]
##
## - Set fill_tile_key = "" to make a empty rect with borders[br]
## - Set border_tile_key = "" and fill_tile_key = "" to erase cells [br]
func set_rect(
	rect: Rect2i,
	border_tile_key: String,
	fill_tile_key: String = "",
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	set_rect_random(rect, [border_tile_key], [fill_tile_key], set_tile_mode)


## Set a rectangle of tiles. Tiles are chosen randomly. [br][br]
##
## - Set fill_tile_key = [""[] to make a empty rect with borders[br]
## - Set border_tile_key = [""] and fill_tile_key = [""] to erase cells
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
				game.layers.get_current_layer().tiles.erase_tile(Vector2i(x, y))
				continue


			if Utils.is_border(rect, Vector2i(x, y)):
				if len(border_tiles) == 1:
					game.set_tile_by_preset(border_tiles[0], Vector2i(x, y), set_tile_mode)
				else:
					game.set_tile_by_preset(border_tiles.pick_random(), Vector2i(x, y), set_tile_mode)
			elif len(fill_tiles) >= 1:
				if len(fill_tiles) == 1:
					game.set_tile_by_preset(fill_tiles[0], Vector2i(x, y), set_tile_mode)
				else:
					game.set_tile_by_preset(fill_tiles.pick_random(), Vector2i(x, y), set_tile_mode)


## Utility function for the set_circle function.
func _select_symmetry(
	x: int,
	y: int,
	x0: int,
	y0: int,
	tile_preset_key: String,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	game.set_tile_by_preset(tile_preset_key, Vector2i(x + x0, y + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(-x + x0, y + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(x + x0, -y + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(-x + x0, -y + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(y + x0, x + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(-y + x0, x + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(y + x0, -x + y0), set_tile_mode)
	game.set_tile_by_preset(tile_preset_key, Vector2i(-y + x0, -x + y0), set_tile_mode)


## Set a bordered circle of tiles
func set_circle_with_bordes(
	coords: Vector2i,
	radius: int,
	border_tile_key: String,
	fill_tile_key: String = "",
	border_width: int = 1,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	border_width = clamp(border_width, 0, radius)
	if fill_tile_key != "":
		set_circle_without_borders(coords, radius, border_tile_key, true, set_tile_mode)
		set_circle_without_borders(coords, radius - border_width, fill_tile_key, true, set_tile_mode)
	else:
		set_circle_without_borders(coords, radius, border_tile_key, false, set_tile_mode)


## Set a circle of tiles
func set_circle_without_borders(
	coords: Vector2i,
	radius: int,
	tile_key: String,
	fill: bool = true,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	var x: int = 0
	var y: int = radius
	var d: float = 5 / 4.0 - radius

	if fill:
		for ty in range(y, x - 1, -1):
			_select_symmetry(x, ty, coords.x, coords.y, tile_key, set_tile_mode)
	else:
		_select_symmetry(x, y, coords.x, coords.y, tile_key, set_tile_mode)
	while x < y:
		x += 1
		if d < 0:
			d += 2 * x + 1
		else:
			y -= 1
			d += 2 * (x - y) + 1
		if fill:
			for ty in range(y, x - 1, -1):
				_select_symmetry(x, ty, coords.x, coords.y, tile_key, set_tile_mode)
		else:
			_select_symmetry(x, y, coords.x, coords.y, tile_key, set_tile_mode)


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
						game.set_tile_by_preset(tile_key, tile_pos, set_tile_mode)
					else:
						game.layers.get_current_layer().tiles.erase_tile(tile_pos)


# ## Draw a filled polygon from a list of points.
func set_polygon_filled(
	points: Array[Vector2i],
	tile_key: String,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	if points.size() < 3:
		printerr("Um polígono precisa de pelo menos 3 pontos.")
		return

	var min_y = points[0].y
	var max_y = points[0].y
	for p in points:
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	for y in range(min_y, max_y + 1):
		var intersections = []
		for i in range(points.size()):
			var p1 = points[i]
			var p2 = points[(i + 1) % points.size()]

			if (p1.y < y and p2.y >= y) or (p2.y < y and p1.y >= y):
				var intersect_x = p1.x + (y - p1.y) / float(p2.y - p1.y) * (p2.x - p1.x)
				intersections.append(intersect_x)

		intersections.sort()

		for i in range(0, intersections.size(), 2):
			if i + 1 < intersections.size():
				var x_start = ceili(intersections[i])
				var x_end = floori(intersections[i + 1])
				for x in range(x_start, x_end + 1):
					game.set_tile_by_preset(tile_key, Vector2i(x, y), set_tile_mode)


func set_polygon_bordered(
	points: Array[Vector2i],
	border_tile_key: String,
	fill_tile_key: String = "",
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	if points.size() < 3:
		printerr("Um polígono precisa de pelo menos 3 pontos.")
		return

	if fill_tile_key != "":
		set_polygon_filled(points, fill_tile_key, set_tile_mode)

	for i in range(points.size()):
		var current_point = points[i]
		var next_point = points[(i + 1) % points.size()]
		_draw_thin_line(current_point, next_point, border_tile_key, set_tile_mode)


## Auxiliary function for drawing a tile line between two points.
## It uses Bresenham's algorithm.
func _draw_thin_line(
	p1: Vector2i,
	p2: Vector2i,
	tile_key: String,
	set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ALL
) -> void:
	var x = p1.x
	var y = p1.y
	var dx = abs(p2.x - x)
	var dy = - abs(p2.y - y)
	var sx = 1 if x < p2.x else -1
	var sy = 1 if y < p2.y else -1
	var err = dx + dy

	while true:
		game.set_tile_by_preset(tile_key, Vector2i(x, y), set_tile_mode)
		if x == p2.x and y == p2.y:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


# Create a path between a list o points
func set_path(
	path: Array[Vector2i],
	border_tile: String,
	fill_tile: String = "",
	thickness: int = 5,
	border_width: int = 3,
) -> void:
	var set_tile_mode: Globals.SetTileMode = Globals.SetTileMode.OVERRIDE_ONLY_WITH_COLLISION

	if len(path) <= 1:
		printerr("g_tile_map_layer.gd: setting a path with 1 or less path")
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
	max_room_size: int,
	min_room_size: int,
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
