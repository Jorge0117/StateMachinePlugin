extends Camera3D
class_name CameraController

@export var max_vert = 80
@export var min_vert = -65

@export var bob_freq := 10.0
@export var bob_amp := 0.3

@onready var player : PlayerController = $"../.."
@onready var pivot := $".."
var input_dir : Vector2
var bob_time := 0.0

var last_step_sine : float = 0.0

var starting_pivot_pos : Vector3
var shake_magnitude : float
var shake_duration : float

func _ready() -> void:
	starting_pivot_pos = pivot.position

func _unhandled_input(event: InputEvent) -> void:
	if current && event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and !player.in_cutscene:
		input_dir = event.screen_relative * (15 * 0.0001)
		rotation.x -= input_dir.y
		rotation.x = clamp(rotation.x, deg_to_rad(min_vert), deg_to_rad(max_vert))
		player.rotation.y -= input_dir.x

func _process(delta: float) -> void:
	if !current or player.in_cutscene:
		return

	var look_x = Input.get_action_strength("LookRight") - Input.get_action_strength("LookLeft")
	var look_y = Input.get_action_strength("LookDown") - Input.get_action_strength("LookUp")

	var deadzone := 0.1
	var stick_input := Vector2(look_x, look_y)

	if stick_input.length() < deadzone:
		return

	var controller_sens := 15 * 0.25

	stick_input *= controller_sens * delta

	rotation.x -= stick_input.y
	rotation.x = clamp(rotation.x, deg_to_rad(min_vert), deg_to_rad(max_vert))
	player.rotation.y -= stick_input.x

func _physics_process(delta: float) -> void:
	var normalized_speed : float = clamp(player.velocity.length() / player.sprint_speed, 0.0, 1.0)
	
	if player.is_on_floor() and player.velocity.length() > 0.1 and player.state_machine.current_state.name != 'Slide':
		bob_time += delta * bob_freq * normalized_speed
	else:
		bob_time = lerp(bob_time, 0.0, delta * 5.0)
	var wave = sin(bob_time)
	if sign(wave) != sign(last_step_sine):
		if abs(wave) > 0 and player.is_on_floor() and player.velocity.length() > 0.2 and player.state_machine.current_state in ['Walk', 'Run']:
			player.play_step()
		last_step_sine = wave
	
	var target = headbob(bob_time, normalized_speed if player.is_on_floor() and player.state_machine.current_state.name != 'Slide' else 0.0)
	
	
	
	var shake_offset = Vector3.ZERO
	if shake_duration > 0.0 or shake_duration <= -1:
		shake_offset = Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		) * shake_magnitude
		if shake_duration > 0:
			shake_duration = shake_duration - delta

	var combined_target = target + shake_offset
	if shake_offset != Vector3.ZERO:
		transform.origin = combined_target
	else:
		transform.origin = transform.origin.lerp(combined_target, delta * 10.0)
	
func headbob(time: float, speed_factor: float) -> Vector3:
	var pos = Vector3.ZERO
	
	var wave = sin(time)
	
	pos.y = abs(wave) * bob_amp * speed_factor
	pos.x = cos(time) * bob_amp * 0.5 * speed_factor
	pos.z = sin(time * 0.5) * bob_amp * 0.3 * speed_factor
	
	return pos

func camera_shake(magnitude, duration):
	shake_magnitude = magnitude
	shake_duration = duration
