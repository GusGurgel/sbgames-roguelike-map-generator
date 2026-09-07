extends SerializableResource
class_name TextureList

var textures: Dictionary[String, AtlasTexture]

func get_texture(texture_key: String) -> AtlasTexture:
	if textures.has(texture_key):
		return textures[texture_key]
	else:
		return textures["default"]


func get_texture_monochrome(texture_key: String) -> AtlasTexture:
	texture_key = "monochrome_%s" % texture_key
	if textures.has(texture_key):
		return textures[texture_key]
	else:
		return textures["monochrome_default"]

################################################################################
# Serialization
################################################################################

func load(data: Dictionary) -> void:
	super.load(data)

	# Add the default texture
	var default_colored_texture: AtlasTexture = AtlasTexture.new()
	var default_monochrome_texture: AtlasTexture = AtlasTexture.new()
	default_colored_texture.atlas = Globals.colored_texture
	default_monochrome_texture.atlas = Globals.monochrome_texture
	default_colored_texture.region = Rect2(
		Globals.default_texture.x * Globals.tile_size.x,
		Globals.default_texture.y * Globals.tile_size.y,
		Globals.tile_size.x,
		Globals.tile_size.y
	)
	default_monochrome_texture.region = default_colored_texture.region
	textures["default"] = default_colored_texture
	textures["monochrome_default"] = default_monochrome_texture

	for key in data:
		var texture_data = data[key]

		if not Utils.dict_has_all(texture_data, ["x", "y"]):
			Utils.print_warning("Texture '%s' without position." % key)
			continue

		## Add colored and monochrome versions
		var texture_colored: AtlasTexture = AtlasTexture.new()
		var texture_monochrome: AtlasTexture = AtlasTexture.new()

		texture_colored.atlas = Globals.colored_texture
		texture_monochrome.atlas = Globals.monochrome_texture
		texture_colored.region = Rect2(
			texture_data["x"] * Globals.tile_size.x,
			texture_data["y"] * Globals.tile_size.y,
			Globals.tile_size.x,
			Globals.tile_size.y
		)
		texture_monochrome.region = texture_colored.region

		textures[key] = texture_colored
		textures["monochrome_%s" % key] = texture_monochrome


func serialize() -> Dictionary:
	var result: Dictionary = {}
	return result
