@tool
extends GraphEdit

class_name Graph

var nodes : Array[GraphNode] = []

func add_node(item : TreeItem):
	var node := GraphNode.new()
	node.title = item.get_text(0)
	node.resizable = true
	set_selected(node)
	arrange_nodes()
	add_child(node)
	nodes.push_back(node)
	
	var input = Control.new()
	input.name = 'input'
	node.add_child(input)
	var output = Control.new()
	output.name = 'output'
	node.add_child(output)
	
	node.set_slot(0, true, 1, Color.LIGHT_GOLDENROD, false, 1, Color.AQUA)
	node.set_slot(1, false, 1, Color.LIGHT_GOLDENROD, true, 1, Color.AQUA)

func update_node(item : TreeItem):
	var index = item.get_index()
	nodes[index].title = item.get_text(0)

func remove_node(item : TreeItem):
	var index = item.get_index()
	var node = nodes.pop_at(index)
	node.free()
