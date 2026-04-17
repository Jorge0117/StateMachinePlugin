extends Sprite2D

class_name SpriteController

@export var speed := 100.0

@onready var state_machine := $StateMachine

var input_dir : Vector2

func _process(delta: float) -> void:
	input_dir = Input.get_vector("Left", "Right", "Up", "Down")
