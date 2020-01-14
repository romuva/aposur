extends Control

var url_data_player:String
var url_data_shop:String
var inventory_max_slots:int = 20
var inventory_player:Dictionary = {}
var inventory_shop:Dictionary = {}
var data_player:Dictionary
var data_shop:Dictionary

var active_item_slot:int = -1
var drop_item_slot:int = -1

onready var is_dragging_item:bool = false
onready var mouse_button_released:bool = true
var dragged_item_slot:int = -1
onready var initial_mouse_pos:Vector2 = Vector2()
onready var is_cursor_inside_item_list:bool = false

var is_awaiting_split:bool = false
var split_item_slot:int = -1

var is_shop_selected = false

var is_inside_shop = false

var first_time_food_update = false

func _ready() -> void:

	set_process(false)
	set_process_input(false)
	
	_hide_center_content_item()


func load_data_player(name:String) -> void:

	url_data_player = "res://Database//data_player_" + name + ".json"
	data_player = Global_DataParser.load_data(url_data_player)
	if (data_player.empty()):
		var dict:Dictionary = {"inventory":{}}
		for slot in range (0, inventory_max_slots):
			if(slot == 0):
				dict["inventory"][str(slot)] = {"id": "3", "amount": 5}
			elif(slot == 1):
				dict["inventory"][str(slot)] = {"id": "1", "amount": 100}
			else:
				dict["inventory"][str(slot)] = {"id": "0", "amount": 0}
		Global_DataParser.write_data(url_data_player, dict)
		inventory_player = dict["inventory"]
		data_player = dict
	else:
		inventory_player = data_player["inventory"]
		
	load_items_player()


func load_data_shop(name:String) -> void:

	url_data_shop = "res://Database//data_shop_" + name + ".json"
	data_shop = Global_DataParser.load_data(url_data_shop)
	if (data_shop.empty()):
		var dict:Dictionary = {"inventory":{}}
		for slot in range (0, inventory_max_slots):
			dict["inventory"][str(slot)] = {"id": "0", "amount": 0}
		Global_DataParser.write_data(url_data_shop, dict)
		inventory_shop = dict["inventory"]
		data_shop = dict
	else:
		inventory_shop = data_shop["inventory"]
		
	load_items_shop()


func save_data() -> void:
	Global_DataParser.write_data(url_data_player, {"inventory": inventory_player})


func inventory_get_items_count_player() -> int:
	var count = 0
	for slot in range(0, inventory_max_slots):
		if (inventory_player[str(slot)]["id"] != "0"): 
			count = count + 1
	return count


func inventory_get_item_by_slot_player(slot:int):
	if(!inventory_player.empty()):
		return inventory_player[str(slot)]
	else:
		return 0


func inventory_get_item_by_slot_shop(slot:int):
	if(!inventory_shop.empty()):
		return inventory_shop[str(slot)]
	else:
		return 0


func inventory_get_item_by_id_player(id:int):
	if(!inventory_player.empty()):
		for slot in range(0, inventory_max_slots):
			if (inventory_player[str(slot)]["id"] == var2str(id)): 
				return inventory_player[str(slot)]
	else:
		return 0


func inventory_get_item_by_id_shop(id:int):
	if(!inventory_shop.empty()):
		for slot in range(0, inventory_max_slots):
			if (inventory_shop[str(slot)]["id"] == var2str(id)): 
				return inventory_shop[str(slot)]
	else:
		return 0


func inventory_get_slot_by_item_id_player(id:int):
	if(!inventory_player.empty()):
		for slot in range(0, inventory_max_slots):
			if (inventory_player[str(slot)]["id"] == var2str(id)): 
				return str(slot)
	else:
		return 0


func inventory_get_slot_by_item_id_shop(id:int):
	if(!inventory_shop.empty()):
		for slot in range(0, inventory_max_slots):
			if (inventory_shop[str(slot)]["id"] == var2str(id)): 
				return str(slot)
	else:
		return 0


func inventory_get_empty_slot_player() -> int:
	for slot in range(0, inventory_max_slots):
		if (inventory_player[str(slot)]["id"] == "0"): 
			return int(slot)
	print ("Player inventory is full!")
	return -1

func inventory_get_empty_slot_shop() -> int:
	for slot in range(0, inventory_max_slots):
		if (inventory_shop[str(slot)]["id"] == "0"): 
			return int(slot)
	print ("Shop inventory is full!")
	return -1

func inventory_split_item(slot, split_amount) -> int:
	if (split_amount <= 0):
		return -1
	var empty_slot = inventory_get_empty_slot_player()
	if empty_slot < 0:
		return empty_slot
		
	var new_amount = int(inventory_get_item_by_slot_player(slot)["amount"]) - split_amount
	inventory_player[str(slot)]["amount"] = new_amount
	inventory_player[str(empty_slot)] = {"id": inventory_player[str(slot)]["id"], "amount": split_amount}
	return empty_slot

func inventory_add_item_player(item_id:int, count:int = 1) -> int:
	var item_data:Dictionary = Global_ItemDatabase.get_item(str(item_id))
	if (item_data.empty()): 
		return -1
	if (int(item_data["stack_limit"]) <= 1):
		var slot = inventory_get_empty_slot_player()
		if (slot < 0): 
			return -1
		inventory_player[String(slot)] = {"id": String(item_id), "amount": count}
		return slot

	for slot in range (0, inventory_max_slots):
		if (inventory_player[String(slot)]["id"] == String(item_id)):
			if (int(item_data["stack_limit"]) > int(inventory_player[String(slot)]["amount"])):
				inventory_player[String(slot)]["amount"] = int(inventory_player[String(slot)]["amount"] + count)
				return slot

	var slot = inventory_get_empty_slot_player()
	if (slot < 0): 
		return -1
	inventory_player[String(slot)] = {"id": String(item_id), "amount": count}
	return slot


func inventory_add_item_shop(item_id:int, count:int = 1) -> int:
	var item_data:Dictionary = Global_ItemDatabase.get_item(str(item_id))
	if (item_data.empty()): 
		return -1
	if (int(item_data["stack_limit"]) <= 1):
		var slot = inventory_get_empty_slot_shop()
		if (slot < 0): 
			return -1
		inventory_shop[String(slot)] = {"id": String(item_id), "amount": count}
		return slot

	for slot in range (0, inventory_max_slots):
		if (inventory_shop[String(slot)]["id"] == String(item_id)):
			if (int(item_data["stack_limit"]) > int(inventory_shop[String(slot)]["amount"])):
				inventory_shop[String(slot)]["amount"] = int(inventory_shop[String(slot)]["amount"] + count)
				return slot

	var slot = inventory_get_empty_slot_shop()
	if (slot < 0): 
		return -1
	inventory_shop[String(slot)] = {"id": String(item_id), "amount": count}
	return slot


func inventory_remove_item_player(slot, is_all = false, count:int = 1) -> int:
	var new_amount = inventory_player[String(slot)]["amount"] - count
	if (new_amount < 1 || is_all == true):
		inventory_update_item_player(slot, 0, 0)
		return 0
	inventory_player[String(slot)]["amount"] = new_amount
	return new_amount


func inventory_remove_item_shop(slot, is_all = false, count:int = 1) -> int:
	var new_amount = inventory_shop[String(slot)]["amount"] - count
	if (new_amount < 1 || is_all == true):
		inventory_update_item_shop(slot, 0, 0)
		return 0
	inventory_shop[String(slot)]["amount"] = new_amount
	return new_amount


func inventory_update_item_player(slot:int, new_id:int, new_amount:int) -> void:
	if (slot < 0):
		return
	if (new_amount < 0):
		return
	if (Global_ItemDatabase.get_item(str(new_id)).empty()):
		return
	inventory_player[str(slot)] = {"id": str(new_id), "amount": int(new_amount)}


func inventory_update_item_shop(slot:int, new_id:int, new_amount:int) -> void:
	if (slot < 0):
		return
	if (new_amount < 0):
		return
	if (Global_ItemDatabase.get_item(str(new_id)).empty()):
		return
	inventory_shop[str(slot)] = {"id": str(new_id), "amount": int(new_amount)}


func inventory_mergeItem(from_slot:int, to_slot:int) -> void:
	if (from_slot < 0 or to_slot < 0):
		return
	
	var from_slot_inv_data:Dictionary = inventory_player[str(from_slot)]
	var to_slot_inv_data:Dictionary = inventory_player[str(to_slot)]
	
	var to_slot_stack_limit:int = (Global_ItemDatabase.get_item(inventory_player[str(to_slot)]["id"])["stack_limit"])
	var from_slot_stack_limit:int = (Global_ItemDatabase.get_item(inventory_player[str(from_slot)]["id"])["stack_limit"])
	
	if (to_slot_stack_limit <= 1 or from_slot_stack_limit <=1):
		return
	
	
	if (from_slot_inv_data["id"] != to_slot_inv_data["id"]):
		return
	if (int(to_slot_inv_data["amount"]) >= to_slot_stack_limit or int(from_slot_inv_data["amount"] >= to_slot_stack_limit)):
		inventory_move_item(from_slot, to_slot)
		return
	
	var to_slot_new_amount:int = (to_slot_inv_data["amount"]) + (from_slot_inv_data["amount"])
	var from_slot_new_amount:int = 0
	if (to_slot_new_amount > to_slot_stack_limit):
		from_slot_new_amount = to_slot_new_amount - to_slot_stack_limit
		inventory_update_item_player(to_slot, int(inventory_player[str(to_slot)]["id"]), to_slot_stack_limit)
		inventory_update_item_player(from_slot, int(inventory_player[str(from_slot)]["id"]), from_slot_new_amount)
	else:
		inventory_update_item_player(to_slot, int(inventory_player[str(to_slot)]["id"]), to_slot_new_amount)
		inventory_update_item_player(from_slot, 0, 0)


func inventory_move_item(from_slot:int, to_slot:int) -> void:
	var temp_to_slot_item:Dictionary = inventory_player[str(to_slot)]
	inventory_player[str(to_slot)] = inventory_player[str(from_slot)]
	inventory_player[str(from_slot)] = temp_to_slot_item

#warning-ignore:unused_argument
func _process(delta) -> void:
	if (is_dragging_item):
		$Panel/Sprite_DraggedItem.global_position = get_global_mouse_position()


func _input(event) -> void:
	if (!is_dragging_item):
#		if event.is_action_pressed("key_shift"):
#			isAwaitingSplit = true
		if event.is_action_released("key_shift"):
			is_awaiting_split = false

	if (event is InputEventMouseButton):
		if (!is_awaiting_split):
			if (event.is_action_pressed("mouse_leftbtn")):
				mouse_button_released = false
				initial_mouse_pos = get_viewport().get_mouse_position()
			if (event.is_action_released("mouse_leftbtn")):
				move_merge_item()
				end_drag_item()
		else:
			if (event.is_action_pressed("mouse_rightbtn")):
				if (active_item_slot >= 0):
					begin_split_item()
	if (event is InputEventMouseMotion):
		if (is_cursor_inside_item_list):
			active_item_slot = $Panel/ItemList.get_item_at_position($Panel/ItemList.get_local_mouse_position(),true)
			if (active_item_slot >= 0):
				$Panel/ItemList.select(active_item_slot, true)
				if (is_dragging_item or mouse_button_released):
					return
				if (!$Panel/ItemList.is_item_selectable(active_item_slot)):
					end_drag_item()
				if (initial_mouse_pos.distance_to(get_viewport().get_mouse_position()) > 0.0):
					begin_drag_item(active_item_slot)
		else:
			active_item_slot = -1


func load_items_player() -> void:
	$Panel/ItemList.clear()
	for slot in range(0, inventory_max_slots):
		$Panel/ItemList.add_item("", null, false)
		update_slot_player(slot)


func load_items_shop() -> void:
	$Panel/ItemList2.clear()
	for slot in range(0, inventory_max_slots):
		$Panel/ItemList2.add_item("", null, false)
		update_slot_shop(slot)


func update_slot_player(slot:int) -> void:
	if (slot < 0):
		return
	var inventory_item:Dictionary = data_player.inventory[str(slot)]
	var item_meta_data = Global_ItemDatabase.get_item(str(inventory_item["id"])).duplicate()
	var icon = ResourceLoader.load(item_meta_data["icon"])
	var amount = int(inventory_item["amount"])
	
	if(int(inventory_item["id"]) == 1 && !first_time_food_update):
		get_parent().get_parent().set_food_count(inventory_item["amount"])
		first_time_food_update = true

	item_meta_data["amount"] = amount
	if (!item_meta_data["stackable"]):
		amount = " "
	$Panel/ItemList.set_item_text(slot, String(amount))
	$Panel/ItemList.set_item_icon(slot, icon)
	$Panel/ItemList.set_item_selectable(slot, int(inventory_item["id"]) > 0)
	$Panel/ItemList.set_item_metadata(slot, item_meta_data)
	$Panel/ItemList.set_item_tooltip(slot, item_meta_data["name"])
	$Panel/ItemList.set_item_tooltip_enabled(slot, int(inventory_item["id"]) > 0)


func update_slot_shop(slot:int) -> void:
	if (slot < 0):
		return
	var inventory_item:Dictionary = data_shop.inventory[str(slot)]
	var item_meta_data = Global_ItemDatabase.get_item(str(inventory_item["id"])).duplicate()
	var icon = ResourceLoader.load(item_meta_data["icon"])
	var amount = int(inventory_item["amount"])

	item_meta_data["amount"] = amount
	if (!item_meta_data["stackable"]):
		amount = " "
	$Panel/ItemList2.set_item_text(slot, String(amount))
	$Panel/ItemList2.set_item_icon(slot, icon)
	$Panel/ItemList2.set_item_selectable(slot, int(inventory_item["id"]) > 0)
	$Panel/ItemList2.set_item_metadata(slot, item_meta_data)
	$Panel/ItemList2.set_item_tooltip(slot, item_meta_data["name"])
	$Panel/ItemList2.set_item_tooltip_enabled(slot, int(inventory_item["id"]) > 0)


func _on_Button_AddItem_pressed() -> void:
#	Need to fix this later ^^
	$Panel/WindowDialog_AddItemWindow.rect_global_position = get_parent().get_parent().get_node("Camera2D").get_camera_position()
	$Panel/WindowDialog_AddItemWindow.popup()


func _on_AddItemWindow_Button_Close_pressed() -> void:
	$Panel/WindowDialog_AddItemWindow.hide()


func _on_AddItemWindow_Button_AddItem_pressed() -> void:
	var affected_slot = inventory_add_item_player($Panel/WindowDialog_AddItemWindow/AddItemWindow_SpinBox_ItemID.get_value())
	if (affected_slot >= 0):
		update_slot_player(affected_slot)


#warning-ignore:unused_argument
func _on_ItemList_item_rmb_selected(index:int, atpos:Vector2) -> void:
	if (is_dragging_item):
		return
	if (is_awaiting_split):
		return

	drop_item_slot = index
	var item_data:Dictionary = $Panel/ItemList.get_item_metadata(index)
	if (int(item_data["id"])) < 1: return
	var str_item_info:String = ""

	$Panel/WindowDialog_ItemMenu.set_position(get_viewport().get_mouse_position())
	$Panel/WindowDialog_ItemMenu.set_title(item_data["name"])
	$Panel/WindowDialog_ItemMenu/ItemMenu_TextureFrame_Icon.set_texture($Panel/ItemList.get_item_icon(index))

	str_item_info = "Name: [color=#00aedb] " + item_data["name"] + "[/color]\n"
	str_item_info = str_item_info + "Type: [color=#f37735] " + item_data["type"] + "[/color]\n"
	str_item_info = str_item_info + "Weight: [color=#00b159] " + String(item_data["weight"]) + "[/color]\n"
	str_item_info = str_item_info + "Sell Price: [color=#ffc425] " + String(item_data["sell_price"]) + "[/color] gold\n"
	str_item_info = str_item_info + "\n[color=#b3cde0]" + item_data["description"] + "[/color]"

	$Panel/WindowDialog_ItemMenu/ItemMenu_RichTextLabel_ItemInfo.set_bbcode(str_item_info)
	$Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropItem.set_text("(" + String(item_data["amount"]) + ") Drop" )
	active_item_slot = index
	$Panel/WindowDialog_ItemMenu.popup()


func _on_ItemMenu_Button_DropItem_pressed() -> void:
	var new_amount = inventory_remove_item_player(drop_item_slot)
	if (new_amount < 1):
		$Panel/WindowDialog_ItemMenu.hide()
	else:
		$Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropItem.set_text("(" + String(new_amount) + ") Drop")
	update_slot_player(drop_item_slot)

func _on_ItemMenu_Button_DropAllItem_pressed() -> void:
	var new_amount = inventory_remove_item_player(drop_item_slot, true)
	if (new_amount < 1):
		$Panel/WindowDialog_ItemMenu.hide()
	else:
		$Panel/WindowDialog_ItemMenu/ItemMenu_Button_DropAllItem.set_text("(" + String(new_amount) + ") Drop")
	update_slot_player(drop_item_slot)

func _on_Button_Save_pressed() -> void:
	save_data()

func begin_split_item() -> void:
	if active_item_slot < 0:
		return
	split_item_slot = active_item_slot
	var item_meta_data = $Panel/ItemList.get_item_metadata(split_item_slot)
	var available_amount = int(item_meta_data["amount"])
	if (available_amount > 1):
		$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.min_value = 1
		$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.max_value = available_amount -1
		$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.value = 1
		$Panel/WindowDialog_SplitItemWindow.popup()


func _on_SplitItemWindow_Button_Split_pressed() -> void:
	update_slot_player(inventory_split_item(split_item_slot, int($Panel/WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.value)))
	update_slot_player(split_item_slot)
	split_item_slot = -1
	$Panel/WindowDialog_SplitItemWindow.hide()


func begin_drag_item(index:int) -> void:
	if (is_dragging_item):
		return
	if (index < 0):
		return

	set_process(true)
	$Panel/Sprite_DraggedItem.texture = $Panel/ItemList.get_item_icon(index)
	$Panel/Sprite_DraggedItem.show()

	$Panel/ItemList.set_item_text(index, " ")
	$Panel/ItemList.set_item_icon(index, ResourceLoader.load(Global_ItemDatabase.get_item("0")["icon"]))

	dragged_item_slot = index
	is_dragging_item = true
	mouse_button_released = false
#	$Panel/Sprite_DraggedItem.global_translate(get_viewport().get_mouse_position())


func end_drag_item() -> void:
	set_process(false)
	dragged_item_slot = -1
	$Panel/Sprite_DraggedItem.hide()
	mouse_button_released = true
	is_dragging_item = false
	active_item_slot = -1


func move_merge_item() -> void:
	if (dragged_item_slot < 0):
		return
	if (active_item_slot < 0):
		update_slot_player(dragged_item_slot)
		return

	if (active_item_slot == dragged_item_slot):
		update_slot_player(dragged_item_slot)
	else:
		if ($Panel/ItemList.get_item_metadata(active_item_slot)["id"] == $Panel/ItemList.get_item_metadata(dragged_item_slot)["id"]):
			var itemData = $Panel/ItemList.get_item_metadata(active_item_slot)
			if (int(itemData["stack_limit"]) >= 2):
				inventory_mergeItem(dragged_item_slot, active_item_slot)
				update_slot_player(dragged_item_slot)
				update_slot_player(active_item_slot)
				return
			else:
				update_slot_player(dragged_item_slot)
				return
		else:
			inventory_move_item(dragged_item_slot, active_item_slot)
			update_slot_player(dragged_item_slot)
			update_slot_player(active_item_slot)


func _on_ItemList_mouse_entered() -> void:
	is_cursor_inside_item_list = true;


func _on_ItemList_mouse_exited() -> void:
	is_cursor_inside_item_list = false;


func _on_SplitItemWindow_Button_Cancel_pressed() -> void:
	$Panel/WindowDialog_SplitItemWindow.hide()


func _on_SplitItemWindow_HSlider_Amount_value_changed(value:int) -> void:
	$Panel/WindowDialog_SplitItemWindow/SplitItemWindow_Label_Amount.text = String(value)


func _on_ItemList_item_selected(index):
	var item_data:Dictionary = $Panel/ItemList.get_item_metadata(index)
	if(item_data.name.empty()): return
	
	_update_center_content_item(item_data)
	is_shop_selected = false
	if(is_inside_shop):
		$Panel/Button_SellBuyDrop.text = "Sell"

func _on_ItemList2_item_selected(index):
	var item_data:Dictionary = $Panel/ItemList2.get_item_metadata(index)
	if(item_data.name.empty()): return
	
	_update_center_content_item(item_data)
	is_shop_selected = true
	if(is_inside_shop):
		$Panel/Button_SellBuyDrop.text = "Buy"


func _update_center_content_item(item_data:Dictionary) -> void:
	$Panel/SelectedItemNameLabel.text = var2str(item_data.name).replace('"', '')
	$Panel/SelectedItemIconSprite.texture = load(item_data.icon)
	$Panel/CountLabel.text = var2str(item_data.amount).replace('"', '')
	$Panel/PriceLabel.text = "Price: " + var2str(int(item_data.sell_price)).replace('"', '')
	$Panel/WeightLabel.text = "Weight: " + var2str(item_data.weight).replace('"', '')
	$Panel/DescriptionLabel.text = var2str(item_data.description).replace('"', '')
	$Panel/LineEdit.text = var2str(item_data.amount).replace('"', '')
	if(int(item_data.amount) == 1):
		$Panel/HSlider.min_value = 0
	else:
		$Panel/HSlider.min_value = 1
	$Panel/HSlider.max_value = item_data.amount
	$Panel/HSlider.set_value(float(item_data.amount))
	$Panel/HSlider.tick_count = int(item_data.amount / 10) + 2

	if(!$Panel/SelectedItemNameLabel.text):
		_hide_center_content_item()
	else:
		_show_center_content_item()

func _hide_center_content_item() -> void:
	$Panel/SelectedItemNameLabel.hide()
	$Panel/SelectedItemIconSprite.hide()
	$Panel/CountLabel.hide()
	$Panel/PriceLabel.hide()
	$Panel/WeightLabel.hide()
	$Panel/DescriptionLabel.hide()
	$Panel/HSlider.hide()
	$Panel/LineEdit.hide()
	$Panel/Button_SellBuyDrop.hide()


func _show_center_content_item() -> void:
	$Panel/SelectedItemNameLabel.show()
	$Panel/SelectedItemIconSprite.show()
	$Panel/CountLabel.show()
	$Panel/PriceLabel.show()
	$Panel/WeightLabel.show()
	$Panel/DescriptionLabel.show()
	$Panel/HSlider.show()
	$Panel/LineEdit.show()
	$Panel/Button_SellBuyDrop.show()


func _on_HSlider_value_changed(value):
	$Panel/LineEdit.text = var2str(int(value)).replace('"', '')


func _on_Button_SellBuyDrop_pressed():
	
	var selected_items_player = $Panel/ItemList.get_selected_items()
	var selected_items_shop = $Panel/ItemList2.get_selected_items()
	
	var slot_id_item_player:int
	var slot_id_item_shop:int
	
	var slot_id_money_player:int
	var slot_id_money_shop:int
	
	var money_shop
	var money_player

	var amount = int($Panel/LineEdit.text)
	if(amount == 0): return
	if(inventory_get_items_count_player() == 0): return
	
	if(!is_inside_shop):
		slot_id_item_player = int(selected_items_player[0])
		print("Dropped from slot: " + var2str(slot_id_item_player))
		if(amount > inventory_get_item_by_slot_player(slot_id_item_player).amount):
			inventory_remove_item_player(slot_id_item_player, true)
		else:
			inventory_remove_item_player(slot_id_item_player, false, amount) # need upgrade so it drops bag sprite with items in it
		_update_slots_player()
		_update_center_content_item($Panel/ItemList.get_item_metadata(slot_id_item_player))
		return
		
	if(is_shop_selected):
		money_player = inventory_get_item_by_id_player(1)
		
		if(inventory_get_item_by_id_shop(1) == null):
			slot_id_money_shop = inventory_get_empty_slot_shop()
		else:
			slot_id_money_shop = int(inventory_get_slot_by_item_id_shop(1))
		if(inventory_get_slot_by_item_id_player(1) == null):
			print("No money player!")
			return
		slot_id_money_player = int(inventory_get_slot_by_item_id_player(1))
		slot_id_item_shop  = int(selected_items_shop[0])
			
		var item_id_money_shop = int(inventory_get_item_by_slot_player(slot_id_money_player).id)
		var item_id_player = int(inventory_get_item_by_slot_shop(slot_id_item_shop).id)
		
		var item_cost_player = Global_ItemDatabase.get_item(var2str(item_id_player)).sell_price
		
		if(money_player == null || money_player.amount < amount * item_cost_player):
			print("Not enough money player!")
			return
		
		if(amount > int(inventory_get_item_by_slot_shop(slot_id_item_shop).amount)): return # protect against same item trade hack
		
		inventory_add_item_player(item_id_player, amount)
		inventory_add_item_shop(item_id_money_shop, amount * item_cost_player)
		inventory_remove_item_player(slot_id_money_player, false, amount * item_cost_player)
		inventory_remove_item_shop(slot_id_item_shop, false, amount)
		_update_slots_player()
		_update_slots_shop()
		_update_center_content_item($Panel/ItemList2.get_item_metadata(slot_id_item_shop))
	else:
		money_shop = inventory_get_item_by_id_shop(1)
		
		if(inventory_get_item_by_id_player(1) == null):
			slot_id_money_player = inventory_get_empty_slot_player()
		else:
			slot_id_money_player  = int(inventory_get_slot_by_item_id_player(1))
		if(inventory_get_slot_by_item_id_shop(1) == null):
			print("No money shop!")
			return
		slot_id_money_shop = int(inventory_get_slot_by_item_id_shop(1))
		slot_id_item_player = int(selected_items_player[0])

		var item_id_money_player = int(inventory_get_item_by_slot_shop(slot_id_money_shop).id)
		var item_id_shop = int(inventory_get_item_by_slot_player(slot_id_item_player).id)

		var item_cost_shop = Global_ItemDatabase.get_item(var2str(item_id_shop)).sell_price

		if(money_shop == null || money_shop.amount < amount * item_cost_shop):
			print("Not enough money shop!")
			return

		if(amount > int(inventory_get_item_by_slot_player(slot_id_item_player).amount)): return
		
		inventory_add_item_player(item_id_money_player, amount * item_cost_shop)
		inventory_add_item_shop(item_id_shop, amount)
		inventory_remove_item_player(slot_id_item_player, false, amount)
		inventory_remove_item_shop(slot_id_money_shop, false, amount * item_cost_shop)
		_update_slots_player()
		_update_slots_shop()
		_update_center_content_item($Panel/ItemList.get_item_metadata(slot_id_item_player))

func _update_slots_player():
	for slot in range(0, inventory_max_slots):
		update_slot_player(int(slot))

func _update_slots_shop():
	for slot in range(0, inventory_max_slots):
		update_slot_shop(int(slot))

func _hide_shop() -> void:
	$Panel/SelectedItemNameLabel.hide()
	$Panel/SelectedItemIconSprite.hide()
	$Panel/CountLabel.hide()
	$Panel/PriceLabel.hide()
	$Panel/WeightLabel.hide()
	$Panel/DescriptionLabel.hide()
	$Panel/HSlider.hide()
	$Panel/LineEdit.hide()
	$Panel/Button_SellBuyDrop.hide()
	$Panel/Button_SellBuyDrop.text = "Drop"
	is_inside_shop = false
	
	$Panel/ItemList2.hide()
	$Panel/Label2.hide()


func _show_shop() -> void:
	$Panel/SelectedItemNameLabel.show()
	$Panel/SelectedItemIconSprite.show()
	$Panel/CountLabel.show()
	$Panel/PriceLabel.show()
	$Panel/WeightLabel.show()
	$Panel/DescriptionLabel.show()
	$Panel/HSlider.show()
	$Panel/LineEdit.show()
	$Panel/Button_SellBuyDrop.show()
	$Panel/Button_SellBuyDrop.text = "Sell"
	is_inside_shop = true
	
	$Panel/ItemList2.show()
	$Panel/Label2.show()


func _on_Control_visibility_changed():
	if(is_visible_in_tree()):
		get_parent().get_parent().set_is_other_window_focused(true)
	else:
		get_parent().get_parent().set_is_other_window_focused(false)


func _on_ItemList_visibility_changed():
	var item_food = inventory_get_item_by_id_player(1)
	if(!is_visible_in_tree() && item_food):
		var food_count = int(item_food.amount)
		if(food_count > 0):
			get_parent().get_parent().set_food_count(int(food_count))
		else:
			get_parent().get_parent().set_food_count(0)

func _on_ItemList_item_activated(index):
	pass # Replace with function body.
