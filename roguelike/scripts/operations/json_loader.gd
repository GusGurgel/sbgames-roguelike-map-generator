extends Operation
class_name JSONLoader


var data: Dictionary


## Load a "strinfied" JSON. Only accepts JSON Dictionaries.
func load_from_string(json_string: String) -> void:
	var json = JSON.new()
	var json_error = json.parse(json_string)
	if json_error != OK:
		var json_error_info = "error %s at line %s"
		json_error_info = json_error_info % [json.get_error_message(), json.get_error_line()]
		error_messages.push_back("Invalid JSON: %s" % json_error_info)
		return

	var data_received = json.data
	if typeof(data_received) != TYPE_DICTIONARY:
		error_messages.push_back("Invalid JSON.")
		return

	data = data_received as Dictionary


## Load a JSON file. Only accepts JSON Dictionaries.
func load_from_path(path: String) -> void:
	var file = FileAccess.open(path, FileAccess.READ)

	if not file:
		error_messages.push_back("File '%s' does not exists." % path)
		return

	var json_string = file.get_as_text()
	file.close()
	load_from_string(json_string)