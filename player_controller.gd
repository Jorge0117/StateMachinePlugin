extends CharacterBody3D

class_name PlayerController

@export var speed = 4.0
@export var sprint_speed = 8.0
@export var acc = 20.0
@export var fric = 50.0
@export var air_acc = 15.0
@export var air_fric = 2.0
@export var jump_velocity = 4.0
@export var up_gravity = 9.8
@export var down_gravity = 18.0
@export var coyote_time = 0.2

@onready var collider : CollisionShape3D = $CollisionShape3D
@onready var camera : Camera3D = %Camera

var prev_frame_on_floor = false
var can_jump = false
var jumping = false
var force_down_gravity = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func is_running():
	return Input.is_action_pressed('Run')

func move(prev_velocity, acceleration, friction, move_speed, target_camera : Camera3D, delta) -> void:
	var next_velocity := Vector3.ZERO
	var input_dir := Input.get_vector("Left", "Right", "Up", "Down")
	var forward := target_camera.global_basis.z
	var right := target_camera.global_basis.x
	
	var direction := forward * input_dir.y + right * input_dir.x
	direction.y = 0.0
	direction = direction.normalized()
	
	var y_velocity = prev_velocity.y
	next_velocity.y = 0.0
	
	if(direction.length() > 0) and Vector3(velocity.x, 0, velocity.z).length() < move_speed:
		next_velocity = prev_velocity.move_toward(direction * move_speed, acceleration * delta)
	else:
		next_velocity = prev_velocity.move_toward(direction * move_speed, friction * delta)
	
	if(y_velocity > 0 and !force_down_gravity):
		next_velocity.y = y_velocity - up_gravity * delta
	else:
		next_velocity.y = y_velocity - down_gravity * delta
	velocity =  next_velocity
	
	if(is_on_floor()):
		force_down_gravity = false
		can_jump = true
		jumping = false
	else:
		if prev_frame_on_floor and !jumping:
			start_coyote_time()
		if Input.is_action_just_released("Jump"):
			force_down_gravity = true

	if can_jump and Input.is_action_just_pressed("Jump"):
		velocity.y = jump_velocity
		can_jump = false
		jumping = true
	prev_frame_on_floor = is_on_floor()
	move_and_slide()

func start_coyote_time():
	can_jump = true
	await get_tree().create_timer(coyote_time).timeout
	if !is_on_floor():
		can_jump = false
