extends Area2D

export var insects = 1000
export var water = 100

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass



func _on_Area2D_body_entered(body):
	print(body)
	body.insects += 10
	body.water += 10
	body._update_item_labels()
	pass # Replace with function body.
