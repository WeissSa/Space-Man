extends Node


var FOV: int = 85
var VOLUME: float  = 1.0
var SENSITIVITY: float = 1.0

func _ready():
	load_game()

func set_FOV(new: int):
	FOV = new

func set_Volume(new: float):
	VOLUME = new

func set_Sensitivity(new: float):
	SENSITIVITY = new

func save_game():
	var save_game = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var save_data: Dictionary = {
		"FOV": str(FOV),
		"VOLUME": str(VOLUME),
		"SENSITIVITY": str(SENSITIVITY)
	}
	save_game.store_line(JSON.stringify(save_data))

func load_game():
	if not FileAccess.file_exists("user://savegame.save"):
		return
	var save_game = FileAccess.open("user://savegame.save", FileAccess.READ)
	var data = save_game.get_line()
	var res = JSON.parse_string(data)
	if res.FOV:
		set_FOV(int(res.FOV))
	if res.SENSITIVITY:
		set_Sensitivity(float(res.SENSITIVITY))
	if res.VOLUME:
		set_Volume(float(res.VOLUME))
	

