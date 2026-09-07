extends ScrollContainer
class_name DebugUI

@export var go_to_position_x_line_edit: LineEdit
@export var go_to_position_y_line_edit: LineEdit
@export var go_to_position_button: Button
@export var current_player_pos_label: Label

func _ready():
	go_to_position_button.button_down.connect(_on_go_to_position_button_pressed)


func _on_go_to_position_button_pressed():
	var x: int = int(go_to_position_x_line_edit.text)
	var y: int = int(go_to_position_y_line_edit.text)

	Globals.game.player.grid_position = Vector2i(x, y)


func _on_player_change_grid_position(_old_pos: Vector2i, new_pos: Vector2i) -> void:
	current_player_pos_label.text = "Current (%d, %d)" % \
		[Globals.game.player.grid_position.x, Globals.game.player.grid_position.y]
