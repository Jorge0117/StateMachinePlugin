@tool
extends Resource
class_name StateMachineNode

@export var name : String
@export var state : StateMachineState
@export var transitions : Array[StateMachineTransition] :
	set(value):
		transitions = value
		setup()
@export var initial_state : bool

@export var meta : Dictionary = {
	'position': Vector2(),
	'collapsed': false
}

func _init(_name ='', _state = null, _transitions = [] as Array[StateMachineTransition], _initial_state = false) -> void:
	name = _name
	state = _state
	transitions = _transitions
	initial_state = _initial_state
	
func setup() -> void:
	for transition in transitions:
		if transition:
			if !transition.changed.is_connected(on_transition_change):
				transition.changed.connect(on_transition_change)
				
func on_transition_change() -> void:
	emit_changed()
	
func parse_transitions() -> bool:
	var success := true
	for transition in transitions:
		success = transition.parse_expression()
		if !success:
			return false
	return success

func add_transition(transition:StateMachineTransition):
	transitions.append(transition)
	if !transition.changed.is_connected(on_transition_change):
		transition.changed.connect(on_transition_change)
	emit_changed()

func remove_transition(transition : StateMachineTransition):
	transitions.erase(transition)
	emit_changed()

func move_transition_up(transition : StateMachineTransition):
	var index := transitions.find(transition)
	if index == 0:
		return
	var other_transition := transitions[index - 1]
	transitions[index] = other_transition
	transitions[index -1] = transition
	emit_changed()
	
func move_transition_down(transition : StateMachineTransition):
	var index := transitions.find(transition)
	if index == transitions.size() - 1:
		return
	var other_transition := transitions[index + 1]
	transitions[index] = other_transition
	transitions[index + 1] = transition
	emit_changed()

func set_position(new_position : Vector2) -> void:
	meta.position = new_position
	emit_changed()
