extends Node
class_name FieldOfView

var fov_radius: int = 8

# Armazena os tiles visíveis do frame ANTERIOR
var _visible_tiles: Array[Tile] = []
# Armazena os tiles visíveis sendo calculados no frame ATUAL
var _current_frame_visible: Array[Tile] = []

const OCTANT_TRANSFORMS = [
	Vector2i(1, 0), Vector2i(0, 1), # 0: E-NE
	Vector2i(0, 1), Vector2i(1, 0), # 1: N-NE
	Vector2i(0, 1), Vector2i(-1, 0), # 2: N-NW
	Vector2i(-1, 0), Vector2i(0, 1), # 3: W-NW
	Vector2i(-1, 0), Vector2i(0, -1), # 4: W-SW
	Vector2i(0, -1), Vector2i(-1, 0), # 5: S-SW
	Vector2i(0, -1), Vector2i(1, 0), # 6: S-SE
	Vector2i(1, 0), Vector2i(0, -1), # 7: E-SE
]

var enemies_in_view: Array[Enemy] = []

func update_fov(origin: Vector2i):
	enemies_in_view = []

	# 1. Limpa a lista temporária do frame atual
	_current_frame_visible.clear()

	# 2. O tile onde o jogador está é sempre visível
	_mark_visible(origin)

	# 3. Calcular FOV para os 8 octantes
	for i in range(8):
		_cast_light(
			origin, 1, 1.0, 0.0,
			OCTANT_TRANSFORMS[i * 2],
			OCTANT_TRANSFORMS[i * 2 + 1]
		)
	
	# 4. Processar ENTITITES/TILES que saíram do campo de visão (Exit)
	# Se estava visível antes, mas não está na lista nova, saiu da visão.
	for tile in _visible_tiles:
		if is_instance_valid(tile) and not tile in _current_frame_visible:
			tile.is_in_view = false
			if tile is Entity:
				tile._on_field_of_view_exit()

	# 5. Processar ENTITIES/TILES que entraram no campo de visão (Enter) e atualizar visual
	for tile in _current_frame_visible:
		if is_instance_valid(tile):
			if tile is Entity:
				enemies_in_view.append(tile)

			# Se não estava na lista anterior, acabou de entrar
			if not tile in _visible_tiles:
				if tile is Entity:
					tile._on_field_of_view_enter()
			
			# Garante que visualmente está aceso (o setter da classe Tile lida com a cor)
			tile.is_in_view = true

	# 6. Atualiza a lista oficial para o próximo frame
	_visible_tiles = _current_frame_visible.duplicate()

func _cast_light(origin: Vector2i, row: int, start_slope: float, end_slope: float, xx: Vector2i, xy: Vector2i):
	if start_slope < end_slope:
		return

	var next_start_slope = start_slope

	for i in range(row, fov_radius + 1):
		var blocked = false
		var dy = -i

		for dx in range(-i, 1):
			var l_slope = (dx - 0.5) / (dy + 0.5)
			var r_slope = (dx + 0.5) / (dy - 0.5)

			if start_slope < r_slope:
				continue

			if end_slope > l_slope:
				break

			var map_x = origin.x + (dx * xx.x + dy * xy.x)
			var map_y = origin.y + (dx * xx.y + dy * xy.y)
			var pos = Vector2i(map_x, map_y)

			if (dx * dx + dy * dy) < (fov_radius * fov_radius):
				_mark_visible(pos)

			# --- MUDANÇA PRINCIPAL NA LÓGICA DE BLOQUEIO ---
			# Agora verificamos o array retornado por get_tiles
			var tiles_at_pos = Globals.game.get_tiles(pos)
			var is_current_pos_transparent = true
			
			# Se QUALQUER coisa na célula bloquear a visão, ela é considerada bloqueada
			for t in tiles_at_pos:
				if t and not t.is_transparent:
					is_current_pos_transparent = false
					break
			
			# Lógica de Shadowcasting padrão
			if blocked:
				if is_current_pos_transparent:
					blocked = false
					start_slope = next_start_slope
				else:
					next_start_slope = r_slope
			elif not is_current_pos_transparent:
				blocked = true
				next_start_slope = r_slope
				_cast_light(origin, i + 1, start_slope, l_slope, xx, xy)

		if blocked:
			break

## Helper atualizado para lidar com Array[Tile]
func _mark_visible(pos: Vector2i):
	var tiles_at_pos = Globals.game.get_tiles(pos)
	
	# Adiciona todos os tiles/entidades dessa posição à lista do frame atual
	for tile in tiles_at_pos:
		if tile: # Verifica null, pois seu get_tiles pode retornar [Obj, null]
			if not tile in _current_frame_visible:
				_current_frame_visible.append(tile)
