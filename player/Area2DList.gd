extends Area2D

func _ready():
	get_parent().modulate = Color(1, 1, 1, 0.5)

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton \
	and event.button_index == BUTTON_LEFT \
	and event.is_pressed():
		self.on_click()

func on_click():
	print("Click")
	if(get_parent().get_parent().get_node("ListMenu").is_visible()):
		get_parent().get_parent().get_node("ListMenu").hide()
	else:
		get_parent().get_parent().get_node("ListMenu").show()

func _on_Area2DList_mouse_entered():
	get_parent().modulate = Color(1, 1, 1, 1)


func _on_Area2DList_mouse_exited():
	get_parent().modulate = Color(1, 1, 1, 0.5)
