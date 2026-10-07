@tool
extends FoldableContainer
class_name TransitionContainer

signal remove_transition(index)
signal transition_up(transition_res)
signal transition_down(transition_res)
signal request_render()

var transition : StateMachineTransition
var up_button : Button
var down_button : Button
var delete_button : Button
var state_dropdown: OptionButton
var expression_text : TextEdit

func _ready() -> void:
	var container = %ButtonsContainer
	for child in container.get_children():
		child.free()
	up_button = Button.new()
	var up_icon := EditorInterface.get_base_control().get_theme_icon('GuiSpinboxUp', 'EditorIcons')
	up_button.icon = up_icon
	up_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	up_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	up_button.pressed.connect(move_up)
	
	down_button = Button.new()
	var down_icon := EditorInterface.get_base_control().get_theme_icon('GuiSpinboxDown', 'EditorIcons')
	down_button.icon = down_icon
	down_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	down_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	down_button.pressed.connect(move_down)
	
	delete_button = Button.new()
	var delete_icon := EditorInterface.get_base_control().get_theme_icon('GuiClose', 'EditorIcons')
	delete_button.icon = delete_icon
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	delete_button.pressed.connect(remove)
	
	container.add_child(up_button)
	container.add_child(down_button)
	container.add_child(delete_button)
	
	state_dropdown = %StateDropdown
	state_dropdown.item_selected.connect(dropdown_selected)
	
	expression_text = %ExpressionText
	expression_text.text_changed.connect(update_condition)
	folding_changed.connect(on_collapse)

func set_data(transition_res : StateMachineTransition, first, last, index):
	title = 'Transition ' + str(index)
	up_button.disabled = false
	down_button.disabled = false
	if first:
		up_button.disabled = true
	if last:
		down_button.disabled = true
	transition = transition_res
	folded = transition.meta.collapsed
	expression_text.text = transition.expression_text
	
func on_collapse(is_collapsed):
	transition.meta.collapsed = is_collapsed
		
func load_dropdown(state_machine : StateMachineResource):
	state_dropdown.clear()
	for state : StateMachineNode in state_machine.states:
		state_dropdown.add_item(state.name)
	state_dropdown.selected = -1
	for i in range(state_dropdown.item_count):
		var item_text := state_dropdown.get_item_text(i)
		if item_text == transition.target:
			state_dropdown.selected = i
			break
	
		
func remove():
	remove_transition.emit(transition)
	
func move_up():
	transition_up.emit(transition)
	
func move_down():
	transition_down.emit(transition)
	
func dropdown_selected(dropdown_index):
	var target_text := state_dropdown.get_item_text(dropdown_index)
	transition.target = target_text
	request_render.emit()
	
func update_condition():
	transition.expression_text = expression_text.text
