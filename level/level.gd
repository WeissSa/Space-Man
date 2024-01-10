extends Node3D


@onready var tutorial_platforms = $tutorial_platforms
@onready var level_spawn = $level_platforms/starting_platform
@onready var player = $PlayerHookshot
var respawn_point: Vector3 = Vector3(0, 1, 0)

func hide_tutorial():
	respawn_point = level_spawn.global_position + Vector3(0, 1, 0)
	tutorial_platforms.queue_free()

func respawn():
	player.global_position = respawn_point
	player.neck.rotation = Vector3(0, 0, 0)
	player.camera.rotation = Vector3(0, 0, 0)


func end_level():
	get_tree().quit()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
