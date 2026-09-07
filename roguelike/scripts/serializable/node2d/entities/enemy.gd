extends Entity
class_name Enemy

var enemy_mode: Globals.EnemyMode = Globals.EnemyMode.ENEMY_WANDERING

var available_turns: int = 0

var thread: int = 1:
	set(new_thread):
		thread = clampi(new_thread, 1, 10)

var weight: int = 1:
	set(new_weight):
		weight = clampi(new_weight, 1, 10)

func _init():
	super._init(true, 0)

	has_collision = true
	is_transparent = false
	z_index = 1
	z_as_relative = false

func _ready():
	super._ready()
	visible = is_in_view
		

func _on_field_of_view_enter() -> void:
	super._on_field_of_view_enter()
	visible = true
	enemy_mode = Globals.EnemyMode.ENEMY_CHASING


func _on_field_of_view_exit() -> void:
	super._on_field_of_view_exit()
	visible = false


func _on_turn_updated(old_turn: int, new_turn: int) -> void:
	available_turns += new_turn - old_turn

	while available_turns > turns_to_move:
		if enemy_mode == Globals.EnemyMode.ENEMY_WANDERING:
			move_to(self.grid_position + Utils.get_random_direction())
		elif enemy_mode == Globals.EnemyMode.ENEMY_CHASING:
			var astar_grid: AStarGrid2D = Globals.game.layers.get_current_layer().astar_grid
			var player: Player = Globals.game.player
			var path: PackedVector2Array = astar_grid.get_point_path(grid_position, player.grid_position)

			if len(path) == 2:
				Globals.game.player.get_hit(self , get_melee_damage())
			else:
				step(Globals.game.player.grid_position)
				player.update_fov()

		available_turns -= turns_to_move


## Using A*, step 1 tile to de target position.
func step(target_position: Vector2i) -> void:
	var current_layer = Globals.game.layers.get_current_layer()
	var path: PackedVector2Array = current_layer.astar_grid.get_point_path(grid_position, target_position)

	if len(path) > 1:
		move_to(path[1])


# Move to position if possible.
func move_to(pos: Vector2i) -> void:
	var current_layer = Globals.game.layers.get_current_layer()
	if current_layer.can_move_to_position(pos):
		# Update entities dictionary
		current_layer.entities.entities.erase(Utils.vector2i_to_string(grid_position))
		current_layer.entities.entities[Utils.vector2i_to_string(pos)] = self

		grid_position = pos


func copy(enemy) -> void:
	super.copy(enemy)

	enemy_mode = enemy.enemy_mode
	thread = enemy.thread
	weight = enemy.weight


static func clone(entity) -> Variant:
	var result_enemy = Enemy.new()
	result_enemy.copy(entity)

	return result_enemy


func get_info() -> String:
	var info: String = super.get_info()

	info = Utils.append_info_line(info, {
		"Thread": str(thread),
		"Weight": str(weight)
	})

	return info
	
################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)

	Utils.copy_from_dict_if_exists(
		self ,
		data,
		[
			"thread",
			"weight"
		]
	)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()

	result["thread"] = thread
	result["weight"] = weight
	result["type"] = "enemy"

	return result
