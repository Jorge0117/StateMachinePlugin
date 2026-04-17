@tool
extends EditorPlugin

var dock : EditorDock
var current_node : StateMachine = null

func _enable_plugin() -> void:
	# Add autoloads here.
	pass


func _disable_plugin() -> void:
	# Remove autoloads here.
	pass

func _enter_tree() -> void:
	var dock_scene = preload("res://addons/state_machine/state_machine_dock.tscn").instantiate()
	dock_scene.set_states = set_states
	dock_scene.set_transitions = set_transitions
	dock_scene.get_available_name = get_available_name
	
	dock = EditorDock.new()
	dock.add_child(dock_scene)
	
	dock.title = 'State Machine'
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	dock.available_layouts = EditorDock.DOCK_LAYOUT_HORIZONTAL
	
	add_dock(dock)
	
	EditorInterface.get_selection().selection_changed.connect(on_selection_changed)

func _exit_tree() -> void:
	remove_dock(dock)
	dock.queue_free()
	pass
	
func on_selection_changed():
	var selection = EditorInterface.get_selection().get_selected_nodes()
	
	if selection.size() == 1 and selection[0] is StateMachine:
		current_node = selection[0]
		dock.get_child(0).set_state_machine(current_node)
		dock.get_child(0).load_states()
		dock.show()
	else:
		current_node = null
		dock.get_child(0).set_state_machine(current_node)
		dock.hide()
	
func get_available_name(name: String) -> String:
	var states = current_node.states
	if name in ['on_enter', 'on_update', 'on_physics_update', 'on_exit', '']:
		name = 'State'
		
	if not states.has(name):
		return name

	var name_index := 1
	while true:
		var new_name := "%s (%d)" % [name, name_index]
		if not states.has(new_name):
			return new_name
		name_index += 1
	return ''

func set_states(new_states : Dictionary):
	current_node.states = new_states
	
func set_transitions(new_transitions : Dictionary):
	current_node.transitions = new_transitions
