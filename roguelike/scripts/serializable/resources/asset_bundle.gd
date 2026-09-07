extends SerializableResource
class_name AssetBundle

## User description
var raw_description: String = ""

## LLM Enhanced theme description
var description: String = ""

var player_asset: Player = Player.new()

var textures: Dictionary[String, Dictionary] = {}

var dungeon_levels: Array[DungeonLevel] = []

var tile_preset_list: TilePresetList = TilePresetList.new()

var layers: LayerList = LayerList.new()

var melee_weapons_assets: Array[MeleeWeapon]
var range_weapons_assets: Array[RangeWeapon]
var enemies_assets: Array[Enemy]
var healing_potion_asset: HealingPotion = HealingPotion.new()


func add_texture(tile_data: Dictionary) -> String:
	var name = "%s_%d" % [tile_data["name"], int(Time.get_unix_time_from_system() + len(textures))]

	var x: int = clampi(tile_data["texture"]["tileset_position"]["x"], 0, Globals.tileset_count.x)
	var y: int = clampi(tile_data["texture"]["tileset_position"]["y"], 0, Globals.tileset_count.y)

	textures[name] = {
		"x": x,
		"y": y
	}

	return name


func add_tile_preset(tile: Tile) -> String:
	var name = "%s_%d" % [tile.tile_name, int(Time.get_unix_time_from_system() + len(tile_preset_list.tiles_presets))]

	tile_preset_list.tiles_presets[name] = tile

	return name


################################################################################
# Serialization
################################################################################

func load_player(data: Dictionary) -> void:
	player_asset.tile_name = data["tile"]["name"]
	player_asset.tile_description = data["tile"]["description"]
	var texture_name: String = add_texture(data["tile_with_texture"])
	player_asset.tile_color_hex = data["tile_with_texture"]["color"]
	player_asset.texture_name = texture_name

	player_asset.back_history = data["back_history"]

	Utils.copy_from_dict_if_exists(
		player_asset,
		Globals.player_defaults,
		Globals.player_defaults.keys()
	)


func load_dungeon_levels(data: Array) -> void:
	for dungeon_level_data in data:
		var dungeon_level = DungeonLevel.new()

		var wall_tile = Tile.new()
		Utils.copy_from_dict_if_exists(
			wall_tile,
			Globals.wall_tile_defaults,
			Globals.wall_tile_defaults.keys()
		)
		wall_tile.tile_description = dungeon_level_data["wall_tile_with_texture"]["description"]
		wall_tile.tile_name = dungeon_level_data["wall_tile_with_texture"]["name"]
		wall_tile.tile_color_hex = dungeon_level_data["wall_tile_with_texture"]["color"]
		wall_tile.texture_name = add_texture(
			dungeon_level_data["wall_tile_with_texture"]
		)

		var floor_tile = Tile.new()
		Utils.copy_from_dict_if_exists(
			floor_tile,
			Globals.floor_tile_defaults,
			Globals.floor_tile_defaults.keys()
		)
		floor_tile.tile_description = dungeon_level_data["floor_tile_with_texture"]["description"]
		floor_tile.tile_name = dungeon_level_data["floor_tile_with_texture"]["name"]
		floor_tile.tile_color_hex = dungeon_level_data["floor_tile_with_texture"]["color"]
		floor_tile.texture_name = add_texture(
			dungeon_level_data["floor_tile_with_texture"],
		)


		Utils.copy_from_dict_if_exists(
			dungeon_level,
			dungeon_level_data,
			[
				"depth",
				"name",
				"description"
			]
		)


		dungeon_level.wall_tile_preset = add_tile_preset(wall_tile)
		dungeon_level.floor_tile_preset = add_tile_preset(floor_tile)

		dungeon_levels.append(dungeon_level)


func load_weapons(weapons_data: Array) -> void:
	for weapon_data in weapons_data:
		var weapon: Item

		if weapon_data["weapon_type"] == "melee":
			weapon = MeleeWeapon.new()
			weapon.weight = weapon_data["weight"]
			weapon.damage = clamp(
				Globals.melee_weapons_configuration["damage_base"] * \
				(pow(1 + Globals.melee_weapons_configuration["damage_multiplier_by_rarity"], weapon_data["rarity"]) + \
				pow(1 + Globals.melee_weapons_configuration["damage_multiplier_by_weight"], weapon_data["weight"])),
				1,
				Globals.melee_weapons_configuration["damage_max"]
			)

			weapon.turns_to_use = clampi(
				Globals.melee_weapons_configuration["turns_to_use_base"] * \
				pow(1 + Globals.melee_weapons_configuration["turns_to_use_base"], weapon_data["weight"]),
				1,
				Globals.melee_weapons_configuration["turns_to_user_max"]
			)
			melee_weapons_assets.append(weapon)

		elif weapon_data["weapon_type"] == "range":
			weapon = RangeWeapon.new()
			weapon.damage = clampi(
				Globals.range_weapons_configuration["damage_base"] * \
				(pow(1 + Globals.range_weapons_configuration["damage_multiplier_by_rarity"], weapon_data["rarity"]) + \
				pow(1 + Globals.range_weapons_configuration["damage_multiplier_by_mana_cost"], weapon_data["mana_cost"])),
				1,
				Globals.range_weapons_configuration["damage_max"]
			)

			weapon.mana_cost = clampi(
				Globals.range_weapons_configuration["mana_cost_base"] * \
				pow(1 + Globals.range_weapons_configuration["mana_cost_multiplier_by_mana_cost"], weapon_data["mana_cost"]),
				1,
				Globals.range_weapons_configuration["mana_cost_max"]
			)
			range_weapons_assets.append(weapon)
		
		weapon.rarity = weapon_data["rarity"]
		weapon.tile_description = weapon_data["tile_with_texture"]["description"]
		weapon.tile_name = weapon_data["tile_with_texture"]["name"]
		weapon.tile_color_hex = weapon_data["tile_with_texture"]["color"]
		weapon.texture_name = add_texture(
			weapon_data["tile_with_texture"],
		)


func load_enemies(enemies_data: Array) -> void:
	for enemy_data in enemies_data:
		var enemy: Enemy = Enemy.new()

		enemy.max_health = clampi(
			Globals.enemies_configuration["health_base"] * \
			pow(1 + Globals.enemies_configuration["health_multiplier_by_thread"], enemy_data["thread"]),
			1,
			Globals.enemies_configuration["health_max"]
		)
		enemy.health = enemy.max_health

		enemy.turns_to_move = clampi(
			Globals.enemies_configuration["turns_to_move_base"] * \
			pow(1 + Globals.enemies_configuration["turns_to_move_multiplier_by_weight"], enemy_data["weight"]),
			1,
			Globals.enemies_configuration["turns_to_move_max"]
		)


		enemy.base_damage = clampi(
			Globals.enemies_configuration["damage_base"] * \
			pow(1 + Globals.enemies_configuration["damage_multiplier_by_thread"], enemy_data["thread"]) + \
			pow(1 + Globals.enemies_configuration["damage_multiplier_by_weight"], enemy_data["weight"]),
			1,
			Globals.enemies_configuration["damage_max"]
		)

		enemy.experience_to_give = clampi(
			Globals.enemies_configuration["experience_base"] * \
			pow(1 + Globals.enemies_configuration["experience_multiplier_by_thread"], enemy_data["thread"]) + \
			pow(1 + Globals.enemies_configuration["experience_multiplier_by_weight"], enemy_data["weight"]),
			1,
			Globals.enemies_configuration["experience_max"]
		)

		enemy.thread = enemy_data["thread"]
		enemy.weight = enemy_data["weight"]
		enemy.tile_description = enemy_data["tile_with_texture"]["description"]
		enemy.tile_name = enemy_data["tile_with_texture"]["name"]
		enemy.tile_color_hex = enemy_data["tile_with_texture"]["color"]
		enemy.texture_name = add_texture(
			enemy_data["tile_with_texture"],
		)

		enemies_assets.append(enemy)


func get_weight_array_by_level_index(vals: Array, index: float, max_index: float) -> Array:
	var vals_float: Array = vals.map(func(val):
		if "rarity" in val:
			return val.rarity
		elif "thread" in val:
			return val.thread
		else:
			return 0
	)
	var min_val: float = vals_float.min()
	var max_val: float = vals_float.max()

	var factor: float = index / max_index

	return vals_float.map(func(val):
		var target: float = (min_val + max_val) - val
		return clamp(11 - round(val + (target - val) * factor), 1, 10)
	)


func generate_layer_list() -> void:
	for level in dungeon_levels:
		var layer = Layer.new()
		layer.dungeon_level = level
		layer.rooms = layer.tiles.generate_basic_dungeon(
			Rect2i(0, 0, 50, 50),
			10,
			10,
			10,
			level.wall_tile_preset,
			level.floor_tile_preset
		)

		var level_index: int = len(layers.layers_keys_ordered)
		var level_max_index = len(dungeon_levels)

		var range_weapons_weight = get_weight_array_by_level_index(range_weapons_assets, level_index, level_max_index)
		var melee_weapons_weight = get_weight_array_by_level_index(melee_weapons_assets, level_index, level_max_index)
		var enemies_weight = get_weight_array_by_level_index(enemies_assets, level_index, level_max_index)


		for room in layer.rooms:
			# Add a weapon
			if Globals.rng.randi_range(0, 1) == 1:
				if Globals.rng.randi_range(0, 1) == 1:
					# Add a melee_weapon
					layer.items.add_item(layer.find_random_free_space_on_room(room), melee_weapons_assets[Globals.rng.rand_weighted(melee_weapons_weight)])
				else:
					# Add a range_weapon
					layer.items.add_item(layer.find_random_free_space_on_room(room), range_weapons_assets[Globals.rng.rand_weighted(range_weapons_weight)])

			# Add a enemy
			if Globals.rng.randi_range(0, 1) == 1:
				layer.entities.add_entity(layer.find_random_free_space_on_room(room), enemies_assets[Globals.rng.rand_weighted(enemies_weight)])

			# Add a healing potion
			if Globals.rng.randi_range(0, 1) == 1:
				layer.items.add_item(layer.find_random_free_space_on_room(room), healing_potion_asset)

		layers.layers[level.name] = layer
		layers.layers_keys_ordered.append(level.name)

	layers.current_layer_key = layers.layers_keys_ordered[0]

	player_asset.grid_position = layers.get_current_layer().rooms[0].get_center()


func load_healing_potion() -> void:
	healing_potion_asset.texture_name = add_texture({
		"name": Globals.healing_potion_defaults["tile_name"],
		"texture": {
			"tileset_position": Globals.healing_potion_defaults["tileset_position"]
		}
	})
	healing_potion_asset.tile_name = Globals.healing_potion_defaults["tile_name"]
	healing_potion_asset.tile_description = Globals.healing_potion_defaults["tile_description"]
	healing_potion_asset.health_increase = Globals.healing_potion_defaults["health_increase"]
	healing_potion_asset.tile_color_hex = Globals.healing_potion_defaults["tile_hex_color"]


## Return a complete random generated game based on the asset_bundle
func generate_json_game() -> Dictionary:
	return {
		"layer_list": layers.serialize(),
		"player": player_asset.serialize(),
		"textures": textures,
		"tiles_presets": tile_preset_list.serialize(),
		"turn": 0
	}


func load(data: Dictionary) -> void:
	Globals.tile_preset_list = tile_preset_list

	# Adding the default tile
	textures["default"] = {
		"x": Globals.default_texture.x,
		"y": Globals.default_texture.y
	}

	var default_tile = Tile.new()
	default_tile.tile_color_hex = "#c711f0"
	default_tile.texture_name = "default"
	default_tile.tile_name = "default"
	default_tile.tile_description = "..."
	default_tile.has_collision = false
	default_tile.is_transparent = true
	tile_preset_list.tiles_presets["default"] = default_tile

	load_player(data["player"])

	load_dungeon_levels(data["dungeon_levels"]["items"])

	load_weapons(data["weapons"]["items"])

	load_enemies(data["enemies"]["items"])

	load_healing_potion()

	generate_layer_list()

	Utils.copy_from_dict_if_exists(
		self,
		data,
		[
			"description",
			"raw_description"
		]
	)

	super.load(data)


func serialize() -> Dictionary:
	var result: Dictionary = {}
	return result
