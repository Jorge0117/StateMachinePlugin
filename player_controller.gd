extends CharacterBody3D

class_name PlayerController

@export var speed := 4.0
@export var sprint_speed := 8.0
@export var acc := 20.0
@export var fric := 50.0
@export var air_acc := 15.0
@export var air_fric := 2.0
@export var jump_velocity := 4.0
@export var up_gravity := 9.8
@export var down_gravity := 18.0
@export var coyote_time := 0.2
@export var jump_buffer := 0.2

@export var wall_run_speed = 8.0
@export var wall_run_down_gravity = 4.0
@export var wall_run_up_gravity = 8.0

@export var crouch_speed := 2.0
@export var slide_speed := 9.0
@export var slide_duration := 1.0

@export var hide_timer := false

@onready var collider : CollisionShape3D = $CollisionShape3D
@onready var camera : CameraController = %Camera
@onready var camera_pivot : Node3D = $CameraPivot
@onready var state_machine : StateMachine = $StateMachine

@onready var bottom_shapecast : ShapeCast3D = %BottomShapeCast
@onready var top_shapecast : ShapeCast3D = %TopShapeCast
@onready var jump_buffer_timer : Timer = %JumpBufferTimer

var jump_buffer_time := 0.0

var prev_frame_on_floor = false
var can_jump = false
var jumping = false
var force_down_gravity = false

var running := false
var wall_running := false
var wall_run_dir := Vector3()
var wall_run_normal := Vector3()

var crouched := false
var sliding := false
var initial_cam_pos
var initial_collider_height
var initial_collider_pos
var crouch_amount := 0.0
var force_end_slide := false

var slide_dir := Vector3()

var external_velocity := Vector3()

var in_cutscene := false

var rotation_tween : Tween

var can_wall_run := true

func _ready() -> void:
	Engine.time_scale = 1.0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	initial_cam_pos = camera_pivot.position
	initial_collider_height = collider.shape.height
	initial_collider_pos = collider.position
		
func handle_jump_buffer(delta: float) -> void:
	if jump_buffer_time > 0.0:
		jump_buffer_time -= delta
		
	
func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed:
		#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			#
	#if event.is_action_pressed("Pause"):
		#ui.pause()
			
	if in_cutscene:
		return
		
	if event.is_action_pressed('Jump'):
		jump_buffer_time = jump_buffer
		
	if event.is_action_pressed("Restart"):
		restart()
		
	if event.is_action_pressed("Run"):
		running = true
	
	if event.is_action_pressed("Crouch") and !state_machine.current_state.name == 'Slide' and is_on_floor():
		crouched = !crouched


func move(prev_velocity, acceleration, friction, move_speed, target_camera : Camera3D, delta) -> void:
	handle_jump_buffer(delta)
	var next_velocity := Vector3.ZERO
	var input_dir := Vector2.ZERO
	if !in_cutscene:
		input_dir = Input.get_vector("Left", "Right", "Up", "Down")

	var forward := target_camera.global_basis.z
	var right := target_camera.global_basis.x
	
	var direction := forward * input_dir.y + right * input_dir.x
	direction.y = 0.0
	direction = direction.normalized()
	
	var y_velocity = prev_velocity.y
	next_velocity.y = 0.0
	
	#Air control
	if !is_on_floor():
		var horizontal_vel := Vector3(prev_velocity.x, 0, prev_velocity.z)
		if direction.length() > 0:
			var wish_dir = direction.normalized()
			var wish_speed = move_speed  # you can tweak this
			
			var current_speed = horizontal_vel.dot(wish_dir)
			var add_speed = wish_speed - current_speed
			
			if add_speed > 0:
				# Source-style acceleration
				var accel_amount = acceleration * wish_speed * delta
				
				if accel_amount > add_speed:
					accel_amount = add_speed
				
				horizontal_vel += wish_dir * accel_amount
		next_velocity = Vector3(horizontal_vel.x, 0, horizontal_vel.z)
	else:
		if(direction.length() > 0) and Vector3(velocity.x, 0, velocity.z).length() < move_speed:
			next_velocity = prev_velocity.move_toward(direction * move_speed, acceleration * delta)
		else:
			next_velocity = prev_velocity.move_toward(direction * move_speed, friction * delta)
	
	if(y_velocity > 0 and !force_down_gravity):
		next_velocity.y = y_velocity - up_gravity * delta
	else:
		next_velocity.y = y_velocity - down_gravity * delta
	velocity =  next_velocity + external_velocity
	external_velocity = Vector3.ZERO
	
	if is_on_floor():
		force_down_gravity = false
		can_jump = true
		jumping = false
		
		if crouched and !can_stand():
			can_jump = false
	else:
		if prev_frame_on_floor and !jumping:
			start_coyote_time()
		if Input.is_action_just_released("Jump") and jumping:
			force_down_gravity = true

	if can_jump and jump_buffer_time > 0.0 and !in_cutscene:
		jump_buffer_time = 0.0
		velocity.y = jump_velocity
		can_jump = false
		jumping = true
		crouched = false
		force_stand()
		#audioPlayer.play_sound('Player/Jump')
	prev_frame_on_floor = is_on_floor()
	move_and_slide()

func start_coyote_time():
	can_jump = true
	await get_tree().create_timer(coyote_time).timeout
	if !is_on_floor():
		can_jump = false

func force_stand():
	var tween_cam = create_tween()
	tween_cam.tween_property(camera_pivot, "position:y", initial_cam_pos.y, 0.5)
	#camera_pivot.position.y = initial_cam_pos.y
	var tween_coll_height = create_tween()
	tween_coll_height.tween_property(collider.shape, "height", initial_collider_height, 0.5)
	#collider.shape.height = initial_collider_height
	var tween_pos_height = create_tween()
	tween_pos_height.tween_property(collider, "position:y", initial_collider_pos.y, 0.5)
	#collider.position.y = initial_collider_pos.y
	crouch_amount = 0.0
	
func on_valid_wall() -> bool:
	bottom_shapecast.force_shapecast_update()
	top_shapecast.force_shapecast_update()
	if bottom_shapecast.get_collision_count() == 0:
		return false
	if top_shapecast.get_collision_count() == 0:
		return false
		
	var normal_bottom = bottom_shapecast.get_collision_normal(0)
	var normal_top = top_shapecast.get_collision_normal(0)
	
	if abs(normal_bottom.y) > 0.2 or abs(normal_top.y) > 0.2:
		return false
		
	var collider_bottom = bottom_shapecast.get_collider(0)
	var collider_top = top_shapecast.get_collider(0)
	if collider_bottom != collider_top:
		return false
		
	if normal_bottom.dot(normal_top) < 0.9:
		return false
		
	return true

func start_wall_run():
	var wall_normal := bottom_shapecast.get_collision_normal(0)
	wall_normal.y = 0
	wall_normal = wall_normal.normalized()
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var dot = forward.dot(wall_normal)
	
	var move_dir = Vector3(velocity.x, 0, velocity.z)
	if move_dir.length() < 0.1:
		return
	move_dir = move_dir.normalized()
	

	if abs(dot) <= 0.9 and move_dir.dot(forward) > 0.2 :
		wall_running = true
		var dir = wall_normal.cross(Vector3.UP).normalized()
		if dir.dot(forward) < 0:
			dir = dir * -1
		wall_run_dir = dir
		wall_run_normal = wall_normal
		
		var target_dir = wall_run_dir
		target_dir.y = 0
		target_dir = target_dir.normalized()
		var target_rot = atan2(-target_dir.x, -target_dir.z)
		var delta_angle = wrapf(target_rot - rotation.y, -PI, PI)
		var final_rot = rotation.y + delta_angle
		if rotation_tween and rotation_tween.is_valid() and rotation_tween.is_running():
			rotation_tween.kill()
		rotation_tween = create_tween()
		rotation_tween.tween_property(self, 'rotation:y', final_rot, 0.15)

func stop_wall_run() -> bool:
	if !on_valid_wall():
		return true
		
	var h_velocity := Vector3(velocity.x, 0.0, velocity.z)
	if h_velocity.length() <= 0.1:
		return true

	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var dot = forward.dot(wall_run_normal)
	if abs(dot) > 0.9:
		return true
	
	return false

func get_wall_contacts() -> Array:
	var normals := []
	for i in get_slide_collision_count():
		var col = get_slide_collision(i)
		if abs(col.get_normal().y) < 0.2: # ignore floor/ceiling
			normals.append(col.get_normal())
	return normals
		
func wall_run(delta):
	#update wall normal in case it changed
	handle_jump_buffer(delta)
	var wall_normal := bottom_shapecast.get_collision_normal(0)
	wall_normal.y = 0
	wall_normal = wall_normal.normalized()
	if abs(wall_normal.dot(wall_run_normal)) < 0.8:
		wall_run_normal = wall_normal
		var dir = wall_normal.cross(Vector3.UP).normalized()
		var forward := -camera.global_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		if dir.dot(forward) < 0:
			dir = dir * -1
		wall_run_dir = dir
		
	var next_velocity := Vector3.ZERO
	var y_velocity = velocity.y
	next_velocity.y = 0.0
	
	if Vector3(velocity.x, 0, velocity.z).length() < wall_run_speed:
		next_velocity = velocity.move_toward(wall_run_dir * wall_run_speed, acc * delta)
	else:
		next_velocity = velocity.move_toward(wall_run_dir * wall_run_speed, fric * delta)
		
	if y_velocity < 0:
		next_velocity.y = lerp(y_velocity, -2.0, 6.0 * delta)
	else:
		next_velocity.y = y_velocity
		
	next_velocity.y -= wall_run_down_gravity * delta
	
	# Force towards the wall so is_on_wall is true
	next_velocity -= wall_run_normal * 5.0 * delta
	
	if jump_buffer_time > 0.0:
		jump_buffer_time = 0.0
		var forward := -camera.global_basis.z
		forward.y = 0.0
		forward = forward.normalized()
		
		var jump_dir = (wall_run_normal * 1.3 + Vector3.UP ).normalized()
		
		next_velocity = Vector3(next_velocity.x, 0.0, next_velocity.z) + jump_dir * jump_velocity * 2
		
		can_jump = false
		jumping = true
		force_down_gravity = false
	
	velocity = next_velocity
	move_and_slide()
	
func wall_run_step():
	await get_tree().create_timer(0.25).timeout
	if wall_running:
		wall_run_step()
		
func on_wall_run_exit():
	can_wall_run = false
	await get_tree().create_timer(0.25).timeout
	can_wall_run = true

func can_stand():
	var space_state := get_world_3d().direct_space_state
	var from = Vector3(global_position.x, global_position.y + initial_collider_height / 2, global_position.z)
	var to = Vector3(global_position.x, global_position.y + initial_collider_height, global_position.z)
	var query = PhysicsRayQueryParameters3D.create(from, to, 0b1001) #Collision mask 1 and 4
	query.collide_with_areas = true
	var result := space_state.intersect_ray(query)
	if result.size() > 0:
		if result.collider is StaticBody3D:
			return false
	return true

func can_slide():
	return Vector3(velocity.x, 0, velocity.z).length() > speed

func slide(delta):
	handle_jump_buffer(delta)
	var next_velocity := Vector3.ZERO
	next_velocity.y = 0.0
	
	next_velocity = velocity.move_toward(slide_dir * slide_speed, acc * delta)
	if jump_buffer_time > 0:
		jump_buffer_time = 0
		next_velocity.y = jump_velocity
		can_jump = false
		jumping = true
		crouched = false
	velocity = next_velocity
	move_and_slide()

func apply_force(force : Vector3):
	external_velocity += force

	
func freeze_frame(timescale, duration):
	Engine.time_scale = timescale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
	
func play_step():
	pass


func restart():
	collider.shape.height = initial_collider_height
	get_tree().reload_current_scene()
	
