extends Area3D

func respawn_player():
	get_tree().reload_current_scene()

func _on_body_entered(body):
	respawn_player()
