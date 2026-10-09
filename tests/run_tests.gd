extends SceneTree

## Exercise the playable scene and controller with real physics and input actions.
const ACTIONS: Array[StringName] = [
	&"move_forward", &"move_back", &"move_left", &"move_right",
	&"sprint", &"jump", &"reset_player", &"release_mouse",
]

var passed := 0
var failed := 0
var player: CharacterBody3D
var head: Node3D
var spawn: Transform3D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room_scene := load("res://scenes/test_room.tscn") as PackedScene
	_check(room_scene != null, "Test room loads")
	if room_scene == null:
		_finish()
		return
	var room := room_scene.instantiate()
	root.add_child(room)
	player = room.get_node_or_null("Player") as CharacterBody3D
	_check(player != null, "Room contains the first-person player")
	if player == null:
		_finish()
		return
	head = player.get_node_or_null("Head") as Node3D
	_check(head != null and head.get_node_or_null("Camera3D") is Camera3D,
		"Player has a head and camera")
	if head == null:
		_finish()
		return
	spawn = player.global_transform
	for action in ACTIONS:
		_check(InputMap.has_action(action), "Input action exists: %s" % action)
		if not InputMap.has_action(action):
			_finish()
			return

	await _test_floor()
	await _test_movement()
	await _test_jump()
	await _test_collisions()
	await _test_ramp()
	await _test_mouse_look()
	await _test_release_and_resume()
	await _test_reset()
	_finish()


func _test_floor() -> void:
	await _reset()
	_check(player.is_on_floor(), "Gravity brings the player onto the floor")
	_check(absf(player.global_position.y) < 0.08,
		"Capsule rests with its feet at floor height")
	_check(absf(player.velocity.y) < 0.01, "Landing clears downward velocity")


func _test_movement() -> void:
	await _reset()
	var start := player.global_position
	Input.action_press("move_forward")
	await _frames(60)
	_release_actions()
	var walk_distance := start.z - player.global_position.z
	_check(walk_distance > 4.0 and walk_distance < 5.6,
		"Forward walking covers the expected distance")
	_check(absf(player.global_position.x - start.x) < 0.02,
		"Forward walking does not drift sideways")

	await _reset()
	start = player.global_position
	Input.action_press("move_forward")
	Input.action_press("sprint")
	await _frames(60)
	_release_actions()
	var sprint_distance := start.z - player.global_position.z
	_check(sprint_distance > walk_distance * 1.35 and sprint_distance < 8.7,
		"Sprint is faster than walking")

	await _reset()
	start = player.global_position
	Input.action_press("move_forward")
	Input.action_press("move_right")
	await _frames(60)
	_release_actions()
	var diagonal := player.global_position - start
	diagonal.y = 0.0
	_check(diagonal.x > 2.0 and diagonal.z < -2.0,
		"Diagonal input moves in both requested directions")
	_check(absf(diagonal.length() - walk_distance) < 0.35,
		"Diagonal movement is normalized")


func _test_jump() -> void:
	await _reset()
	var start_y := player.global_position.y
	Input.action_press("jump")
	await _frames(1)
	Input.action_release("jump")
	var highest_y := player.global_position.y
	for frame in range(110):
		await _frames(1)
		highest_y = maxf(highest_y, player.global_position.y)
	_check(highest_y > start_y + 0.7, "Jump lifts the player off the floor")
	_check(player.is_on_floor() and absf(player.global_position.y) < 0.08,
		"The player lands after jumping")


func _test_collisions() -> void:
	await _reset()
	player.global_position = Vector3(0.0, 0.1, -8.0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	Input.action_press("move_forward")
	await _frames(70)
	_release_actions()
	_check(player.global_position.z > -9.65 and player.global_position.z < -8.8,
		"The far wall blocks forward movement")
	_check(player.is_on_floor(), "The floor supports the player against the wall")

	await _reset()
	player.global_position = Vector3(3.0, 0.1, 3.0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	Input.action_press("move_forward")
	await _frames(70)
	_release_actions()
	_check(player.global_position.z > 1.25 and player.global_position.z < 1.6,
		"The raised test block blocks forward movement")
	_check(absf(player.global_position.y) < 0.08,
		"Walking into the block does not climb through it")


func _test_mouse_look() -> void:
	await _reset()
	_mouse_motion(Vector2(100.0, -100.0))
	_check(player.rotation.y < -0.05 and head.rotation.x > 0.05,
		"Mouse movement turns the player and raises the view")
	_mouse_motion(Vector2(0.0, -100000.0))
	_check(absf(head.rotation.x - deg_to_rad(85.0)) < 0.001,
		"Looking upward stops at the pitch limit")
	_mouse_motion(Vector2(0.0, 200000.0))
	_check(absf(head.rotation.x + deg_to_rad(85.0)) < 0.001,
		"Looking downward stops at the pitch limit")
	_check(absf(head.rotation.z) < 0.001, "Mouse look does not roll the view")


func _test_ramp() -> void:
	await _reset()
	player.global_position = Vector3(-5.0, 0.1, 1.0)
	player.velocity = Vector3.ZERO
	await _frames(20)
	Input.action_press("move_forward")
	await _frames(110)
	_release_actions()
	await _frames(20)
	_check(player.global_position.z < -6.5,
		"Walking forward traverses the ramp onto its platform")
	_check(player.is_on_floor() and absf(player.global_position.y - 1.55) < 0.08,
		"The ramp leads to a supported raised platform")


func _test_release_and_resume() -> void:
	await _reset()
	var escape := InputEventKey.new()
	escape.physical_keycode = KEY_ESCAPE
	escape.pressed = true
	player.call("_unhandled_input", escape)
	_check(not bool(player.get("controls_active")), "Escape releases player controls")
	var start := player.global_position
	var start_yaw := player.rotation.y
	var start_pitch := head.rotation.x
	Input.action_press("move_forward")
	Input.action_press("sprint")
	Input.action_press("jump")
	_mouse_motion(Vector2(500.0, 500.0))
	await _frames(45)
	_release_actions()
	_check(player.global_position.distance_to(start) < 0.02,
		"Released controls ignore movement and jump")
	_check(is_equal_approx(player.rotation.y, start_yaw)
		and is_equal_approx(head.rotation.x, start_pitch),
		"Released controls ignore mouse look")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	player.call("_unhandled_input", click)
	_check(bool(player.get("controls_active")), "Left click resumes player controls")
	Input.action_press("move_forward")
	await _frames(20)
	_release_actions()
	_check(player.global_position.z < start.z - 0.7,
		"Movement works again after resuming")


func _test_reset() -> void:
	await _reset()
	player.global_position = Vector3(4.0, 3.0, 2.0)
	player.rotation.y = 0.8
	head.rotation.x = 0.6
	player.velocity = Vector3(3.0, 4.0, 5.0)
	player.call("reset_player")
	_check(player.global_transform.is_equal_approx(spawn),
		"Reset restores the starting position and orientation")
	_check(player.velocity.is_zero_approx(), "Reset clears movement velocity")
	_check(absf(head.rotation.x) < 0.001, "Reset restores camera pitch")
	await _frames(40)
	player.global_position = Vector3(-3.0, 2.0, 2.0)
	var reset_key := InputEventKey.new()
	reset_key.physical_keycode = KEY_R
	reset_key.pressed = true
	player.call("_unhandled_input", reset_key)
	await _frames(2)
	_check(absf(player.global_position.x - spawn.origin.x) < 0.01
		and absf(player.global_position.z - spawn.origin.z) < 0.01,
		"The reset action returns the player to spawn")


func _reset() -> void:
	_release_actions()
	player.call("set_controls_active", true)
	player.call("reset_player")
	await _frames(40)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
		await process_frame


func _mouse_motion(relative: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.relative = relative
	player.call("_unhandled_input", event)


func _release_actions() -> void:
	for action in ACTIONS:
		Input.action_release(action)


func _check(condition: bool, description: String) -> void:
	if condition:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		print("FAIL: ", description)


func _finish() -> void:
	_release_actions()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("CHECKS passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
