extends Area3D

func respawn_player():
	get_tree().reload_current_scene()

func _on_body_entered(body):
	get_tree().call_group("hookshot", "_on_tree_exiting")
	get_tree().call_group("level", "respawn")

