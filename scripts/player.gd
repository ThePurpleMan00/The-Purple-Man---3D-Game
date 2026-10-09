class_name FirstPersonPlayer
extends CharacterBody3D
## Feet-origin first-person controller. Tune movement in the Inspector.

signal controls_changed(active: bool)

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 5.0
@export var acceleration: float = 24.0
@export var air_acceleration: float = 8.0
@export var mouse_sensitivity: float = 0.002
@export_range(1.0, 89.0) var pitch_limit_degrees: float = 85.0

@onready var head: Node3D = $Head

var controls_active: bool = true
var _spawn_transform: Transform3D


func _ready() -> void:
	_spawn_transform = global_transform
	# Browsers require a click before requesting pointer lock.
	set_controls_active(not OS.has_feature("web"))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("release_mouse"):
		set_controls_active(false)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		set_controls_active(true)
		get_viewport().set_input_as_handled()
	elif controls_active and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		var pitch_limit := deg_to_rad(pitch_limit_degrees)
		head.rotation.x = clampf(head.rotation.x - event.relative.y * mouse_sensitivity, -pitch_limit, pitch_limit)
	elif controls_active and event.is_action_pressed("reset_player"):
		reset_player()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if controls_active and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_vector := Vector2.ZERO
	if controls_active:
		input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
	direction.y = 0.0
	direction = direction.normalized() * input_vector.length()
	var speed := sprint_speed if controls_active and Input.is_action_pressed("sprint") else walk_speed
	var rate := acceleration if is_on_floor() else air_acceleration
	velocity.x = move_toward(velocity.x, direction.x * speed, rate * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, rate * delta)
	move_and_slide()

	if global_position.y < -20.0:
		reset_player()


func set_controls_active(enabled: bool) -> void:
	controls_active = enabled
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if enabled else Input.MOUSE_MODE_VISIBLE
	if not enabled:
		velocity.x = 0.0
		velocity.z = 0.0
	controls_changed.emit(enabled)


func reset_player() -> void:
	global_transform = _spawn_transform
	velocity = Vector3.ZERO
	head.rotation = Vector3.ZERO
