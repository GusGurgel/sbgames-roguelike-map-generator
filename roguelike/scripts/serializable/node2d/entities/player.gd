extends Entity
class_name Player


## Max camera zoom multiplier
@export var max_camera_zoom: int = 4

@export var heal_per_turns: int = 1
@export var regen_per_turns: int = 1

var camera: Camera2D = Camera2D.new()

var item_frame_scene = preload("res://scenes/ui/item_frame.tscn")

var melee_weapon: MeleeWeapon = null:
	set(new_melee_weapon):
		if new_melee_weapon != null:
			Globals.game_ui.melee_weapon_label.text = new_melee_weapon.tile_name
		else:
			Globals.game_ui.melee_weapon_label.text = "(None)"
		melee_weapon = new_melee_weapon

var range_weapon: RangeWeapon = null:
	set(new_range_weapon):
		if new_range_weapon != null:
			Globals.game_ui.range_weapon_label.text = new_range_weapon.tile_name
		else:
			Globals.game_ui.range_weapon_label.text = "(None)"
		range_weapon = new_range_weapon

var level: int = 0
var experience: int = 0
var damage_multiplier: float = 0
var back_history: String = ""

var mouse_grid_position: Vector2i = Vector2i.ZERO
var under_mouse_tile_info: String = ""

var description_frame: DescriptionFrame

func _init():
	super._init(true)

func _ready():
	super._ready()

	camera.name = "Camera"
	add_child(camera)

	## Player need to be transparent
	is_transparent = true

	camera.position += texture.get_size() / 2
	camera.zoom = Vector2.ONE * 2

	update_fov.call_deferred()

	# Call set methods to trigger UI update
	set_health(Globals.player_config["health_base"])
	set_max_health(Globals.player_config["health_base"])
	set_mana(Globals.player_config["mana_base"])
	set_max_mana(Globals.player_config["mana_base"])

	melee_weapon = melee_weapon
	range_weapon = range_weapon

	set_experience(experience)
	set_health(max_health)
	set_mana(max_mana)


func set_description_frame(_description_frame: DescriptionFrame) -> void:
	description_frame = _description_frame
	
	description_frame.name = "DescriptionFrame"
	description_frame.visible = false
	# description_frame.description_label.text = ""


func _process(_delta):
	var new_grid_mouse_position: Vector2i = \
	Utils.global_position_to_grid_position(get_local_mouse_position()) - Vector2i.ONE + grid_position
	var is_mouse_under_viewport: bool = Globals.game_viewport_rect.has_point(get_viewport().get_mouse_position())
	if is_mouse_under_viewport and mouse_grid_position != new_grid_mouse_position:
		mouse_grid_position = new_grid_mouse_position
	
	if is_mouse_under_viewport and Input.is_action_just_pressed("show_under_mouse_tile_info"):
		description_frame.visible = true
		var offset_x = 0

		if get_viewport().get_mouse_position().x > Globals.game_viewport_rect.size.x - description_frame.size.x:
			offset_x = - description_frame.size.x

		var new_position = get_viewport().get_mouse_position()
		new_position.x += offset_x
		description_frame.position = new_position

		description_frame.description_label.text = ""

		var tiles: Array[Tile] = Globals.game.layers.get_current_layer().get_tiles(mouse_grid_position)


		if len(tiles) >= 1:
			description_frame.description_label.text = tiles[0].get_info()
			
	if Input.is_action_just_released("show_under_mouse_tile_info"):
		description_frame.visible = false
	
	
func _unhandled_input(event: InputEvent) -> void:
	var event_key = event as InputEventKey

	if event_key:
		if event_key.is_pressed():
			_handle_movement(event_key)
			_handle_camera_zoom(event_key)
			_handle_grab_item(event_key)
			_handle_use_range_weapon(event_key)
			if event_key.is_action("wait"):
				pass_turns(1)


func _handle_use_range_weapon(event_key: InputEventKey) -> void:
	if event_key.is_action_pressed("use_range_weapon"):
		if range_weapon != null:
			var enemies_in_view = Globals.game.field_of_view.enemies_in_view
			var close_enemy: Enemy = null
			
			for enemy in enemies_in_view:
				if enemy != null and is_instance_valid(enemy):
					if close_enemy == null or (close_enemy.grid_position - grid_position) > (enemy.grid_position - grid_position):
						close_enemy = enemy
			
			if close_enemy != null:
				if mana >= range_weapon.mana_cost:
					set_mana(mana - range_weapon.mana_cost)
					pass_turns(turns_to_move)
					var is_enemy_dead: bool = close_enemy.get_hit(self , get_range_damage())
					if is_enemy_dead:
						Globals.game_ui.prompt_text(
							"[color=#88A8C5]%s[/color] kills [color=#d37073]%s[/color] using a %s." % \
							[tile_name, close_enemy.tile_name, range_weapon.tile_name]
						)
						set_experience(experience + close_enemy.experience_to_give)
					else:
						Globals.game_ui.prompt_text(
							"[color=#88A8C5]%s[/color] hits [color=#d37073]%s[/color] using a %s. (Damage: %d; %s Life: %d)." % \
							[
								tile_name,
								close_enemy.tile_name,
								range_weapon.tile_name,
								get_range_damage(),
								close_enemy.tile_name,
								close_enemy.health
							]
						)
				else:
					Globals.game_ui.prompt_text("Not enough mana to use %s" % range_weapon.tile_name)
			else:
				Globals.game_ui.prompt_text("No enemy nearby")

		else:
			Globals.game_ui.prompt_text("You won't have a range weapon!")

func _handle_use_melee_weapon(enemy: Enemy):
	var is_enemy_dead: bool = enemy.get_hit(self , get_melee_damage())
	var weapon_name: String = "Fists" if melee_weapon == null else melee_weapon.tile_name
	if is_enemy_dead:
		Globals.game_ui.prompt_text(
			"[color=#88A8C5]%s[/color] kills [color=#d37073]%s[/color] using %s." % \
			[tile_name, enemy.tile_name, weapon_name]
		)
		set_experience(experience + enemy.experience_to_give)
	else:
		Globals.game_ui.prompt_text(
			"[color=#88A8C5]%s[/color] hits [color=#d37073]%s[/color] using %s. (Damage: %d; %s Life: %d)." % \
			[
				tile_name,
				enemy.tile_name,
				weapon_name,
				get_melee_damage(),
				enemy.tile_name,
				enemy.health
			]
		)

func _handle_grab_item(event_key: InputEventKey) -> void:
	if event_key.is_action_pressed("grab"):
		var item = Globals.game.layers.get_current_layer().items.get_item(grid_position)
		if item:
			add_item_to_inventory(item)
		else:
			Globals.game_ui.prompt_text("No item to grab.")

				
func _handle_camera_zoom(event_key: InputEventKey) -> void:
	if event_key.is_action("zoom_plus"):
		camera.zoom = clamp(camera.zoom + Vector2.ONE, Vector2.ONE, Vector2.ONE * max_camera_zoom)
	elif event_key.is_action("zoom_minus"):
		camera.zoom = clamp(camera.zoom - Vector2.ONE, Vector2.ONE, Vector2.ONE * max_camera_zoom)


func _handle_movement(event_key: InputEventKey):
	var move = Vector2i.ZERO
	if event_key.is_action("player_up"):
		move += Vector2i.UP
	elif event_key.is_action("player_down"):
		move += Vector2i.DOWN
	elif event_key.is_action("player_left"):
		move += Vector2i.LEFT
	elif event_key.is_action("player_right"):
		move += Vector2i.RIGHT
	elif event_key.is_action("player_northeast"):
		move += Vector2i.UP + Vector2i.RIGHT
	elif event_key.is_action("player_northwest"):
		move += Vector2i.UP + Vector2i.LEFT
	elif event_key.is_action("player_southeast"):
		move += Vector2i.DOWN + Vector2i.RIGHT
	elif event_key.is_action("player_southwest"):
		move += Vector2i.DOWN + Vector2i.LEFT

	## Check for collision and change player position
	if move != Vector2i.ZERO:
		if Globals.game.layers.get_current_layer().can_move_to_position(grid_position + move):
			grid_position += move
			update_fov.call_deferred()

			for tile in Globals.game.layers.get_current_layer().get_tiles(grid_position):
				var tile_item: Item = tile as Item

				if tile_item:
					Globals.game_ui.prompt_text(
						"[color=#fae7ac]%s[/color] (grab: g)" % tile_item.tile_name
					)

			pass_turns(turns_to_move)

		else:
			for tile in Globals.game.layers.get_current_layer().get_tiles(grid_position + move):
				var enemy: Enemy = tile as Enemy
				if enemy:
					_handle_use_melee_weapon(enemy)
					pass_turns(turns_to_move)

## Update fov using player position
func update_fov() -> void:
	Globals.game.field_of_view.update_fov(grid_position)


## Pass turns and heal player
func pass_turns(turns_count: int) -> void:
	Globals.game.turn += turns_count
	set_health(health + heal_per_turns * turns_count)
	set_mana(mana + regen_per_turns * turns_count)


func get_hit(entity: Entity, damage: int) -> bool:
	self.health -= damage
	set_health(health)

	Globals.game_ui.prompt_text(
		"[color=#d37073]%s[/color] hits [color=#88A8C5]%s[/color]. (Damage: %d)" % \
		[
			entity.tile_name,
			tile_name,
			damage,
		]
	)

	return false

		
func set_health(new_health: int) -> void:
	health = new_health
	Globals.game_ui.health_progress_bar.value = health
	Globals.game_ui.health_label.text = "%d/%d" % [health, max_health]


func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	Globals.game_ui.health_progress_bar.max_value = max_health
	Globals.game_ui.health_label.text = "%d/%d" % [health, max_health]


func set_mana(new_mana: int) -> void:
	mana = new_mana
	Globals.game_ui.mana_progress_bar.value = mana
	Globals.game_ui.mana_label.text = "%d/%d" % [mana, max_mana]


func set_max_mana(new_max_mana: int) -> void:
	max_mana = new_max_mana
	Globals.game_ui.mana_progress_bar.max_value = max_mana
	Globals.game_ui.mana_label.text = "%d/%d" % [mana, max_mana]


func get_total_experience_for_the_level(_level: int) -> int:
	return roundi(Globals.player_config["level_up_experience_base"] * pow((1 + Globals.player_config["level_up_experience_increase_per_level"]), _level))


func set_experience(_experience: int) -> void:
	var _level: int = 0

	while _experience >= get_total_experience_for_the_level(_level) - Globals.player_config["level_up_experience_base"]:
		_level += 1
	
	_level -= 1
	if _level < 0:
		_level = 0

	level = _level
	experience = _experience
	var experience_for_the_next_level = get_total_experience_for_the_level(level + 1) - get_total_experience_for_the_level(level)
	var current_experience = experience_for_the_next_level - (get_total_experience_for_the_level(level + 1) - experience - Globals.player_config["level_up_experience_base"])
	Globals.game_ui.level_label.text = "%d/%d (%d)" % [current_experience, experience_for_the_next_level, level]
	Globals.game_ui.level_progress_bar.max_value = experience_for_the_next_level
	Globals.game_ui.level_progress_bar.value = current_experience

	damage_multiplier = 1 + (level * Globals.player_config["damage_multiplier_increase_per_level"])

	set_max_health(
		roundi(Globals.player_config["health_base"] * pow((1 + Globals.player_config["health_gain_per_level"]), level))
	)

	set_max_mana(
		roundi(Globals.player_config["mana_base"] * pow((1 + Globals.player_config["mana_gain_per_level"]), level))
	)


func add_item_to_inventory(item: Item) -> void:
	Globals.game.layers.get_current_layer().items.erase_item(item.grid_position)
	item.visible = false

	var item_frame: ItemFrame = item_frame_scene.instantiate()
	item_frame.item = item
	Globals.game_ui.add_item_frame(item_frame)


func get_melee_damage() -> int:
	if melee_weapon != null:
		return melee_weapon.damage * damage_multiplier
	else:
		return Globals.player_config["base_melee_damage"] * damage_multiplier

func get_range_damage() -> int:
	if range_weapon != null:
		return range_weapon.damage * damage_multiplier
	else:
		return 0

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)

	var to_copy: PackedStringArray = ["experience"]

	Utils.copy_from_dict_if_exists(
		self ,
		data,
		to_copy,
		to_copy
	)

	self.is_in_view = true
	self.is_explored = true

func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()
	result["experience"] = experience
	return result
