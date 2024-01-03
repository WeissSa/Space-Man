extends Control

@onready var timer := $Timer
@onready var pause := $Paused

func _input(event):
	if event.is_action_pressed("ui_cancel") and Input.get_mouse_mode() != Input.MOUSE_MODE_VISIBLE:
		mouse_filter = Control.MOUSE_FILTER_STOP
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		timer.timer_on = false
		$Paused.visible = true
		get_tree().call_group("entity", "set_is_paused", true)
	elif event.is_action_pressed("ui_cancel"):
		mouse_filter = Control.MOUSE_FILTER_PASS
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		timer.timer_on = true
		$Paused.visible = false
		get_tree().call_group("entity", "set_is_paused", false)
