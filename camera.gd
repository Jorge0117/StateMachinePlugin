extends Camera3D

@export var max_vert = 80
@export var min_vert = -65

@export var bob_freq := 10.0
@export var bob_amp := 0.3

@onready var player = $"../.."
var input_dir : Vector2
var bob_time := 0.0

var last_step_sine : float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if current && event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		input_dir = event.screen_relative * 0.3

func _process(delta: float) -> void:
	rotation.x -= input_dir.y * delta
	rotation.x = clamp(rotation.x, deg_to_rad(min_vert), deg_to_rad(max_vert))
	player.rotation.y -= input_dir.x * delta
	
	input_dir = Vector2.ZERO
	
func _physics_process(delta: float) -> void:
	var normalized_speed : float = clamp(player.velocity.length() / player.sprint_speed, 0.0, 1.0)
	
	if player.is_on_floor() and player.velocity.length() > 0.1:
		bob_time += delta * bob_freq * normalized_speed
	else:
		bob_time = lerp(bob_time, 0.0, delta * 5.0)
	
	var wave = sin(bob_time)
	if sign(wave) != sign(last_step_sine):
		if wave > 0 and player.is_on_floor() and player.velocity.length() > 0.2:
			# play step sound here
			pass
		last_step_sine = wave
	
	var target = headbob(bob_time, normalized_speed)
	
	transform.origin = transform.origin.lerp(target, delta * 10.0)
	
	
func headbob(time: float, speed_factor: float) -> Vector3:
	var pos = Vector3.ZERO
	
	var wave = sin(time)
	
	pos.y = abs(wave) * bob_amp * speed_factor
	pos.x = cos(time * 0.5) * bob_amp * 0.8 * speed_factor
	pos.z = sin(time * 0.5) * bob_amp * 0.5 * speed_factor
	
	return pos
