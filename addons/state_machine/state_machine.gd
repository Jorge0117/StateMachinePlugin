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
	var dock_scene : StateMachineDock = preload("res://addons/state_machine/state_machine_dock.tscn").instantiate()
	if current_node:
		dock_scene.state_machine_resource = current_node.state_machine_resource
	
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
		dock.get_child(0).render_state_tree()
		dock.show()
	else:
		current_node = null
		dock.get_child(0).set_state_machine(current_node)
		dock.hide()
	
