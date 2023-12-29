extends CharacterBody3D


const MAX_SPEED = 4
const ACCELERATION = 0.3
const DECELLERATION = 0.2
const GRAVITY = 12
const JUMP_VELOCITY = 6
const JUMP_SLOWDOWN = 0.8
const SPEED_CUTOFF = 3

enum STATES {RUNNING, JUMPING, FALLING, STANDING}

var mouse_sensitivity = 0.005
var direction_2D: Vector2 = Vector2(0, 0)
var state: STATES = STATES.RUNNING
var initial_jump_basis: Basis

@onready var neck := $Neck
@onready var camera := $Neck/CameraParent
@onready var coyote_time := $CoyoteTime
@onready var camera_shake := $Neck/CameraParent/CameraShake
@onready var camera_node := $Neck/CameraParent/Camera3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			neck.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(55))
			

func apply_vertical_movement(delta: float) -> void:
	if not is_on_floor() and coyote_time.is_stopped():
		velocity.y -= GRAVITY * delta
		if velocity.y < 0:
			state = STATES.FALLING
	
	# fall faster once we reach peak of jump
	if state == STATES.FALLING:
		velocity.y -= GRAVITY * delta / 2
	
	if state == STATES.JUMPING and initial_jump_basis == Basis.IDENTITY and (
		velocity.x > 0 or velocity.y > 0):
		initial_jump_basis = neck.transform.basis
	
	# Handle jump.
	if Input.is_action_just_pressed("jump") and (
		is_on_floor() or not coyote_time.is_stopped()):
		velocity.y = JUMP_VELOCITY
		state = STATES.JUMPING
		if state == STATES.RUNNING:
			initial_jump_basis = neck.transform.basis
		coyote_time.stop()
	elif is_on_floor():
		state = STATES.RUNNING
		initial_jump_basis = Basis.IDENTITY
	

func apply_horizontal_movement(delta: float) -> void:
	# Get the input direction and handle the movement/deceleration.
	var input_dir: Vector2 = Input.get_vector("move_left", 
		"move_right", "move_forward", "move_down")

	if state == STATES.STANDING and (input_dir.x != 0 or input_dir.y != 0):
		state = STATES.RUNNING
	
	
	# read inputs and factor in acceleration
	direction_2D.x = clamp(input_dir.x * ACCELERATION * delta + direction_2D.x,
		-1, 1)

	direction_2D.y = clamp(input_dir.y * ACCELERATION * delta + direction_2D.y,
		-1, 1)
	
	# convert inputs into normalized direction vector
	# keep relative direction if jumping
	var direction: Vector3 = (neck.transform.basis * Vector3(input_dir.x,
			0, input_dir.y)).normalized()
	
	if state in [STATES.JUMPING, STATES.FALLING]:
		direction += (initial_jump_basis * Vector3(input_dir.x,
			0, input_dir.y)).normalized()
		direction = direction / 2

		
			
	# allow for precision in non-forward directions
	if initial_jump_basis and initial_jump_basis != Basis.IDENTITY:
		if input_dir.y > 0:
			direction.z = direction.z * JUMP_SLOWDOWN
		direction.x = direction.x * JUMP_SLOWDOWN
		
	handle_inputs(direction)

func handle_inputs(direction: Vector3) -> void:
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


func _physics_process(delta: float) -> void:

	apply_horizontal_movement(delta)
	
	apply_vertical_movement(delta)
	
	var was_on_floor: bool = is_on_floor()
	move_and_slide()
	if was_on_floor and not is_on_floor():
		coyote_time.start()
	
	if velocity.is_equal_approx(Vector3.ZERO):
		state = STATES.STANDING
		
	animate()
	

	
	
