@tool
extends ScrollContainer

var states_tree : Tree
var states_tree_root : TreeItem
var add_state_button : Button

var add_icon : Texture2D
var remove_icon : Texture2D
var load_icon : Texture2D

var set_states : Callable
var set_transitions : Callable
var get_available_name : Callable

var state_machine : StateMachine

var graph : Graph
var graph_node_label : Label

var state_transitions : Dictionary
var add_transition_button : Button
var selected_node_index : int = -1

var resource_text : LineEdit
var create_resource_button : Button
var load_resource_button : Button

func _ready() -> void:
	add_icon = EditorInterface.get_base_control().get_theme_icon('Add', 'EditorIcons')
	remove_icon = EditorInterface.get_base_control().get_theme_icon('GuiClose', 'EditorIcons')
	load_icon = EditorInterface.get_base_control().get_theme_icon('Load', 'EditorIcons')
	
	states_tree = %StatesTree
	graph = %GraphEdit
	states_tree.item_edited.connect(on_tree_edited)
	states_tree.button_clicked.connect(on_tree_button)
	states_tree_root = states_tree.create_item()
	states_tree.hide_root = true
	
	add_state_button = %AddStateButton
	add_state_button.pressed.connect(add_state)
	
	graph.node_selected.connect(on_graph_node_selection_change)
	graph.node_deselected.connect(on_graph_node_selection_change)
	graph_node_label = %NodeNameLabel
	add_transition_button = %AddTransitionButton
	add_transition_button.pressed.connect(add_transition)
	add_transition_button.disabled = true
	
	resource_text = %ResourceText
	load_resource_button = %LoadResourceButton
	load_resource_button.icon = load_icon
	create_resource_button = %CreateResourceButton
	create_resource_button.icon = add_icon
	
func set_state_machine(new_state_machine):
	state_machine = new_state_machine
	if state_machine:
		%MainContainer.visible = true
		%ErrorLabel.visible = false
	else:
		%MainContainer.visible = false
		%ErrorLabel.visible = true
	
func on_tree_edited():
	var item_edited := states_tree.get_edited()
	
	#Name changed:
	if item_edited.is_editable(0):
		var old_name : String = item_edited.get_metadata(0)
		var new_name : String = get_available_name.call(item_edited.get_text(0))
		item_edited.set_text(0, new_name)
		item_edited.set_metadata(0, new_name)
		
		state_transitions[new_name] = state_transitions[old_name]
		state_transitions.erase(old_name)
		
		graph.update_node(item_edited)
		update_states()
		graph.set_selected(null)
		return
	
	#Select function
	if item_edited.get_cell_mode(1) == TreeItem.CELL_MODE_CHECK:
		for child in item_edited.get_parent().get_children():
			if child != item_edited:
				child.set_checked(1, false)
		update_states()
		return
	
func on_tree_button(item: TreeItem, colum, id, mouse_button):
	var item_name := item.get_text(0)
	if item_name not in ['on_enter', 'on_update', 'on_physics_update', 'on_exit']:
		graph.set_selected(null)
		graph.remove_node(item)
		state_transitions.erase(item_name)
		item.free()
		update_states()
		return
	if item.get_text(1) == '...':
		open_script_dialog(item)
	else:
		item.set_text(1, '...')
		item.set_button(1, 0, add_icon)
		for child in item.get_children():
			child.free()
		update_states()
		

func add_state():
	var default_name := 'State'
	default_name = get_available_name.call(default_name)
	var state = states_tree.create_item(states_tree_root)
	state.set_editable(0, true)
	state.set_text(0, default_name)
	state.add_button(1, remove_icon)
	
	state.set_metadata(0, default_name)
	
	var on_enter = states_tree.create_item(state)
	on_enter.set_text(0, 'on_enter')
	on_enter.set_text(1, '...')
	on_enter.add_button(1, add_icon)
	
	var on_update = states_tree.create_item(state)
	on_update.set_text(0, 'on_update')
	on_update.set_text(1, '...')
	on_update.add_button(1, add_icon)
	
	var on_physics_update = states_tree.create_item(state)
	on_physics_update.set_text(0, 'on_physics_update')
	on_physics_update.set_text(1, '...')
	on_physics_update.add_button(1, add_icon)
	
	var on_exit = states_tree.create_item(state)
	on_exit.set_text(0, 'on_exit')
	on_exit.set_text(1, '...')
	on_exit.add_button(1, add_icon)
	
	state_transitions[default_name] = []
	
	update_states()
	graph.add_node(state)
	
func open_script_dialog(tree_item):
	var script_dialog := EditorFileDialog.new()
	script_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	script_dialog.access = FileDialog.ACCESS_RESOURCES
	script_dialog.add_filter('*.gd', 'GDScript files')
	script_dialog.file_selected.connect(on_add_script.bind(tree_item))
	EditorInterface.get_base_control().add_child(script_dialog)
	script_dialog.popup_centered_ratio()
	
func on_add_script(path, tree_item: TreeItem):
	tree_item.set_text(1, path)
	tree_item.set_button(1, 0, remove_icon)
	
	var script : Script = load(path)
	var functions = script.get_script_method_list() 
	for function in functions:
		if not function.name.begins_with("_"):
			var tree_func = states_tree.create_item(tree_item)
			tree_func.set_text(0, function.name)
			tree_func.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			tree_func.set_editable(1, true)
	if tree_item.get_child_count() == 0:
		push_error("Coulnd't find any valid functions on script %d" % path)
		return
	tree_item.get_child(0).set_checked(1, true)
	update_states()

func update_states():
	var data = {}
	var root := states_tree.get_root()
	var tree_states := root.get_children()
	for state : TreeItem in tree_states:
		data[state.get_text(0)] = {}
		for param : TreeItem in state.get_children():
			if param.get_text(1) == '...':
				data[state.get_text(0)][param.get_text(0)] = {}
			else:
				data[state.get_text(0)][param.get_text(0)] = {'script': param.get_text(1)}
			for function : TreeItem in param.get_children():
				if function.is_checked(1):
					data[state.get_text(0)][param.get_text(0)]['function'] = function.get_text(0)
					
	set_states.call(data)
	set_transitions.call(state_transitions)
	#update_transition_dropdowns()

func load_states():
	for child in states_tree.get_root().get_children():
		child.free()
	for child in graph.get_children():
		if child is GraphNode:
			child.free()
	graph.nodes = []
	
	for state in state_machine.states.keys():
		var state_branch = states_tree.create_item(states_tree.get_root())
		state_branch.set_text(0, state)
		state_branch.set_editable(0, true)
		state_branch.add_button(1, remove_icon)
		
		graph.add_node(state_branch)
		
		for phase in ['on_enter', 'on_update', 'on_physics_update', 'on_exit']:
			var phase_branch = states_tree.create_item(state_branch)
			phase_branch.set_text(0, phase)
			if state_machine.states[state][phase] == {}:
				phase_branch.set_text(1, '...')
				phase_branch.add_button(1, add_icon)
			else:
				phase_branch.set_text(1, state_machine.states[state][phase]['script'])
				var script : Script = load(state_machine.states[state][phase]['script'])
				var functions = script.get_script_method_list() 
				for function in functions:
					if not function.name.begins_with("_"):
						var tree_func = states_tree.create_item(phase_branch)
						tree_func.set_text(0, function.name)
						tree_func.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
						tree_func.set_editable(1, true)
						if state_machine.states[state][phase]['function'] == function.name:
							tree_func.set_checked(1, true)
	graph.arrange_nodes()
	load_transitions()
	
func load_transitions():
	state_transitions = {}
	for key in state_machine.transitions.keys():
		state_transitions[key] = []
		for j in state_machine.transitions[key].size():
			state_transitions[key].append({
				'source': key,
				'to': state_machine.transitions[key][j].to,
				'condition':  state_machine.transitions[key][j].condition
			})

func on_graph_node_selection_change(node):
	var selected_nodes = []
	for child in graph.get_children():
		if child is GraphNode and child.selected:
			selected_nodes.push_back(child)
	if len(selected_nodes) == 0:
		graph_node_label.text = 'Select Node'
		add_transition_button.disabled = true
		selected_node_index = -1
	elif len(selected_nodes) > 1:
		graph_node_label.text = 'Select Single Node'
		add_transition_button.disabled = true
		selected_node_index = -1
	else:
		graph_node_label.text = selected_nodes[0].title
		add_transition_button.disabled = false
		var states = state_machine.states.keys()
		for i in range(states.size()):
			if states[i] == selected_nodes[0].title:
				selected_node_index = i
				
	update_transition_containers()

func add_transition():
	if selected_node_index >= 0:
		var state = states_tree.get_root().get_child(selected_node_index).get_text(0)
		var transition := {
			'source': state,
			'to': '',
			'condition': ''
		}
		state_transitions[state].append(transition)
		add_transition_container(state_transitions[state].size() - 1)
		
func update_transition_containers():
	var container = %TransitionContainer
	for child in container.get_children():
		if child is TransitionContainer:
			child.free()
	if selected_node_index < 0:
		return
	var state = states_tree.get_root().get_child(selected_node_index).get_text(0)
	var index = 0
	for transition in state_transitions[state]:
		var to = transition.get('to', null)
		var condition = transition.get('condition', null)
		add_transition_container(index, to, condition)
		index += 1
	
func add_transition_container(index, to=null, condition=null):
	if selected_node_index < 0:
		return
	var container = %TransitionContainer
	var transition_container : PackedScene = load("res://addons/state_machine/transition_container.tscn")
	var instance = transition_container.instantiate()
	container.add_child(instance)
	instance.set_index(index, index)
	
	update_transition_dropdown(index)
	if to:
		for state : TreeItem in states_tree.get_root().get_children():
			if state.get_text(0) == to:
				instance.state_dropdown.selected = state.get_index()
	if condition:
		instance.expression_text.text = condition
		
	
	if index == 1:
		container.get_child(0).set_index(0, index)
		
	instance.remove_transition.connect(remove_transition)
	instance.sort_transition.connect(sort_transition)
	instance.create_transition.connect(add_transition_connection)
	instance.update_expression.connect(set_transition_expression)
	
		
func remove_transition(index):
	if selected_node_index < 0:
		return
	var state = states_tree.get_root().get_child(selected_node_index).get_text(0)
	state_transitions[state].remove_at(index)
	remove_transition_container.call_deferred(index)

func remove_transition_container(index):
	var container := %TransitionContainer
	container.get_child(index).free()
	for i in range(index, container.get_child_count()):
		container.get_child(i).set_index(i, container.get_child_count() - 1)

func sort_transition(index, new_index):
	var container := %TransitionContainer
	var node := container.get_child(index)
	container.move_child(node, new_index)
	node.set_index(new_index, container.get_child_count() - 1)
	container.get_child(index).set_index(index, container.get_child_count() - 1)

func update_transition_dropdown(index):
	var container := %TransitionContainer
	var states = state_machine.states.keys()
	var child = container.get_child(index)
	child.load_dropdown(states)

func add_transition_connection(source_index, target_index):
	var state = states_tree.get_root().get_child(selected_node_index).get_text(0)
	state_transitions[state][source_index]['to'] = states_tree.get_root().get_child(target_index).get_text(0)
	return
	var source = graph.nodes[source_index]
	print(source)
	var target = graph.nodes[target_index]
	print(target)
	print(graph.connect_node(source.name, 1, target.name, 0, true))

func set_transition_expression(index, value):
	var state = states_tree.get_root().get_child(selected_node_index).get_text(0)
	state_transitions[state][index]['condition'] = value
	set_transitions.call(state_transitions)
