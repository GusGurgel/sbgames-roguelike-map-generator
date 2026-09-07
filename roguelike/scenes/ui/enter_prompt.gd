extends Control

@export var loading_panel: Panel
@export var input_text: CodeEdit
@export var generate_button: Button

var main_scene = preload("res://scenes/main.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_button.button_down.connect(_on_generate_button_pressed)

func _on_generate_button_pressed() -> void:
	loading_panel.visible = true
	var post_result: Dictionary = await send_post_and_wait(input_text.text)
	Globals.game_data = post_result
	loading_panel.visible = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func send_post_and_wait(map_description: String) -> Dictionary:
	# 1. URL base limpa
	var url: String = "http://localhost:8000/generate-map/"
	
	# 2. Preparamos o corpo da requisição como um dicionário
	var body_dict = {"map_description": map_description}
	var json_body = JSON.stringify(body_dict)

	var http_request := HTTPRequest.new()
	add_child(http_request)

	# 3. Headers indicando que estamos enviando JSON
	var headers = ["Content-Type: application/json"]

	# 4. Enviamos o JSON no quarto argumento da função request
	var error = http_request.request(
		url,
		headers,
		HTTPClient.METHOD_POST,
		json_body
	)

	if error != OK:
		push_error("Erro ao iniciar requisição: %s" % error)
		http_request.queue_free()
		return {}

	var result = await http_request.request_completed
	
	http_request.queue_free()

	var response_code = result[1]
	var response_body = result[3]

	if response_code == 200:
		var response_text = response_body.get_string_from_utf8()
		return JSON.parse_string(response_text)
	else:
		push_error("Erro %d: %s" % [response_code, response_body.get_string_from_utf8()])
		return {}
