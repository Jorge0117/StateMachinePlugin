extends Resource
class_name StateMachineState

@export var on_enter : Dictionary[String, String] = {'script' : '', 'function': ''}
@export var on_update : Dictionary[String, String] = {'script' : '', 'function': ''}
@export var on_physics_update : Dictionary[String, String] = {'script' : '', 'function': ''}
@export var on_exit : Dictionary[String, String] = {'script' : '', 'function': ''}

@export var meta : Dictionary = {
	'collapsed': false
}

func _init() -> void:
	pass
