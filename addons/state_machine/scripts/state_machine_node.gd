@tool
extends PanelContainer
class_name StateMachineGridNode

signal selected(node: StateMachineGridNode)

@onready var normal_panel : StyleBoxFlat = preload('res://addons/state_machine/panels/state_machine_node_normal.tres')
@onready var selected_panel : StyleBoxFlat = preload('res://addons/state_machine/panels/state_machine_node_selected.tres')

var node_res : StateMachineNode

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			selected.emit(self)
			accept_event()

func set_node_res(res : StateMachineNode):
	node_res = res
	%Name.text = res.name

func set_selected(value: bool):
	if value:
		add_theme_stylebox_override("panel", selected_panel)
	else:
		add_theme_stylebox_override("panel", normal_panel)
