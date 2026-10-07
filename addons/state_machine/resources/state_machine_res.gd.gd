@tool
extends Resource
class_name StateMachineResource

@export var states : Array[StateMachineNode] :
	set(value):
		states = value
		setup()

func _init(_states = [] as Array[StateMachineNode]) -> void:
	states = _states
	setup()

func on_state_change() -> void:
	emit_changed()
	
func setup():
	for state in states:
		if state:
			if !state.changed.is_connected(on_state_change):
				state.changed.connect(on_state_change)

func add_state(state : StateMachineNode):
	states.append(state)
	if !state.changed.is_connected(on_state_change):
		state.changed.connect(on_state_change)

func get_initial_state() -> StateMachineNode:
	for node in states:
		if node.initial_state:
			return node
	return null

func parse_expressions() -> bool:
	var success := true
	for node in states:
		success = node.parse_transitions()
		if !success:
			return false
	return true

func get_node_by_name(name : String) -> StateMachineNode:
	for node in states:
		if node.name == name:
			return node
	return null

func get_valid_name(name):
	if !has_node_with_name(name):
		return name
		
	var name_index := 1
	while true:
		var new_name := "%s (%d)" % [name, name_index]
		if !has_node_with_name(new_name):
			return new_name
		name_index += 1

func has_node_with_name(name) -> bool:
	for state in states:
		if state.name == name:
			return true
	return false
	
func remove_state(name):
	var node := get_node_by_name(name)
	states.erase(node)
