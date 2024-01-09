extends Node3D




func _on_gravityzone_body_entered(body):
	get_tree().call_group("entity", "set_gravitating")


func _on_endzone_body_entered(body):
	get_tree().call_group("level", "end_level")
