extends Node

var source : PlayerController

func idle_physics_update(delta):
	source.move(source.velocity, source.acc, source.fric, source.speed, source.camera, delta)

func walk_physics_update(delta):
	source.move(source.velocity, source.acc, source.fric, source.speed, source.camera, delta)
	
func run_physics_update(delta):
	source.move(source.velocity, source.acc, source.fric, source.sprint_speed, source.camera, delta)
	
func air_physics_update(delta):
	source.move(source.velocity, source.air_acc, source.air_fric, source.speed, source.camera, delta)
	
