@tool
extends ScrollContainer
class_name StateMachineDock

var states_tree : Tree
var states_tree_root : TreeItem
var add_state_button : Button

var add_icon : Texture2D
var remove_icon : Texture2D
var load_icon : Texture2D
var save_icon : Texture2D
var elipsis_icon : Texture2D

var state_machine : StateMachine
var state_machine_grid : StateMachineGrid
var graph_node_label : Label

var add_transition_button : Button
var transition_container : VBoxContainer

var resource_text : LineEdit
var create_resource_button : Button
var load_resource_button : Button
var save_resource_button : Button
var resource_options_button : Button

var state_machine_res : StateMachineResource = null
var selected_node : StateMachineNode

func _ready() -> void:
	add_icon = EditorInterface.get_base_control().get_theme_icon('Add', 'EditorIcons')
	remove_icon = EditorInterface.get_base_control().get_theme_icon('GuiClose', 'EditorIcons')
	load_icon = EditorInterface.get_base_control().get_theme_icon('Load', 'EditorIcons')
	save_icon = EditorInterface.get_base_control().get_theme_icon('Save', 'EditorIcons')
	elipsis_icon = EditorInterface.get_base_control().get_theme_icon('GuiEllipsis', 'EditorIcons')
	
	states_tree = %StatesTree
	state_machine_grid = %StateMachineGrid
	states_tree.item_edited.connect(on_tree_edited)
	states_tree.button_clicked.connect(on_tree_button)
	states_tree_root = states_tree.create_item()
	states_tree.hide_root = true
	states_tree.item_collapsed.connect(on_tree_collapse)
	
	add_state_button = %AddStateButton
	add_state_button.pressed.connect(add_state)
	
	state_machine_grid.node_selected.connect(on_graph_node_selection_change)
	graph_node_label = %NodeNameLabel
	add_transition_button = %AddTransitionButton
	add_transition_button.pressed.connect(add_transition)
	add_transition_button.disabled = true
	
	resource_text = %ResourceText
	load_resource_button = %LoadResourceButton
	load_resource_button.icon = load_icon
	load_resource_button.pressed.connect(load_resource_dialog)
	create_resource_button = %CreateResourceButton
	create_resource_button.icon = add_icon
	create_resource_button.pressed.connect(create_resource_dialog)
	save_resource_button = %SaveResourceButton
	save_resource_button.icon = save_icon
	create_resource_button.pressed.connect(save_resource)
	resource_options_button = %OptionsResourceButton
	resource_options_button.icon = elipsis_icon
	
	transition_container = %TransitionContainer
	
func set_state_machine(new_state_machine : StateMachine):
	state_machine = new_state_machine
	if state_machine:
		%MainContainer.visible = true
		%ErrorLabel.visible = false
		load_state_machine_resource(new_state_machine.state_machine_resource)
	else:
		%MainContainer.visible = false
		%ErrorLabel.visible = true    
		resource_text.text = ''
		
func create_resource_dialog():
	var create_resource_dialog := EditorFileDialog.new()
	create_resource_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	create_resource_dialog.access = FileDialog.ACCESS_RESOURCES
	create_resource_dialog.add_filter('*.res', 'State Machine Resource Files')
	create_resource_dialog.file_selected.connect(create_resource)
	EditorInterface.get_base_control().add_child(create_resource_dialog)
	create_resource_dialog.popup_centered_ratio()
	
func load_resource_dialog():
	var load_resource_dialog := EditorFileDialog.new()
	load_resource_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	load_resource_dialog.access = FileDialog.ACCESS_RESOURCES
	load_resource_dialog.add_filter('*.res', 'State Machine Resource Files')
	load_resource_dialog.file_selected.connect(load_resource)
	EditorInterface.get_base_control().add_child(load_resource_dialog)
	load_resource_dialog.popup_centered_ratio()
	
func save_resource():
	var path = resource_text.text
	var err := ResourceSaver.save(state_machine.state_machine_resource, path)
	if err != OK:
		print(err)
	
func create_resource(path):
	var res := StateMachineResource.new()
	var err := ResourceSaver.save(res, path)
	if err == OK:
		load_resource(path)
	else:
		print(err)
		
func load_resource(path):
	var res : StateMachineResource = ResourceLoader.load(path)
	if res:
		res.setup()
		state_machine.state_machine_resource = res
		load_state_machine_resource(res)

func load_state_machine_resource(resource):
	if state_machine.state_machine_resource:
		resource_text.text = state_machine.state_machine_resource.resource_path
		%StateMachineContainer.visible = true
		%NoResourceLabel.visible = false
		if !state_machine.state_machine_resource.changed.is_connected(on_resource_changed):
			state_machine.state_machine_resource.changed.connect(on_resource_changed)
	else:
		%StateMachineContainer.visible = false
		%NoResourceLabel.visible = true
		
func on_resource_changed():
	#%UnsavedResourceLabel.visible = true
	save_resource()

func add_state():
	var default_name := 'State'
	default_name = state_machine.state_machine_resource.get_valid_name(default_name)
	var state : StateMachineNode = StateMachineNode.new()
	state.name = default_name
	state.state = StateMachineState.new()
	var initial_state := state_machine.state_machine_resource.get_initial_state()
	if initial_state == null:
		state.initial_state = true
	state_machine.state_machine_resource.add_state(state)
	state_machine.state_machine_resource.emit_changed()
	render_state_tree()
	render_transitions()

func render_state_tree():
	if !state_machine.state_machine_resource:
		return
	for child in states_tree_root.get_children():
		child.free()
		
	for node : StateMachineNode in state_machine.state_machine_resource.states:
		var state = states_tree.create_item(states_tree_root)
		state.set_editable(0, true)
		state.set_text(0, node.name)
		state.add_button(1, remove_icon)
		state.set_metadata(0, node)
		state.collapsed = node.meta.collapsed
		
		var on_enter = states_tree.create_item(state)
		on_enter.set_text(0, 'on_enter')
		on_enter.set_metadata(0, node.state.on_enter)
		if !node.state.on_enter.is_valid():
			on_enter.set_text(1, '...')
			on_enter.add_button(1, add_icon)
		else:
			render_tree_script(node.state.on_enter, on_enter)
		
		var on_update = states_tree.create_item(state)
		on_update.set_text(0, 'on_update')
		on_update.set_metadata(0, node.state.on_update)
		if !node.state.on_update.is_valid():
			on_update.set_text(1, '...')
			on_update.add_button(1, add_icon)
		else:
			render_tree_script(node.state.on_update, on_update)
		
		var on_physics_update = states_tree.create_item(state)
		on_physics_update.set_text(0, 'on_physics_update')
		on_physics_update.set_metadata(0, node.state.on_physics_update)
		if !node.state.on_physics_update.is_valid():
			on_physics_update.set_text(1, '...')
			on_physics_update.add_button(1, add_icon)
		else:
			render_tree_script(node.state.on_physics_update, on_physics_update)
		
		var on_exit = states_tree.create_item(state)
		on_exit.set_text(0, 'on_exit')
		on_exit.set_metadata(0, node.state.on_exit)
		if !node.state.on_exit.is_valid():
			on_exit.set_text(1, '...')
			on_exit.add_button(1, add_icon)
		else:
			render_tree_script(node.state.on_exit, on_exit)
		
	render_grid()
	render_transitions()
	
	
func render_grid():
	state_machine_grid.render_state_machine(state_machine.state_machine_resource)
	
	
func render_tree_script(script_data : StateMachineStateStep, tree_item: TreeItem):
	tree_item.set_text(1, script_data.path)
	tree_item.add_button(1, remove_icon)
	
	var script : Script = load(script_data.path)
	var functions = script.get_script_method_list() 
	for function in functions:
		if not function.name.begins_with("_"):
			var tree_func = states_tree.create_item(tree_item)
			tree_func.set_text(0, function.name)
			tree_func.set_cell_mode(1, TreeItem.CELL_MODE_CHECK)
			tree_func.set_editable(1, true)
			if function.name == script_data.function:
				tree_func.set_checked(1, true)
	if tree_item.get_child_count() == 0:
		push_error("Coulnd't find any valid functions on script %d" % script_data.path)
	tree_item.collapsed = script_data.meta.collapsed
		
		
func on_tree_button(item: TreeItem, colum, id, mouse_button):
	var item_name := item.get_text(0)
	if item_name not in ['on_enter', 'on_update', 'on_physics_update', 'on_exit']:
		state_machine.state_machine_resource.remove_state(item_name)
		render_state_tree()
		return
	if item.get_text(1) == '...':
		var node := state_machine.state_machine_resource.get_node_by_name(item.get_parent().get_text(0))
		open_script_dialog(node.state, item.get_text(0))
	else:
		var node := state_machine.state_machine_resource.get_node_by_name(item.get_parent().get_text(0))
		var dict_name := item.get_text(0)
		node.state.reset_dict(dict_name)
		render_state_tree()
	
func open_script_dialog(state: StateMachineState, dict : String):
	var script_dialog := EditorFileDialog.new()
	script_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	script_dialog.access = FileDialog.ACCESS_RESOURCES
	script_dialog.add_filter('*.gd', 'GDScript files')
	script_dialog.file_selected.connect(on_add_script.bind(state, dict))
	EditorInterface.get_base_control().add_child(script_dialog)
	script_dialog.popup_centered_ratio()
	
func on_add_script(path: String, state: StateMachineState, dict_name : String):
	var script : Script = load(path)
	var functions = script.get_script_method_list()
	var default_function := ''
	for function in functions:
		if not function.name.begins_with("_"):
			default_function = function.name
			break
	state.get(dict_name).path = path
	state.get(dict_name).function = default_function
	render_state_tree()
	
	
func on_tree_edited():
	var item_edited := states_tree.get_edited()
	
	#Name changed:
	if item_edited.is_editable(0):
		var old_name : String = item_edited.get_metadata(0).name
		var new_name := item_edited.get_text(0)
		if old_name != new_name:
			new_name = state_machine.state_machine_resource.get_valid_name(new_name)
		
		var node := state_machine.state_machine_resource.get_node_by_name(old_name)
		node.name = new_name
		render_state_tree.call_deferred()
		render_transitions.call_deferred()
		state_machine.state_machine_resource.emit_changed()
		return
	
	#Select function
	if item_edited.get_cell_mode(1) == TreeItem.CELL_MODE_CHECK:
		var function := item_edited.get_text(0)
		var dict_name := item_edited.get_parent().get_text(0)
		var node := state_machine.state_machine_resource.get_node_by_name(item_edited.get_parent().get_parent().get_text(0))
		var step : StateMachineStateStep = node.state.get(dict_name)
		step.function = function
		render_state_tree.call_deferred()
		state_machine.state_machine_resource.emit_changed()
		return

func on_tree_collapse(item: TreeItem):
	var metadata = item.get_metadata(0)
	if 'meta' in metadata:
		if metadata.meta.has('collapsed'):
			metadata.meta.collapsed = item.collapsed


func on_graph_node_selection_change(node: StateMachineNode):
	selected_node = node
	if node:
		graph_node_label.text = node.name
		add_transition_button.disabled = false
	else:
		graph_node_label.text = 'Select Node'
		add_transition_button.disabled = true
		
	render_transitions()

func add_transition():
	if selected_node:
		var state := state_machine.state_machine_resource.get_node_by_name(selected_node.name)
		var transition = StateMachineTransition.new()

		state.add_transition(transition)
		render_transitions()
		state_machine.state_machine_resource.emit_changed()
		
func render_transitions():
	for child in transition_container.get_children():
		if child is TransitionContainer:
			child.free()
	if !selected_node:
		return
	var state := state_machine.state_machine_resource.get_node_by_name(selected_node.name)
	var transition_amount := state.transitions.size()
	for i in range(transition_amount):
		var transition : StateMachineTransition = state.transitions[i]
		add_transition_container(transition, i, i==0, i==transition_amount - 1)
	
func add_transition_container(transition_res, index, first=false, last=false):
	if !selected_node:
		return
	var transition : PackedScene = load("res://addons/state_machine/transition_container.tscn")
	var instance : TransitionContainer = transition.instantiate()
	transition_container.add_child(instance)
	instance.set_data(transition_res, first, last, index)
	instance.load_dropdown(state_machine.state_machine_resource)

	instance.remove_transition.connect(remove_transition)
	instance.transition_up.connect(move_transition_up)
	instance.transition_down.connect(move_transition_down)
	instance.request_render.connect(render_grid)
	
		
func remove_transition(transition : StateMachineTransition):
	if !selected_node:
		return
	selected_node.remove_transition(transition)

	render_transitions.call_deferred()
	state_machine.state_machine_resource.emit_changed()

func move_transition_up(transition : StateMachineTransition):
	if !selected_node:
		return
	selected_node.state_machine_node.move_transition_up(transition)
	render_transitions.call_deferred()
	state_machine.state_machine_resource.emit_changed()
	
func move_transition_down(transition : StateMachineTransition):
	if !selected_node:
		return
	selected_node.state_machine_node.move_transition_down(transition)
	render_transitions.call_deferred()
	state_machine.state_machine_resource.emit_changed()
