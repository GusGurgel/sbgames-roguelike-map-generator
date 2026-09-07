extends Node

################################################################################
# Godot
################################################################################

func _ready():
	blank_atlas_texture.region = Rect2(
		48 * Globals.tile_size.x,
		0 * Globals.tile_size.y,
		Globals.tile_size.x,
		Globals.tile_size.y
	)
	blank_atlas_texture.atlas = monochrome_texture
	rng.randomize()

################################################################################
# Tiles
################################################################################
var tileset_size: Vector2i = Vector2i(784, 352)
var tile_size: Vector2i = Vector2i(16, 16)
var tileset_count: Vector2i = tileset_size / tile_size
var default_texture: Vector2i = Vector2i(21, 9)
var blank_atlas_texture: AtlasTexture = AtlasTexture.new()

################################################################################
# Enums
################################################################################

enum SetTileMode {
	OVERRIDE_ALL,
	OVERRIDE_ONLY_WITH_COLLISION,
	OVERRIDE_ONLY_WITH_NOT_COLLISION
}

enum EntityType {
	ENTITY,
	ENEMY
}

enum EnemyMode {
	ENEMY_WANDERING,
	ENEMY_CHASING
}

enum ItemType {
	ITEM,
	HEALING_POTION,
	MELEE_WEAPON,
	RANGE_WEAPON
}

################################################################################
# Preloads
################################################################################

var colored_texture: CompressedTexture2D = preload(
	"res://images/tileset_colored.png"
)
var monochrome_texture: CompressedTexture2D = preload(
	"res://images/tileset_monochrome.png"
)

var scenes: Dictionary[String, PackedScene] = {
}

################################################################################
# ReGex
################################################################################

var vector2i_string_regex: RegEx = RegEx.create_from_string(
	"^(-?\\d+),(-?\\d+)$"
)
var rect2i_string_regex: RegEx = RegEx.create_from_string(
	"^(-?\\d+),(-?\\d+),(-?\\d+),(-?\\d+)$"
)
var hex_color_regex: RegEx = RegEx.create_from_string(
	"^#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})$"
)

################################################################################
# Configurations
################################################################################

var player_config: Dictionary = {
	"level_up_experience_base": 100,
	"level_up_experience_increase_per_level": 0.2,
	"mana_base": 15,
	"mana_gain_per_level": 0.2,
	"health_base": 20,
	"health_gain_per_level": 0.2,
	"damage_multiplier_increase_per_level": 0.1,
	"base_melee_damage": 10
}

var melee_weapons_configuration: Dictionary = {
	"damage_base": 10,
	"damage_multiplier_by_rarity": 0.1,
	"damage_multiplier_by_weight": 0.1,
	"damage_max": 200,

	"turns_to_use_base": 1,
	"turns_to_use_multiplier_by_weight": 0.1,
	"turns_to_user_max": 10
}

var range_weapons_configuration: Dictionary = {
	"damage_base": 10,
	"damage_multiplier_by_rarity": 0.1,
	"damage_multiplier_by_mana_cost": 0.1,
	"damage_max": 200,

	"mana_cost_base": 10,
	"mana_cost_multiplier_by_mana_cost": 0.1,
	"mana_cost_max": 100
}

var enemies_configuration: Dictionary = {
	"health_base": 30,
	"health_multiplier_by_thread": 0.1,
	"health_max": 300,

	"damage_base": 5,
	"damage_multiplier_by_thread": 0.1,
	"damage_multiplier_by_weight": 0.1,
	"damage_max": 100,

	"experience_base": 5,
	"experience_multiplier_by_thread": 0.1,
	"experience_multiplier_by_weight": 0.1,
	"experience_max": 100,

	"turns_to_move_base": 1,
	"turns_to_move_multiplier_by_weight": 0.1,
	"turns_to_move_max": 10
}

################################################################################
# Globals
################################################################################

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var tile_preset_list: TilePresetList = TilePresetList.new()

var game: Game = null
var game_ui: GameUI = null
var game_data: Dictionary = {}

var astar_grid_region = Rect2i(Vector2i(-100, -100), Vector2i(300, 300))

var game_viewport_rect = Rect2i(Vector2i.ZERO, Vector2i(800, 357))

var verbose_tile_info = true

var player_defaults = {
	"is_in_view" = true,
	"is_transparent" = true,
	"is_explored" = true,
	"turns_to_move" = 1,
	"heal_per_turns" = 1,
	"regen_per_turns" = 1,
	"experience" = 0,
	"base_damage" = 10
}

var wall_tile_defaults = {
	"is_in_view" = false,
	"is_transparent" = false,
	"is_explored" = false,
	"has_collision" = true
}

var floor_tile_defaults = {
	"is_in_view" = false,
	"is_transparent" = true,
	"is_explored" = false,
	"has_collision" = false
}

var healing_potion_defaults = {
	"tileset_position": {
		"x": 33,
		"y": 13
	},
	"tile_name": "Healing Potion",
	"tile_description": "A potion that's heal 20 points of health",
	"health_increase": 20,
	"tile_hex_color": "#dc3545"
}