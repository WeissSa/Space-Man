extends RigidBody3D

func onHit():
	freeze = true
	
func onRelease():
	queue_free()


func _on_body_entered(body: Node3D):
	print(body.collision_layer)
	if body.collision_layer == 4:
		look_at(body.global_position)
		onHit()
	else:
		onRelease()


func _integrate_forces(state):
	look_at(linear_velocity)
