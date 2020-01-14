extends Area2D

const MAX_MOVE_SPEED = 100
const MAX_HP = 100

const MAX_WATER_COUNT = 10
const MAX_FOOD_COUNT = 10
const MAX_AMMO_COUNT = 10

enum MoveDirection { UP, DOWN, LEFT, RIGHT, NONE }

puppet var slave_position = Vector2()
puppet var slave_movement = Vector2(0.0, 0.0)

puppet var direction = Vector2(0.0, 0.0)

puppet var waterCount = MAX_WATER_COUNT
puppet var food_count = 0 setget set_food_count, get_food_count
puppet var ammoCount = MAX_AMMO_COUNT

puppet var money_count = 0

puppet var inventory_minus_food_count = 0

puppet var move_speed = MAX_MOVE_SPEED
puppet var health_points = 10 setget set_health_points, get_health_points

puppet var is_moving_double_slow = false

master var bags = Array()
master var timers = Array()

puppet var is_other_window_focused:bool = false setget set_is_other_window_focused, get_is_other_window_focused

onready var player = $Sprite

func _ready():
	
	$StatsLabel/PlayerIDCountLabel.text = var2str(int(name))
	
	_update_health_bar()
	_update_item_labels()
	
	if is_network_master():
		$ListIcon.visible = true
		$StatsLabel.visible = true
		$ChatRoom.visible = true
	else:
		$ListIcon.visible = false
		$StatsLabel.visible = false
		$ChatRoom.visible = false


func _input(event):
	if(is_other_window_focused):
		direction = Vector2(0.0, 0.0)
	else:
		if is_network_master():
			if Input.is_action_pressed('die'):
				_die()
			
			if event is InputEventScreenTouch:
				if event.is_pressed():
					direction = player.get_local_mouse_position().normalized()
				else:
					direction = Vector2(0.0, 0.0)
			elif event is InputEventScreenDrag:
#				direction = player.to_local(event.position).normalized()
				direction = player.get_local_mouse_position().normalized()
			elif event is InputEventKey:
				if (Input.is_action_pressed('ui_left') && Input.is_action_pressed('ui_up')):
					direction = Vector2(-0.5, -0.5)
				elif (Input.is_action_pressed('ui_up') && Input.is_action_pressed('ui_right')):
					direction = Vector2(0.5, -0.5)
				elif (Input.is_action_pressed('ui_right') && Input.is_action_pressed('ui_down')):
					direction = Vector2(0.5, 0.5)
				elif (Input.is_action_pressed('ui_down') && Input.is_action_pressed('ui_left')):
					direction = Vector2(-0.5, 0.5)
				elif Input.is_action_pressed('ui_left'):
					direction = Vector2(-1.0, 0.0)
				elif Input.is_action_pressed('ui_right'):
					direction = Vector2(1.0, 0.0)
				elif Input.is_action_pressed('ui_up'):
					direction = Vector2(0.0, -1.0)
				elif Input.is_action_pressed('ui_down'):
					direction = Vector2(0.0, 1.0)
				else:
					direction = Vector2(0.0, 0.0)
			
			$StatsLabel/FPSCountLabel.text = var2str(int(Engine.get_frames_per_second()))
			$StatsLabel/PlayersCountLabel.text = var2str(int(Global_Network.players.size()))
			
			rset_unreliable('slave_position', position)
			rset('slave_movement', direction)
#			_move(direction)
		else:
#			_move(slave_movement)
			position = slave_position
		
		if get_tree().is_network_server():
			Global_Network.update_position(int(name), position)


func _physics_process(delta):
	
	if(direction):
		position = position + direction * move_speed * delta
	
	if(waterCount >= 1):
		waterCount -= delta
		regen(delta)
		_update_item_labels()
	else:
		damage(delta)
		_update_item_labels()
		_no_water_left()
	
	if(food_count >= 1):
		food_count -= delta * 0.1
		var inventory_item = $ListMenu/Control.inventory_get_item_by_id_player(1)
		if(!inventory_item):
			food_count = 0
			money_count = 0
			if($ListMenu/Control.inventory_get_slot_by_item_id_player(1)):
				$ListMenu/Control.inventory_remove_item_player(int($ListMenu/Control.inventory_get_slot_by_item_id_player(1)), true)
		else:
			inventory_minus_food_count += delta * 0.1
			if(!is_other_window_focused && inventory_minus_food_count < food_count):
				$ListMenu/Control.inventory_remove_item_player(int($ListMenu/Control.inventory_get_slot_by_item_id_player(1)), false, int(inventory_minus_food_count))
			inventory_minus_food_count = inventory_minus_food_count - int(inventory_minus_food_count)
			$ListMenu/Control._update_slots_player()
			if(is_moving_double_slow):
				is_moving_double_slow = false
				move_speed = MAX_MOVE_SPEED
	else:
		if(!is_moving_double_slow):
			is_moving_double_slow = true
			move_speed = move_speed / 2
#		_no_food_left()
	money_count = food_count
	_update_item_labels()
	update_player_food()
	update_player_money()

func _update_health_bar():
	$GUI/HealthBar.value = health_points


func _update_item_labels():
	
	$StatsLabel/HealthCountLabel.text = var2str(int(health_points)) + "/" + var2str(int(MAX_HP))
	$StatsLabel/WaterCountLabel.text = var2str(int(waterCount)) + "/" + var2str(int(MAX_WATER_COUNT))
	$StatsLabel/AmmoCountLabel.text = var2str(int(ammoCount)) + "/" + var2str(int(MAX_AMMO_COUNT))
	if(waterCount >= 1):
		$StatsLabel/WaterLabel.set("custom_colors/font_color", Color(1,1,1))
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
	bagSprite.set_centered(true)
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
#	for bag in bags:
#		bag.queue_free() it crashes whole game after some time
	pass


func _on_RespawnTimer_timeout():
	set_physics_process(true)
	for child in get_children():
		if child.has_method('show') && is_network_master():
			child.show()
	$Sprite.show() # show player skin for other players
	
	$GUI.show() # show player health and nickname for other players
	$CollisionShape2D.disabled = false
	health_points = MAX_HP
	_update_health_bar()


func _no_water_left():
	$StatsLabel/WaterLabel.set("custom_colors/font_color", Color(1,0,0))


#func _no_food_left():
#	$StatsLabel/FoodLabel.set("custom_colors/font_color", Color(1,0,0))


func _no_ammo_left():
	$StatsLabel/AmmoLabel.set("custom_colors/font_color", Color(1,0,0))


func init(nickname, start_position, is_slave):
	$GUI/Nickname.text = nickname
#	global_position = start_position
	
	$ListMenu/Control.load_data_player(nickname)
		
#	if is_slave:
#		$Sprite.texture = load('res://player/character-alt.png')
	if is_network_master():
		$Camera2D.current = 1
		$ChatRoom.host_room()


func town_entered():
	$ListIcon.modulate = Color(1,1,0,0.5)
	
	$ListMenu/Control._show_shop()


func town_exited():
	$ListIcon.modulate = Color(1,1,1,0.5)
	
	$ListMenu/Control._hide_shop()


func update_player_money():
	if($ListMenu/Control.inventory_get_item_by_id_player(1)):
		money_count = $ListMenu/Control.inventory_get_item_by_id_player(1).amount
	else:
		money_count = 0
	$StatsLabel/MoneyCountLabel.set_text(var2str(int(money_count)))


func update_player_food():
	if($ListMenu/Control.inventory_get_item_by_id_player(1)):
		food_count = $ListMenu/Control.inventory_get_item_by_id_player(1).amount
		$StatsLabel/FoodLabel.set("custom_colors/font_color", Color(1,1,1))
	else:
		food_count = 0
		$StatsLabel/FoodLabel.set("custom_colors/font_color", Color(1,0,0))
	$StatsLabel/FoodCountLabel.set_text(var2str(int(food_count)))


func _on_Player_area_entered(area):
	if area.has_method("get_health_points"): # it is player
		if(health_points <= area.get_health_points()):
			_die()
	elif(area.has_method("_update_town_labels")): # it is town
		$ListMenu/Control.load_data_shop(area.get_node("Label").text)


func set_health_points(hp:int)->void:
	health_points = hp


func get_health_points():
	return health_points


func set_is_other_window_focused(is_focused):
	is_other_window_focused = is_focused


func get_is_other_window_focused():
	return is_other_window_focused


func set_food_count(count):
	food_count = count

func get_food_count():
	return food_count