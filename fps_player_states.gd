extends Node

var source : PlayerController

func idle_enter():
	#if source.anim_tree:
		#source.anim_tree.set('parameters/Transition/transition_request', 'Idle')
	#source.running = false
	pass

func idle_physics_update(delta):
	source.move(source.velocity, source.acc, source.fric, source.speed, source.camera, delta)
	if !Input.is_action_pressed("Run"):
		source.running = false

func walk_enter():
	pass
	#source.anim_tree.set('parameters/Transition/transition_request', 'Walk')

func walk_physics_update(delta):
	source.move(source.velocity, source.acc, source.fric, source.speed, source.camera, delta)
	
func run_enter():
	pass
	#source.anim_tree.set('parameters/Transition/transition_request', 'Run')
	
func run_physics_update(delta):
	source.move(source.velocity, source.acc, source.fric, source.sprint_speed, source.camera, delta)
	
func air_enter():
	if source.crouched or source.crouch_amount > 0.0:
		source.force_stand()
	pass
	
func air_physics_update(delta):
	source.move(source.velocity, source.air_acc, source.air_fric, source.speed, source.camera, delta)
	var vertical_speed := Vector3(source.velocity.x, 0, source.velocity.z).length()
	if vertical_speed > source.speed:
		source.running = true
	if source.on_valid_wall() and !source.is_on_floor() and source.velocity.length() >= 5.0 and source.can_wall_run:
		source.start_wall_run()
		
func air_exit():
	if !source.wall_running:
		source.audioPlayer.play_sound('Player/Land')
	else:
		source.audioPlayer.play_sound('Player/GrabWall')

func wall_run_enter():
	if source.velocity.y < 0:
		source.velocity.y += 1
	source.wall_run_step()
	
func wall_run_physics_update(delta):
	source.wall_run(delta)
	
func wall_run_exit():
	source.wall_running = false
	source.on_wall_run_exit()

func crouch_enter():
	#source.crouch_amount = 0.0
	source.audioPlayer.play_sound('Player/Crouch')
	source.running = false

func crouch_physics_update(delta):
	if !Input.is_action_pressed("Run"):
		source.running = false
	if source.crouch_amount < 1.0 and source.crouched:
		source.camera_pivot.position.y = lerp(source.initial_cam_pos.y, source.initial_cam_pos.y / 2, source.crouch_amount)
		source.collider.shape.height = lerp(source.initial_collider_height, source.initial_collider_height / 2, source.crouch_amount)
		source.collider.position.y = lerp(source.initial_collider_pos.y, source.initial_collider_pos.y / 2, source.crouch_amount)
		source.crouch_amount += delta * 10
		if source.crouch_amount >= 1.0:
			source.crouch_amount = 1.0
	if !source.can_stand():
		source.can_jump = false
	source.move(source.velocity, source.acc, source.fric, source.crouch_speed, source.camera, delta)
	if source.crouch_amount > 0.0 and !source.crouched and source.is_on_floor():
		if !source.can_stand():
			source.crouched = true
		else:
			source.camera_pivot.position.y = lerp(source.initial_cam_pos.y / 2, source.initial_cam_pos.y, 1.0 - source.crouch_amount)
			source.collider.shape.height = lerp(source.initial_collider_height / 2, source.initial_collider_height, 1.0 - source.crouch_amount)
			source.collider.position.y = lerp(source.initial_collider_pos.y / 2, source.initial_collider_pos.y, 1.0 - source.crouch_amount)
			source.crouch_amount -= delta * 10
			if source.crouch_amount <= 0.0:
				source.crouch_amount = 0.0
	
func crouch_exit():
	source.audioPlayer.play_sound('Player/Crouch')

func slide_enter():
	#source.crouch_amount = 0.0
	source.audioPlayer.play_sound('Player/Slide')
	source.slide_dir = Vector3(source.velocity.x, 0, source.velocity.z).normalized()
	source.force_end_slide = false
	await get_tree().create_timer(source.slide_duration).timeout
	if source.state_machine.current_state.name == 'Slide':
		source.crouched = false
		source.force_end_slide = true

func slide_physics_update(delta):
	if source.crouch_amount < 1.0 and source.crouched:
		source.camera_pivot.position.y = lerp(source.initial_cam_pos.y, source.initial_cam_pos.y / 2, source.crouch_amount)
		source.collider.shape.height = lerp(source.initial_collider_height, source.initial_collider_height / 2, source.crouch_amount)
		source.collider.position.y = lerp(source.initial_collider_pos.y, source.initial_collider_pos.y / 2, source.crouch_amount)
		source.crouch_amount += delta * 13
		if source.crouch_amount >= 1.0:
			source.crouch_amount = 1.0
	source.slide(delta)
	if source.crouch_amount > 0.0 and (!source.crouched or source.force_end_slide):
		if !source.can_stand():
			source.crouched = true
			source.velocity = source.velocity.normalized() * source.speed
		else:
			source.camera_pivot.position.y = lerp(source.initial_cam_pos.y / 2, source.initial_cam_pos.y, 1.0 - source.crouch_amount)
			source.collider.shape.height = lerp(source.initial_collider_height / 2, source.initial_collider_height, 1.0 - source.crouch_amount)
			source.collider.position.y = lerp(source.initial_collider_pos.y / 2, source.initial_collider_pos.y, 1.0 - source.crouch_amount)
			source.crouch_amount -= delta * 13
			if source.crouch_amount <= 0.0:
				source.crouch_amount = 0.0
