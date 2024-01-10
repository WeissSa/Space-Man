extends Control

@onready var credits = $Credits
@onready var credits_label = $Credits/Credits


# Called when the node enters the scene tree for the first time.
func _ready():
	var file = FileAccess.open("res://attributions.txt", FileAccess.READ)
	credits_label.text = file.get_as_text()


func _on_close_pressed():
	credits.visible = false


func _on_credits_pressed():
	credits.visible = true


func _on_play_pressed():
	get_tree().change_scene_to_file("res://level/level.tscn")
