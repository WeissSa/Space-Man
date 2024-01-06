extends Node3D


@onready var tutorial_platforms = $tutorial_platforms

func hide_tutorial():
	tutorial_platforms.queue_free()


