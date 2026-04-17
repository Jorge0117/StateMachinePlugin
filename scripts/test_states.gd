extends Node

var source : SpriteController

func idle_enter():
	source.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
func idle_exit():
	source.modulate = Color(randf(), randf(), randf(), 1.0)

func physics_update(delta):
	source.position += source.input_dir * source.speed * delta
