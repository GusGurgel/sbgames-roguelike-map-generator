extends SerializableNode2D
class_name LayerList

var layers: Dictionary[String, Layer]
var current_layer_key: String
var next_layer_key: String:
	get():
		return layers_keys_ordered[(current_layer_index + 1) % len(layers_keys_ordered)]
var previous: String:
	get():
		return layers_keys_ordered[(current_layer_index - 1) % len(layers_keys_ordered)]
var layers_keys_ordered: Array
var current_layer_index: int:
	get():
		return layers_keys_ordered.find(current_layer_key)

func _init():
	layers["default"] = Layer.new()
	layers["default"].name = "default"
	layers["default"].rooms = [Rect2i()]
	

## Returns current layer if exists, else returns default layer
func get_layer(layer_key: String) -> Layer:
	return layers.get(layer_key, layers["default"])


func get_current_layer() -> Layer:
	return get_layer(current_layer_key)


func switch_layer(layer_key: String) -> void:
	if current_layer_key and get_layer(current_layer_key).get_parent() == self:
		remove_child(get_layer(current_layer_key))

	if layers.has(layer_key):
		current_layer_key = layer_key
	else:
		current_layer_key = "default"
	add_child(get_layer(layer_key))

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)

	if data.has("layers"):
		for layer_key in data["layers"]:
			var layer: Layer = Layer.new()
			var layer_data = data["layers"][layer_key]
			layer.load(layer_data)

			layers[layer_key] = layer
			layer.name = layer_key
	else:
		Utils.print_warning("Layers without layers array")


	layers_keys_ordered = data["layers_keys_ordered"]

	current_layer_key = data["current_layer_key"]
	
	switch_layer(current_layer_key)


func serialize() -> Dictionary:
	var result: Dictionary = super.serialize()
	
	
	result["current_layer_key"] = current_layer_key
	result["layers_keys_ordered"] = layers_keys_ordered

	result["layers"] = {}
	for layer_key in layers:
		if layer_key == "default":
			continue

		result["layers"][layer_key] = layers[layer_key].serialize()

	return result
