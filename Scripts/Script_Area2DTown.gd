extends Area2D

remotesync var MAX_WATER_COUNT = 20
remotesync var  MAX_FOOD_COUNT = 100
remotesync var  MAX_AMMO_COUNT = 100

remotesync var waterCount = 10
remotesync var foodCount = 10
remotesync var ammoCount = 10

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_town_labels()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(waterCount < MAX_WATER_COUNT):
		waterCount += delta
	if(foodCount < MAX_FOOD_COUNT):
		foodCount += delta
	if(ammoCount < MAX_AMMO_COUNT):
		ammoCount += delta
	_update_town_labels()
	var averageCount = (waterCount + foodCount + ammoCount) / 3
	$Town.set_scale(Vector2(1+averageCount/100,1+averageCount/100))
	$CollisionShape2D.set_scale(Vector2(1+averageCount/100,1+averageCount/100))

func _update_town_labels():
	$WaterCountLabel.text = "" + var2str(int(waterCount)) + "/" + var2str(int(MAX_WATER_COUNT))
	$FoodCountLabel.text = "" + var2str(int(foodCount)) + "/" + var2str(int(MAX_FOOD_COUNT))
	$AmmoCountLabel.text = "" + var2str(int(ammoCount)) + "/" + var2str(int(MAX_AMMO_COUNT))	
	
	if is_network_master():
		rset('waterCount', waterCount)
		rset('foodCount', foodCount)
		rset('ammoCount', ammoCount)

func _on_Area2D_body_entered(body):
	body.town_entered()
	
	if(waterCount + body.waterCount <= body.MAX_WATER_COUNT):
		body.waterCount += waterCount
		waterCount = 0
	else:
		waterCount = waterCount - (body.MAX_WATER_COUNT - body.waterCount)
		body.waterCount = body.MAX_WATER_COUNT
		
	if(foodCount + body.foodCount <= body.MAX_FOOD_COUNT):
		body.foodCount += foodCount
		foodCount = 0
	else:
		foodCount = foodCount - (body.MAX_FOOD_COUNT - body.foodCount)
		body.foodCount = body.MAX_FOOD_COUNT
		
	if(ammoCount + body.ammoCount <= body.MAX_AMMO_COUNT):
		body.ammoCount += ammoCount
		ammoCount = 0
	else:
		ammoCount = ammoCount - (body.MAX_AMMO_COUNT - body.ammoCount)
		body.ammoCount = body.MAX_AMMO_COUNT
	
	body._update_item_labels()
	_update_town_labels()


func _on_Area2DTown_body_exited(body):
	body.town_exited()
