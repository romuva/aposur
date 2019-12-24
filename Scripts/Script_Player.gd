extends KinematicBody2D

const MAX_MOVE_SPEED = 10.0
const MAX_HP = 100

const MAX_WATER_COUNT = 10
const MAX_FOOD_COUNT = 10
const MAX_AMMO_COUNT = 10

enum MoveDirection { UP, DOWN, LEFT, RIGHT, NONE }

puppet var slave_position = Vector2()
puppet var slave_movement = MoveDirection.NONE

puppet var waterCount = MAX_WATER_COUNT
puppet var foodCount = 10
puppet var ammoCount = MAX_AMMO_COUNT

puppet var move_speed = MAX_MOVE_SPEED
puppet var health_points = MAX_HP

puppet var is_moving_double_slow = false

master var bags = Array()
master var timers = Array()

func _ready():
	$StatsLabel/PlayerIDCountLabel.text = var2str(int(name))
	
	_update_health_bar()
	_update_item_labels()
	
	if is_network_master():
		$ListIcon.visible = true
		$StatsLabel.visible = true
	else:
		$ListIcon.visible = false
		$StatsLabel.visible = false

func _physics_process(delta):
	var direction = MoveDirection.NONE
	if is_network_master():
		if Input.is_action_pressed('die'):
			_die()
		
		if Input.is_action_pressed('left'):
			direction = MoveDirection.LEFT
		elif Input.is_action_pressed('right'):
			direction = MoveDirection.RIGHT
		elif Input.is_action_pressed('up'):
			direction = MoveDirection.UP
		elif Input.is_action_pressed('down'):
			direction = MoveDirection.DOWN
		
		$StatsLabel/FPSCountLabel.text = var2str(int(Engine.get_frames_per_second()))
		$StatsLabel/PlayersCountLabel.text = var2str(int(Network.players.size()))
		
		rset_unreliable('slave_position', position)
		rset('slave_movement', direction)
		_move(direction)
	else:
		_move(slave_movement)
		position = slave_position
	
	if get_tree().is_network_server():
		Network.update_position(int(name), position)

	if(waterCount >= 1):
		waterCount -= delta
		regen(delta)
		_update_item_labels()
	else:
		damage(delta)
		_update_item_labels()
		_no_water_left()

	if(foodCount >= 1):
		if(is_moving_double_slow):
			is_moving_double_slow = false
			move_speed = MAX_MOVE_SPEED
		_update_item_labels()
	else:
		if(!is_moving_double_slow):
			is_moving_double_slow = true
			move_speed = move_speed / 2
		_no_food_left()

func _move(direction):
	match direction:
		MoveDirection.NONE:
			return
		MoveDirection.UP:
			move_and_collide(Vector2(0, -move_speed))
			$Sprite.rotation_degrees = 0
		MoveDirection.DOWN:
			move_and_collide(Vector2(0, move_speed))
			$Sprite.rotation_degrees = 180
		MoveDirection.LEFT:
			move_and_collide(Vector2(-move_speed, 0))
			$Sprite.rotation_degrees = 270
		MoveDirection.RIGHT:
			move_and_collide(Vector2(move_speed, 0))
			$Sprite.rotation_degrees = 90

func _update_health_bar():
	$GUI/HealthBar.value = health_points

func _update_item_labels():
	if($ListMenu/Control.inventory_getItemById(1)):
		foodCount = $ListMenu/Control.inventory_getItemById(1).amount
	
	$StatsLabel/HealthCountLabel.text = var2str(int(health_points)) + "/" + var2str(int(MAX_HP))
	$StatsLabel/WaterCountLabel.text = var2str(int(waterCount)) + "/" + var2str(int(MAX_WATER_COUNT))
	$StatsLabel/FoodCountLabel.text = var2str(int(foodCount))
	$StatsLabel/AmmoCountLabel.text = var2str(int(ammoCount)) + "/" + var2str(int(MAX_AMMO_COUNT))
	if(waterCount >= 1):
		$StatsLabel/WaterLabel.set("custom_colors/font_color", Color(1,1,1))
	if(foodCount >= 1):
		$StatsLabel/FoodLabel.set("custom_colors/font_color", Color(1,1,1))
	if(ammoCount >= 1):
		$StatsLabel/AmmoLabel.set("custom_colors/font_color", Color(1,1,1))

	$StatsLabel/SpeedCountLabel.text = var2str(int(move_speed)) + "/" + var2str(int(MAX_MOVE_SPEED))

func damage(value):
	health_points -= value
	if health_points <= 0:
		health_points = 0
		rpc('_die')
	_update_health_bar()

func regen(value):
	if(health_points <= MAX_HP):
		health_points += value
	_update_health_bar()

sync func _die():
	$RespawnTimer.start()
	set_physics_process(false)
	for child in get_children():
		if child.has_method('hide'):
			child.hide()
	$CollisionShape2D.disabled = true
	rpc("_spawn_bag")
	
sync func _spawn_bag():
	var bagSprite = Sprite.new()
	bagSprite.texture = load("res://Assets/Images/bag.png")
	bagSprite.set_global_position($GUI/HealthBar.get_global_position())
	
	bags.append(bagSprite)
	get_node("..").add_child(bagSprite)
	var timer = Timer.new()
	timer.wait_time = 60
	timer.one_shot = true
	timer.connect("timeout",self,"_on_bag_timer_timeout")
	add_child(timer)
	timer.start()

# need fix to delete only one bag not all 2019-12-23
func _on_bag_timer_timeout():
	for bag in bags:
		bag.queue_free()

func _on_RespawnTimer_timeout():
	set_physics_process(true)
	for child in get_children():
		if child.has_method('show'):
			child.show()
	$CollisionShape2D.disabled = false
	health_points = MAX_HP
	_update_health_bar()
	
func _no_water_left():
	$StatsLabel/WaterLabel.set("custom_colors/font_color", Color(1,0,0))

func _no_food_left():
	$StatsLabel/FoodLabel.set("custom_colors/font_color", Color(1,0,0))

func _no_ammo_left():
	$StatsLabel/AmmoLabel.set("custom_colors/font_color", Color(1,0,0))

func init(nickname, start_position, is_slave):
	$GUI/Nickname.text = nickname
	global_position = start_position
	$ListMenu/Control.load_player_data(nickname)
	$ListMenu/Control/Panel.load_town_data("Alkubra")
#	if is_slave:
#		$Sprite.texture = load('res://player/character-alt.png')
	if is_network_master():
		$Camera2D.current = 1