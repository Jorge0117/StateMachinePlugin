@tool
extends Control

@onready var grid : StateMachineGrid = %Grid

var panning := false

var state_machine : StateMachineResource

func _ready() -> void:
	var state_mac = ResourceLoader.load('res://StateMachines/2d.res')
	load_state_machine(state_mac)


func load_state_machine(_state_machine : StateMachineResource) -> void:
	state_machine = _state_machine
	grid.render_state_machine(state_machine)
