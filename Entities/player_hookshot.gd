extends CharacterBody3D


const MAX_SPEED := 4
const ACCELERATION := 0.3
const DECELLERATION := 0.2
const GRAVITY := 12
const JUMP_VELOCITY := 6
const JUMP_SLOWDOWN := 0.8
const SPEED_CUTOFF := 3

enum STATES {RUNNING, JUMPING, FALLING, STANDING, GRAVITATING}

var mouse_sensitivity: float = 0.005
var direction_2D: Vector2 = Vector2(0, 0)
var state: STATES = STATES.RUNNING

@onready var neck := $Neck
@onready var camera := $Neck/CameraParent
@onready var coyote_time := $CoyoteTime
@onready var camera_shake := $Neck/CameraParent/CameraShake
@onready var camera_node := $Neck/CameraParent/Camera3D
@onready var hookshot_head = $Neck/CameraParent/Camera3D/HookshotHeadModel
@onready var reticle = $Neck/CameraParent/Camera3D/Reticle
@onready var shoot = $Shoot
@onready var walk = $Walk

var Hook: PackedScene = preload("res://Entities/hook.tscn")
const HOOK_SPEED := 30
const GRAPPLE_FORCE := 8
const NEUTRAL_ROPE_LENGTH := 0.5
var is_grappling: bool = false
var is_near_hook: bool = false
var initial_radius: float

var is_paused: bool = false

func set_is_paused(value: bool):
	is_paused = value

func set_gravitating():
	state = STATES.GRAVITATING

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
	
	if event.is_action_pressed("shoot") and hookshot_head.visible:
		hookshot_head.visible = false
		shoot.play()
		shoot_hookshot()
	elif event.is_action_released("shoot") and not hookshot_head.visible:
		shoot.stop()
		release_hookshot()
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * mouse_sensitivity * GlobalSettings.SENSITIVITY)
			camera.rotate_x(-event.relative.y * mouse_sensitivity * GlobalSettings.SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(90))
			

func apply_vertical_movement(delta: float) -> void:
	if not is_on_floor() and coyote_time.is_stopped():
		var multiplier: float = 1
		if is_near_hook:
			multiplier = -1
			if 0 > velocity.y and velocity.y >= MAX_SPEED:
				multiplier = - 10
		velocity.y -= GRAVITY * delta * multiplier
		if velocity.y < 0:
			state = STATES.FALLING
	
	# fall faster once we reach peak of jump
	if state == STATES.FALLING:
		velocity.y -= GRAVITY * delta / 2
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and (
		is_on_floor() or not coyote_time.is_stopped()
		):
		velocity.y = JUMP_VELOCITY
		state = STATES.JUMPING
		coyote_time.stop()
	elif is_grappling and Input.is_action_just_pressed("jump"):
		release_hookshot()
		velocity.y = max(velocity.y, 4)
	elif is_on_floor():
		state = STATES.RUNNING
		

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
	
	if state == STATES.RUNNING and speed > 1 and is_on_floor():
		camera_shake.play("ShakeStrong")
		walk.pitch_scale = randf_range(0.35, 0.45)
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
			var grapple_vector: Vector3 = direction_vector.normalized() * GRAPPLE_FORCE
			grapple_vector = grapple_vector * (direction_vector.length() - NEUTRAL_ROPE_LENGTH)
			velocity +=  grapple_vector * delta 

func handle_gravitation(delta):
	var finish: Node3D = get_tree().get_root().get_node_or_null("Level/Finish")
	if finish:
		var direction_vector: Vector3 = (finish.global_position - global_position) 
		velocity = direction_vector * direction_vector.length()


func _physics_process(delta: float) -> void:
	if is_paused:
		return
	if state != STATES.GRAVITATING:
		if get_tree().get_root().get_node_or_null("Hook"):
			handle_grapple(delta)
		else:
			is_grappling = false
			is_near_hook = false
			initial_radius = INF
		
		apply_horizontal_movement(delta)
		
		apply_vertical_movement(delta)
	else:
		handle_gravitation(delta)
	
	var was_on_floor: bool = is_on_floor()
	move_and_slide()
	if was_on_floor and not is_on_floor():
		coyote_time.start()
	
	if velocity.is_equal_approx(Vector3.ZERO):
		state = STATES.STANDING
	animate()


func _on_ready():
	camera_node.fov = GlobalSettings.FOV
