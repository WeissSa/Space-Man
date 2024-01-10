extends Control

@onready var timer := $Timer
@onready var pause := $PauseMenu

func _input(event):
	if event.is_action_pressed("ui_cancel") and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		mouse_filter = Control.MOUSE_FILTER_STOP
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		timer.timer_on = false
		pause.visible = true
		get_tree().call_group("entity", "set_is_paused", true)
	elif event.is_action_pressed("ui_cancel"):
		close_ui()

func close_ui():
	mouse_filter = Control.MOUSE_FILTER_PASS
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	timer.timer_on = true
	pause.visible = false
	get_tree().call_group("entity", "set_is_paused", false)

func _on_resume_button_up():
	close_ui()


func _on_menu_button_up():
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")
