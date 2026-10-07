@tool
extends Control
class_name StateMachineGrid

signal node_selected(node: StateMachineNode)

@onready var state_machine_node := preload('res://addons/state_machine/scenes/state_machine_node.tscn')

@export var grid_size := 64.0
@export var grid_color := Color(0.3, 0.3, 0.3, 0.5)
@export var major_grid_color := Color(0.5, 0.5, 0.5, 0.5)
@export var dot_radius := 1.5
@export var lane_spacing := 32.0

@export var max_curve_length := 250.0
@export var curve_strength := 0.4

var panning := false
var canvas_offset := Vector2.ZERO
var canvas_zoom := 1.0

var nodes : Array[StateMachineGridNode]= []
var transitions : Array[Dictionary] = []
var routed_transitions : Array[Dictionary] = []
var selected_node : StateMachineGridNode

var dragging_node : StateMachineGridNode
var dragging_offset : Vector2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			clear_selection()
			accept_event()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
		
		var mouse_pos := get_local_mouse_position()
		if get_rect().has_point(mouse_pos):
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				set_grid_zoom(0.9, event.position)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				set_grid_zoom(1.1, event.position)
			
		if event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and dragging_node:
			dragging_node = null
	if event is InputEventMouseMotion:
		if panning:
			set_grid_offset(event.relative)
		elif dragging_node:
			var mouse_world := screen_to_world(get_local_mouse_position())
			dragging_node.node_res.set_position(snap_position(mouse_world + dragging_offset))
			update_nodes()
		

func set_grid_offset(offset : Vector2) -> void:
	canvas_offset += offset
	update_nodes()
	
func snap_position(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / grid_size) * grid_size,
		round(pos.y / grid_size) * grid_size,
	)
	
func set_grid_zoom(zoom : float, mouse_pos : Vector2):
	var mouse_world_before = screen_to_world(mouse_pos)
	canvas_zoom = clamp(canvas_zoom * zoom, 0.1, 4.0)
	var mouse_world_after = screen_to_world(mouse_pos)
	canvas_offset += (mouse_world_after - mouse_world_before) * canvas_zoom
	update_nodes()

func world_to_screen(world_pos: Vector2) -> Vector2:
	return world_pos * canvas_zoom + canvas_offset

func screen_to_world(screen_pos: Vector2) -> Vector2:
	return (screen_pos - canvas_offset) / canvas_zoom
	
func get_effective_grid_size() -> float:
	var desired_screen_spacing := grid_size
	var world_spacing := desired_screen_spacing / canvas_zoom

	var power := floor(log(world_spacing) / log(2.0))
	var spacing := pow(2.0, power)

	var top_left := screen_to_world(Vector2.ZERO)
	var bottom_right := screen_to_world(size)

	var world_width := bottom_right.x - top_left.x
	var world_height := bottom_right.y - top_left.y

	var columns := world_width / spacing
	var rows := world_height / spacing

	while columns * rows > 2000:
		spacing *= 2.0
		columns = world_width / spacing
		rows = world_height / spacing

	return spacing
	
func render_state_machine(state_machine : StateMachineResource):
	render_nodes(state_machine.states)
	load_transitions()
	
func render_nodes(states: Array[StateMachineNode]):
	for child in get_children():
		if child is StateMachineGridNode:
			child.queue_free()
	nodes.clear()
	for node in states:
		var node_instance : StateMachineGridNode = state_machine_node.instantiate()
		node_instance.set_node_res(node)
		node_instance.selected.connect(on_node_selection)
		add_child(node_instance)
		node_instance.scale = Vector2(canvas_zoom, canvas_zoom)
		node_instance.position = world_to_screen(node.meta.position)
		nodes.append(node_instance)

func get_node_by_name(grid_node : StateMachineGridNode, grid_name: String) -> bool: 
	return grid_node.node_res.name == grid_name
	
func get_node_rect(node : StateMachineGridNode) -> Rect2:
	return Rect2(
		node.position,
		node.size * node.scale
	)

func find_node(node_name : String) -> StateMachineGridNode:
	var index = nodes.find_custom(get_node_by_name.bind(node_name))
	if index == -1:
		return null
	return nodes[index]
		
func update_nodes():
	for node in nodes:
		node.scale = Vector2(canvas_zoom, canvas_zoom)
		node.position = world_to_screen(node.node_res.meta.position)
	build_routes()
	queue_redraw()
		
func on_node_selection(node: StateMachineGridNode):
	if selected_node:
		selected_node.set_selected(false)
	selected_node = node
	selected_node.set_selected(true)
	
	node_selected.emit(node.node_res)
	
	dragging_node = selected_node
	
	var mouse_world := screen_to_world(get_local_mouse_position())
	dragging_offset = node.node_res.meta.position - mouse_world
	
func clear_selection() -> void:
	if selected_node:
		selected_node.set_selected(false)
	selected_node = null
	node_selected.emit(null)
	
func load_transitions() -> void:
	transitions.clear()
	for node in nodes:
		var node_transitions = node.node_res.transitions
		for transition in node_transitions:
			if !transition.target:
				continue
			transitions.append({
				'from': find_node(node.node_res.name),
				'to': find_node(transition.target)
			})
	build_routes()
	queue_redraw()

func build_routes() -> void:
	routed_transitions.clear()
	var groups := {}
	
	for transition in transitions:
		var from_node : StateMachineGridNode = transition.from
		var to_node : StateMachineGridNode = transition.to
		
		if from_node == to_node:
			route_self_transition(transition)
			continue
			
		var key := build_pair_key(from_node, to_node)
		if not groups.has(key):
			groups[key] = []
			
		groups[key].append(transition)
		
	for group in groups.values():
		route_transition_group(group)
		
func route_transition_group(group: Array) -> void:
	var count := group.size()

	for i in range(count):
		var transition = group[i]
		var lane := get_centered_lane(i, count)
		var route := create_route(transition.from, transition.to, lane)

		routed_transitions.append(route)
	
func assign_group_lanes(group : Array) -> void:
	var count := group.size()
	for i in range(count):
		group[i].lane = get_centered_lane(i, count)
		
func get_centered_lane(index: int, count: int) -> float:
	if count <= 1:
		return 0.0
	return (index - (count - 1) * 0.5) * lane_spacing
	
func create_route(from_node: StateMachineGridNode, to_node: StateMachineGridNode, lane: float) -> Dictionary:
	var from_rect := get_node_rect(from_node)
	var to_rect := get_node_rect(to_node)
	
	var from_center := from_rect.get_center()
	var to_center := to_rect.get_center()
	
	var perpendicular := get_pair_perpendicular(from_node, to_node)
	
	var start := get_rect_edge_point(from_node, to_center, perpendicular, lane)
	var end := get_rect_edge_point(to_node, from_center, perpendicular, lane)
	
	var controls := get_bezier_controls(start, end, lane, perpendicular)
	
	return {
		"p0": start,
		"p1": controls[0],
		"p2": controls[1],
		"p3": end
	}
	
func get_pair_perpendicular(from_node: StateMachineGridNode, to_node: StateMachineGridNode) -> Vector2:
	var a := from_node.node_res.name
	var b := to_node.node_res.name
	
	var from_center := get_node_rect(from_node).get_center()
	var to_center := get_node_rect(to_node).get_center()

	var direction: Vector2

	if a < b:
		direction = (to_center - from_center).normalized()
	else:
		direction = (from_center - to_center).normalized()

	return Vector2(
		-direction.y,
		direction.x
	)
	
func route_self_transition(transition: Dictionary) -> void:
	var node : StateMachineGridNode = transition.from
	var rect := get_node_rect(node)
	
	var center := rect.get_center()
	var half_size := rect.size * 0.5
	
	var start := center + Vector2(half_size.x, -half_size.y * 0.25)
	var end := center + Vector2(half_size.x, half_size.y * 0.25)
	
	var loop_width := 50.0
	var loop_height := 50.0
	
	var p1 := start + Vector2(loop_width, -loop_height)
	var p2 := end + Vector2(loop_width, loop_height)
	
	var route := {
		'p0': start,
		'p1': p1,
		'p2': p2,
		'p3': end
	}
	transition.merge(route, true)
	routed_transitions.append(transition)
	
func build_pair_key(from_node: StateMachineGridNode, to_node: StateMachineGridNode) -> String:
	var a := from_node.node_res.name
	var b := to_node.node_res.name
	
	if a < b:
		return '%s|%s' % [a, b]
	return '%s|%s' % [b, a]

func cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t:float) -> Vector2:
	var u := 1.0 - t
	return (
		u * u * u * p0
		+ 3.0 * u * u * t * p1
		+ 3.0 * u * t * t * p2
		+ t * t * t * p3
	)
	
func cubic_bezier_derivative(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t:float) -> Vector2:
	var u := 1.0 - t
	return (
		3.0 * u * u * (p1 - p0)
		+ 6.0 * u * t * (p2 - p1)
		+ 3.0 * t * t * (p3 - p2)
	)
	
func draw_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, color: Color, width: float = 2.0) -> void:
	var points := PackedVector2Array()
	var subdivisions := 32
	for i in range(subdivisions + 1):
		var t:= float(i) / subdivisions
		points.append(cubic_bezier(p0, p1, p2, p3, t))
		
	draw_polyline(points, color, width, true)
	
func get_bezier_controls(start: Vector2, end: Vector2, lane: float, perpendicular: Vector2) -> Array[Vector2]:
	var direction := (end - start).normalized()
	var distance := start.distance_to(end)
	
	var strength := min(distance * curve_strength, max_curve_length)
	var lane_offset := perpendicular * lane
	
	var control_1 : Vector2 = start + direction * strength + lane_offset
	var control_2 : Vector2 = end - direction * strength + lane_offset
	
	return [control_1, control_2]
	
func draw_arrowhead(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, color: Color) -> void:
	var t := 0.97
	var position := cubic_bezier(p0, p1, p2, p3, t)
	
	var tangent := cubic_bezier_derivative(p0, p1, p2, p3, t).normalized()
	
	if tangent.length_squared() < 0.001:
		return
		
	var perpendicular := Vector2(-tangent.y, tangent.x)
	
	var arrow_length := 10.0
	var arrow_width := 5.0
	var tip := position + tangent * arrow_length
	
	var left := (position - tangent * arrow_length * 0.5 + perpendicular * arrow_width)
	var right := (position - tangent * arrow_length * 0.5 - perpendicular * arrow_width)
	
	draw_colored_polygon(PackedVector2Array([tip, left, right]), color)
	
	
func draw_route(route: Dictionary) -> void:
	var p0: Vector2 = route.p0
	var p1: Vector2 = route.p1
	var p2: Vector2 = route.p2
	var p3: Vector2 = route.p3

	var color := Color.WHITE

	draw_bezier(p0, p1, p2, p3, color)
	draw_arrowhead(p0, p1, p2, p3, color)
	
func get_rect_edge_point(node: StateMachineGridNode, toward: Vector2, perpendicular: Vector2, lane: float) -> Vector2:
	var node_rect := get_node_rect(node)
	var center := node_rect.get_center()
	var half_size := node_rect.size * 0.5
	
	var target := toward + perpendicular * lane
	
	var direction := (target - center).normalized()
	
	var scale_x := INF
	var scale_y := INF
	
	if abs(direction.x) > 0.0001:
		scale_x = half_size.x / abs(direction.x)
	if abs(direction.y) > 0.0001:
		scale_y = half_size.y / abs(direction.y)
	
	var distance := min(scale_x, scale_y)
	return center + direction * distance


func draw_grid() -> void:
	var visible_world_rect := Rect2(
		screen_to_world(Vector2.ZERO),
		screen_to_world(size) - screen_to_world(Vector2.ZERO)
	)
	
	var effective_grid := get_effective_grid_size()

	# Find the first grid point visible on screen.
	var start_x : float = floor(visible_world_rect.position.x / effective_grid) * effective_grid
	var start_y : float = floor(visible_world_rect.position.y / effective_grid) * effective_grid

	var end_x := visible_world_rect.end.x
	var end_y := visible_world_rect.end.y
	
	var x := start_x
	while x <= end_x:
		var y := start_y
		while y <= end_y:
			var grid_x := int(round(x / effective_grid))
			var grid_y := int(round(y / effective_grid))
			var is_major := grid_x % 5 == 0 or grid_y % 5 == 0
			var color := major_grid_color if is_major else grid_color
			
			var screen_pos = world_to_screen(Vector2(x, y))
			if Rect2(Vector2.ZERO, size).has_point(screen_pos):
				draw_circle(screen_pos, dot_radius, color)
			
			y += effective_grid
		x += effective_grid


func _draw() -> void:
	draw_grid()
	
	for route in routed_transitions:		
		draw_route(route)
		
