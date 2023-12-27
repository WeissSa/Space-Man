extends CharacterBody3D


const MAX_SPEED = 3
const ACCELERATION = 0.3
const DECELLERATION = 0.2
const GRAVITY = 2.3
const JUMP_VELOCITY = 2

var mouse_sensitivity = 0.005
var direction_2D: Vector2 = Vector2(0, 0)

@onready var neck := $Neck
@onready var camera := $Neck/Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_down")
	direction_2D.x = clamp(input_dir.x * ACCELERATION + direction_2D.x, -1, 1)
	direction_2D.y = clamp(input_dir.y * ACCELERATION + direction_2D.y, -1, 1)
	var direction: Vector3 = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = clamp(direction.x * MAX_SPEED,
			-MAX_SPEED * abs(direction.x), 
			MAX_SPEED * abs(direction.x)
		)
		velocity.z = clamp(direction.z * MAX_SPEED,
			-MAX_SPEED * abs(direction.z), 
			MAX_SPEED * abs(direction.z)
		)
	else:
		velocity.x = move_toward(velocity.x, 0, DECELLERATION)
		velocity.z = move_toward(velocity.z, 0, DECELLERATION)
		
	
	move_and_slide()
