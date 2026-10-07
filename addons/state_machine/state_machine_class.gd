extends Node
class_name StateMachine

@export var state_machine_resource : StateMachineResource

@export var print_transitions : bool

var target : Object
var current_state : StateMachineNode
var states_node
var can_transition = true

var state_instances = {}

#var expression : Expression

func _ready() -> void:
	target = get_parent()
	states_node = Node.new()
	states_node.name = 'States'
	target.add_child.call_deferred(states_node)
	init_state_machine()
	var initial_state = state_machine_resource.get_initial_state()
	assert(initial_state != null, 'State machine doesn\'t have an initial state')
	current_state = initial_state
		
	set_initial_state.call_deferred(initial_state)
	
	var success := state_machine_resource.parse_expressions()
	assert(success, 'Could not parse state machine expressions')

func init_state_machine():
	for state in state_machine_resource.states:
		create_state(state.name, state.state)

func create_state(state_name, state_data: StateMachineState):
	var state = State.new()
	state.name = state_name
	
	var on_enter : StateMachineStateStep = state_data.on_enter
	if on_enter.is_valid():
		var on_enter_node = Node.new()
		on_enter_node.set_script(load(on_enter.get('path')))
		if 'source' in on_enter_node:
			on_enter_node.source = target
		state.add_child(on_enter_node)
		state.on_enter_func = Callable(on_enter_node, on_enter.get('function'))
		
	var on_update : StateMachineStateStep = state_data.on_update
	if on_update.is_valid():
		var on_update_node = Node.new()
		on_update_node.set_script(load(on_update.get('path')))
		if 'source' in on_update_node:
			on_update_node.source = target
		state.add_child(on_update_node)
		state.on_update_func = Callable(on_update_node, on_update.get('function'))
		
	var on_physics_update : StateMachineStateStep = state_data.on_physics_update
	if on_physics_update.is_valid():
		var on_physics_update_node = Node.new()
		on_physics_update_node.set_script(load(on_physics_update.get('path')))
		if 'source' in on_physics_update_node:
			on_physics_update_node.source = target
		state.add_child(on_physics_update_node)
		state.on_physics_func = Callable(on_physics_update_node, on_physics_update.get('function'))
		
	var on_exit : StateMachineStateStep = state_data.on_exit
	if on_exit.is_valid():
		var on_exit_node = Node.new()
		on_exit_node.set_script(load(on_exit.get('path')))
		if 'source' in on_exit_node:
			on_exit_node.source = target
		state.add_child(on_exit_node)
		state.on_exit_func = Callable(on_exit_node, on_exit.get('function'))
		
	states_node.add_child(state)
	
	state_instances[state_name] = state

func set_initial_state(state : StateMachineNode, skip_on_enter=false):
	current_state = state
	if !skip_on_enter:
		state_instances[state.name].on_enter()

func transition(next_state : StateMachineNode):
	if !can_transition:
		return
	if !current_state:
		push_error('Current state is not set. Make sure ti set initial state before transition')
	state_instances[current_state.name].on_exit()
	current_state = next_state
	state_instances[next_state.name].on_enter()
	
func evaluate_expressions():
	for tran : StateMachineTransition in current_state.transitions:
		var result = tran.expression.execute([], target)
		if result:
			if print_transitions:
				print('Transition to ' + tran.target)
			var target_node := state_machine_resource.get_node_by_name(tran.target)
			assert(target_node != null, 'Could not find transition target %s' % tran.target)
			
			transition(target_node)
	
	
func _process(delta):
	if !current_state:
		return
	evaluate_expressions()
	state_instances[current_state.name].on_update(delta)

func _physics_process(delta):
	if !current_state:
		return
	state_instances[current_state.name].on_physics_update(delta)
