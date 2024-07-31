class_name SaveGame
extends Resource

const save_path := "user://gamestate.save"

@export var version := 1
@export var WorldState: Resource

func save():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(WorldState)

func load_data():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		WorldState = file.get_var()
	else:
		print("no data has been saved")
	
