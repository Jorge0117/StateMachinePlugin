@tool
extends Resource
class_name StateMachineTransition

@export var target : String :
	set(value):
		target = value
		emit_changed()
		
@export var expression_text : String:
	set(value):
		expression_text = value
		emit_changed()

var expression : Expression

@export var meta : Dictionary = {
	'collapsed': false
}

func parse_expression() -> bool:
	expression = Expression.new()
	var error = expression.parse(expression_text)
	if error != OK:
		push_error(expression.get_error_text())
		return false
	return true
