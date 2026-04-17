extends Resource
class_name StateMachineNode

@export var state : StateMachineState
@export var transitions : Array
@export var initial_state : bool

@export var meta : Dictionary = {
	'position': Vector2()
}

func _init(_state = null, _transitions = [], _initial_state = false) -> void:
	state = _state
	transitions = _transitions
	initial_state = _initial_state
	
