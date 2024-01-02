extends CharacterBody3D


const MAX_SPEED := 4
const ACCELERATION := 0.3
const DECELLERATION := 0.2
const GRAVITY := 12
const JUMP_VELOCITY := 6
const JUMP_SLOWDOWN := 0.8
const SPEED_CUTOFF := 3

enum STATES {RUNNING, JUMPING, FALLING, STANDING}

var mouse_sensitivity: float = 0.005
var direction_2D: Vector2 = Vector2(0, 0)
var state: STATES = STATES.RUNNING
var initial_jump_basis: Basis

@onready var neck := $Neck
@onready var camera := $Neck/CameraParent
@onready var coyote_time := $CoyoteTime
@onready var camera_shake := $Neck/CameraParent/CameraShake
@onready var camera_node := $Neck/CameraParent/Camera3D
@onready var hookshot_head = $Neck/CameraParent/Camera3D/HookshotHeadModel
@onready var reticle = $Neck/CameraParent/Camera3D/Reticle
@onready var shoot = $AudioStreamPlayer

var Hook: PackedScene = preload("res://Entities/hook.tscn")
const HOOK_SPEED := 17
const GRAPPLE_FORCE := 5
var is_grappling: bool = false
var is_near_hook: bool = false
var initial_radius: float

func shoot_hookshot():
	var world = get_tree().get_root()
	var hook = Hook.instantiate()
	hook.transform = reticle.global_transform
	hook.linear_velocity = camera_node.global_transform.basis * Vector3(0, 0, -HOOK_SPEED)
	world.add_child(hook)

func release_hookshot():
	hookshot_head.visible = true
	var hook = get_tree().get_root().get_node_or_null("Hook")
	if hook:
		hook.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("shoot") and hookshot_head.visible:
		hookshot_head.visible = false
		shoot.play()
		shoot_hookshot()
	elif event.is_action_released("shoot") and not hookshot_head.visible:
		shoot.stop()
		release_hookshot()
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(70))
			

func apply_vertical_movement(delta: float) -> void:
	if not is_on_floor() and coyote_time.is_stopped():
		var multiplier: float = 1
		if is_near_hook:
			multiplier = -1
		velocity.y -= GRAVITY * delta * multiplier
		if velocity.y < 0:
			state = STATES.FALLING
	
	# fall faster once we reach peak of jump
	if state == STATES.FALLING:
		velocity.y -= GRAVITY * delta / 2
	
	if state == STATES.JUMPING and initial_jump_basis == Basis.IDENTITY and (
		velocity.x > 0 or velocity.y > 0) and not is_grappling:
		initial_jump_basis = neck.transform.basis
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and (
		is_on_floor() or not coyote_time.is_stopped()
		):
		velocity.y = JUMP_VELOCITY
		state = STATES.JUMPING
		if state == STATES.RUNNING:
			initial_jump_basis = neck.transform.basis
		coyote_time.stop()
	elif is_grappling and Input.is_action_just_pressed("jump"):
		release_hookshot()
		velocity.y = max(velocity.y, 4)
	elif is_on_floor():
		state = STATES.RUNNING
		initial_jump_basis = Basis.IDENTITY
		

func clamp_acceleration(input_dir: Vector2, delta: float):
	return Vector2(
		clamp(input_dir.x * ACCELERATION * delta + direction_2D.x, -1, 1),
		clamp(input_dir.y * ACCELERATION * delta + direction_2D.y, -1, 1)
	)

func apply_horizontal_movement(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("move_left", 
		"move_right", "move_forward", "move_down")

	if state == STATES.STANDING and (input_dir.x != 0 or input_dir.y != 0):
		state = STATES.RUNNING
	

	direction_2D = clamp_acceleration(input_dir, delta)
	
	# makes sure you cannot backup while grappling
	if is_grappling and input_dir.y != 0:
		input_dir.y = -(abs(input_dir.y + 1) / 2)
	# convert inputs into normalized direction vector
	# keep relative direction if jumping
	var direction: Vector3 = (neck.transform.basis * Vector3(input_dir.x,
			0, input_dir.y)).normalized()
	

	if state in [STATES.JUMPING, STATES.FALLING] and not is_grappling and initial_jump_basis != Basis.IDENTITY:
		direction += (initial_jump_basis * Vector3(input_dir.x,
			0, input_dir.y))
		direction = direction / 2

		
			
	# allow for precision in non-forward directions
	if initial_jump_basis and initial_jump_basis != Basis.IDENTITY:
		if input_dir.y > 0:
			direction.z = direction.z * JUMP_SLOWDOWN
		direction.x = direction.x * JUMP_SLOWDOWN
		
	handle_inputs(direction)


func handle_inputs(direction: Vector3) -> void:
	if direction:
		velocity.x = direction.x * MAX_SPEED
		velocity.z = direction.z * MAX_SPEED
	elif not is_grappling:
		velocity.x = move_toward(velocity.x, 0, DECELLERATION)
		velocity.z = move_toward(velocity.z, 0, DECELLERATION)

func animate():
	var speed: float = sqrt(velocity.x ** 2 + velocity.z ** 2)

	var need_animation: bool = len(camera_shake.get_queue()) == 0
	if state == STATES.RUNNING and speed < 2:
		if need_animation:
			camera_shake.queue("ShakeWeak")
	elif state == STATES.RUNNING and speed > 3:
		if need_animation:
			camera_shake.queue("ShakeStrong")
	else:
		camera_shake.play("RESET")

		

func handle_grapple(delta: float):
	var hook: Node3D = get_tree().get_root().get_node("Hook")
	if initial_radius != INF:
		initial_radius = (hook.global_position - global_position).length()
	if hook.freeze:
		is_grappling = true

		var direction_vector: Vector3 = hook.global_position - global_position
		if direction_vector.length() < 2:
			is_near_hook = true
		
		if direction_vector.length() <= initial_radius:
			velocity += direction_vector * GRAPPLE_FORCE * delta

func _physics_process(delta: float) -> void:
	
	if get_tree().get_root().get_node_or_null("Hook"):
		handle_grapple(delta)
	else:
		is_grappling = false
		is_near_hook = false
		initial_radius = INF
	
	apply_horizontal_movement(delta)
	
	apply_vertical_movement(delta)
	
	var was_on_floor: bool = is_on_floor()
	move_and_slide()
	if was_on_floor and not is_on_floor():
		coyote_time.start()
	
	if velocity.is_equal_approx(Vector3.ZERO):
		state = STATES.STANDING
		
	animate()
	

	
	
