extends Node
class_name StateMachine

@export var states : Dictionary
@export var transitions : Dictionary

@export var initial_state : String

@export var print_transitions : bool

var target : Object
var current_state
var states_node
var can_transition = true

var state_instances = {}

#var expression : Expression

func _ready() -> void:
#	expression = Expression.new()
	target = get_parent()
	states_node = Node.new()
	states_node.name = 'States'
	target.add_child.call_deferred(states_node)
	init_state_machine()
	set_initial_state(initial_state)
	
	for transition_entry in transitions.values():
		for condition in transition_entry:
			condition['expression'] = Expression.new()
			var error = condition['expression'].parse(condition.condition)
			if error != OK:
				push_error(condition['expression'].get_error_text())
				return

func init_state_machine():
	for key in states.keys():
		create_state(key, states[key])

func create_state(state_name, data: Dictionary):
	var state = State.new()
	state.name = state_name
	
	var on_enter = data.get('on_enter')
	if on_enter:
		var on_enter_node = Node.new()
		on_enter_node.set_script(load(on_enter.get('script')))
		if 'source' in on_enter_node:
			on_enter_node.source = target
		state.add_child(on_enter_node)
		state.on_enter_func = Callable(on_enter_node, on_enter.get('function'))
		
	var on_update = data.get('on_update')
	if on_update:
		var on_update_node = Node.new()
		on_update_node.set_script(load(on_update.get('script')))
		if 'source' in on_update_node:
			on_update_node.source = target
		state.add_child(on_update_node)
		state.on_update_func = Callable(on_update_node, on_update.get('function'))
		
	var on_physics_update = data.get('on_physics_update')
	if on_physics_update:
		var on_physics_update_node = Node.new()
		on_physics_update_node.set_script(load(on_physics_update.get('script')))
		if 'source' in on_physics_update_node:
			on_physics_update_node.source = target
		state.add_child(on_physics_update_node)
		state.on_physics_func = Callable(on_physics_update_node, on_physics_update.get('function'))
		
	var on_exit = data.get('on_exit')
	if on_exit:
		var on_exit_node = Node.new()
		on_exit_node.set_script(load(on_exit.get('script')))
		if 'source' in on_exit_node:
			on_exit_node.source = target
		state.add_child(on_exit_node)
		state.on_exit_func = Callable(on_exit_node, on_exit.get('function'))
		
	states_node.add_child(state)
	
	state_instances[state_name] = state

func set_initial_state(state, skip_on_enter=false):
	current_state = state
	if !skip_on_enter:
		state_instances[state].on_enter()

func transition(next_state):
	if !can_transition:
		return
	if !current_state:
		push_error('Current state is not set. Make sure ti set initial state before transition')
	state_instances[current_state].on_exit()
	current_state = next_state
	state_instances[next_state].on_enter()
	
func evaluate_expressions():
	for t in transitions[current_state]:
		#var error = expression.parse(t.condition)
		#if error != OK:
			#push_error(expression.get_error_text())
			#return
		var result = t.expression.execute([], target)
		if result:
			if print_transitions:
				print('Transition to ' + t.to)
			transition(t.to)
	
func _process(delta):
	if !current_state:
		return
	evaluate_expressions()
	state_instances[current_state].on_update(delta)

func _physics_process(delta):
	if !current_state:
		return
	state_instances[current_state].on_physics_update(delta)
