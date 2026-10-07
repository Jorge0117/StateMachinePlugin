@tool
extends Resource
class_name StateMachineState

@export var on_enter : StateMachineStateStep
@export var on_update : StateMachineStateStep
@export var on_physics_update : StateMachineStateStep
@export var on_exit : StateMachineStateStep


func _init() -> void:
	on_enter = StateMachineStateStep.new()
	on_update = StateMachineStateStep.new()
	on_physics_update = StateMachineStateStep.new()
	on_exit = StateMachineStateStep.new()
