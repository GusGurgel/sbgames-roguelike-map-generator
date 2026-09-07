extends Resource
class_name LayerPainter

var tile_preset_list: TilePresetList
var layer: Layer


func _init(_layer: Layer, _tile_preset_list: TilePresetList):
	tile_preset_list = _tile_preset_list
	layer = _layer

