@tool
extends FoldableContainer
class_name TransitionContainer

signal remove_transition(index)
signal sort_transition(index, new_index)
signal create_transition(source_index, target_index)
signal update_expression(index, value)

var index := 0
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
	up_button.pressed.connect(sort_up)
	
	down_button = Button.new()
	var down_icon := EditorInterface.get_base_control().get_theme_icon('GuiSpinboxDown', 'EditorIcons')
	down_button.icon = down_icon
	down_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	down_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	down_button.pressed.connect(sort_down)
	
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

func set_index(new_index, last_index):
	index = new_index
	title = 'Transition ' + str(index)
	up_button.disabled = false
	down_button.disabled = false
	if index == 0:
		up_button.disabled = true
	if new_index == last_index:
		down_button.disabled = true
		
func load_dropdown(states):
	state_dropdown.clear()
	for state in states:
		state_dropdown.add_item(state)
	state_dropdown.selected = -1
		
func remove():
	remove_transition.emit(index)
	
func sort_up():
	sort_transition.emit(index, index - 1)
	
func sort_down():
	sort_transition.emit(index, index + 1)
	
func dropdown_selected(dropdown_index):
	create_transition.emit(index, dropdown_index)
	
func update_condition():
	update_expression.emit(index, expression_text.text)
