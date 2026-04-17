@tool
extends Node

class_name State

var on_enter_func : Callable
var on_update_func : Callable
var on_physics_func : Callable
var on_exit_func : Callable

func on_enter():
	if on_enter_func:
		on_enter_func.call()
	
func on_update(_delta):
	if on_update_func:
		on_update_func.call(_delta)
	
func on_physics_update(_delta):
	if on_physics_func:
		on_physics_func.call(_delta)
	
func on_exit():
	if on_exit_func:
		on_exit_func.call()
	
