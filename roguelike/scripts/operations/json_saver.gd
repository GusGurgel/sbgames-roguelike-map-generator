extends Operation
class_name JSONSaver


func save_json_data(data: Dictionary, path: String):
	var json_string = JSON.stringify(data, "\t")
	
	var file_access = FileAccess.open(path, FileAccess.WRITE)
	if file_access:
		file_access.store_string(json_string)
		file_access.close()
	else:
		error_messages.push_back("Invalid JSON.")
