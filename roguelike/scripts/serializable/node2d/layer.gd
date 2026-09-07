extends SerializableNode2D
class_name Layer
## Represents a Game layer, contais the tiles and entities.

var astar_grid: AStarGrid2D = AStarGrid2D.new()

var tiles: TileList = TileList.new(self)
var entities: EntityList = EntityList.new(self)
var items: ItemsList = ItemsList.new(self)

var layer_name: String

var rooms: Array[Rect2i]
var dungeon_level: DungeonLevel

func _init():
	astar_grid.region = Globals.astar_grid_region
	astar_grid.update()
	z_index = -1


## Return all tiles of a grid_position. Including basic tiles and entity tiles.
func get_tiles(pos: Vector2i) -> Array[Tile]:
	var tiles_arr: Array[Tile] = []

	var tile: Variant = tiles.get_tile(pos) as Tile
	var entity: Variant = entities.get_entity(pos) as Entity
	var item: Variant = items.get_item(pos) as Item

	if is_instance_valid(entity):
		tiles_arr.push_back(entity)

	if is_instance_valid(item):
		tiles_arr.push_back(item)

	if is_instance_valid(tile):
		tiles_arr.push_back(tile)


	return tiles_arr


## Return if it's possible to move to pos.
func can_move_to_position(pos: Vector2i) -> bool:
	var pos_tiles: Array[Tile] = get_tiles(pos)
	return not Utils.any_of_array_has_propriety_with_value(pos_tiles, "has_collision", true)

func position_has_only_floor(pos: Vector2i) -> bool:
	var current_tiles: Array[Tile] = get_tiles(pos)

	if len(current_tiles) == 0:
		return false

	for tile in current_tiles:
		if tile is Item or tile is Entity:
			return false
		if tile is Tile and tile.has_collision:
			return false
	
	return true

func find_random_free_space_on_room(room: Rect2i) -> Vector2i:
	var it = 0

	var pos = Utils.get_random_point_in_rect(room)
	while not position_has_only_floor(pos) and it < 100:
		pos = Utils.get_random_point_in_rect(room)
		it += 1
	return pos

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)
	
	astar_grid.update()

	tiles.load(data["tiles"])
	tiles.name = "Tiles"
	add_child(tiles)
	move_child(tiles, 0)

	entities.load(data["entities"])
	entities.name = "Entities"
	add_child(entities)
	move_child(entities, 1)

	items.load(data["items"])
	items.name = "Items"
	add_child(items)
	move_child(items, 2)

	for room in data["rooms"]:
		rooms.append(Utils.string_to_rect2i(room))
	

func serialize() -> Dictionary:
	var rooms_serialized: Array[String]

	for room in rooms:
		rooms_serialized.append(Utils.rect2i_to_string(room))

	var result: Dictionary = {
		"tiles": tiles.serialize(),
		"entities": entities.serialize(),
		"items": items.serialize(),
		"rooms": rooms_serialized
	}
	return result
