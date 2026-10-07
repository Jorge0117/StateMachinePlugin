@tool
extends GraphNode
class_name GraphEditNode

var state_machine_node : StateMachineNode

func _ready() -> void:
	position_offset_changed.connect(on_position_changed)
	
func on_position_changed():
	state_machine_node.meta.position = position_offset
