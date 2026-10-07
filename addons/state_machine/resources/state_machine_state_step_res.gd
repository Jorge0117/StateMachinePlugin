@tool
extends Resource
class_name StateMachineStateStep


@export var path := ''
@export var function := ''
@export var meta := {
	'collapsed': false
}

func is_valid():
	if path != '' and function != '':
		return true
	return false

func reset():
	path = ''
	function = ''
	meta.collapsed = false
