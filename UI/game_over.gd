extends Control

@onready var time: Label = $Time
@onready var scores_label: Label = $Score2
@onready var win_audio: AudioStreamPlayer = $WinAudio

func highscore_object_to_float(object: Array):
	var result: Array[float] = []
	for string in object:
		result.append(float(string))
	return result

func show_gameover(new_time: float):
	print("here")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	visible = true
	time.text = str(new_time)
	
	if not FileAccess.file_exists("user://highscore.txt"):
		var temp = FileAccess.open("user://highscore.txt", FileAccess.WRITE)
		temp.store_line(JSON.stringify({"highscores": []}))
		temp.close()
		
	var highscores = FileAccess.open("user://highscore.txt", FileAccess.READ)
	var data = highscores.get_line()
	highscores.close()
	var res = JSON.parse_string(data)
	
	var scores: Array[float] = highscore_object_to_float(res.highscores)
	
	scores.append(new_time)
	scores.sort()
	if len(scores) > 3:
		scores.pop_back()
	
	if new_time in scores:
		highscores = FileAccess.open("user://highscore.txt", FileAccess.WRITE)
		var highscores_dict: Dictionary = {
			"highscores": scores
		}
		highscores.store_line(JSON.stringify(highscores_dict))
		win_audio.play()
	
	var display_string: String = ""
	for score in scores:
		var score_string: String = str(score)
		display_string += score_string.substr(0, 3 + score_string.find('.')) + "\n"
	scores_label.text = display_string
	
func _on_menu_pressed():
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")


func _on_restart_pressed():
	visible = false
	get_tree().reload_current_scene()
