extends RigidBody3D

@onready var audio = $AudioStreamPlayer3D

var Rope: PackedScene = preload("res://Model/rope.tscn")
var rope: Node3D
const MAX_LENGTH = 8

const ATTACH := preload("res://SFX/attach.ogg")
const DETACH := preload("res://SFX/detach.ogg")

func onHit():
	freeze = true
	audio.stream = ATTACH
	audio.play()
	await get_tree().create_timer(0.2).timeout
	audio.stop()
	
func onRelease():
	queue_free()
	if rope:
		rope.queue_free()


func _on_body_entered(body: Node3D):
	if body.collision_layer == 4 or body.collision_layer == 6:
		look_at(body.global_position)
		onHit()
	else:
		
		if audio.stream != DETACH:
			audio.stream = DETACH
			audio.play()
			await get_tree().create_timer(0.4).timeout
		onRelease()


func _integrate_forces(state):
	look_at(linear_velocity)


func _on_tree_entered():
	var world := get_tree().get_root()
	rope = Rope.instantiate()
	world.add_child(rope)

func _physics_process(delta):
	var anchor: Node3D = get_tree().get_root().get_node_or_null(
		"Level/PlayerHookshot/Neck/CameraParent/Camera3D/RopeAnchor")
	if not anchor or not rope:
		return
	var starting_position: Vector3 = anchor.global_position
	var rope_center: Vector3 = (global_position + starting_position) / 2
	rope.position = rope_center
	if (global_position - starting_position).length() > MAX_LENGTH:
		onRelease()
	rope.scale = Vector3(0.1, 0.1, (global_position - starting_position).length())
	rope.look_at(starting_position)

func _on_tree_exiting():
	onRelease()
