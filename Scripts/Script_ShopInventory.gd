extends Panel

var url_TownData:String
var inventory:Dictionary = {}
var inventory_maxSlots:int = 20
var townData:Dictionary

var activeItemSlot:int = -1
var dropItemSlot:int = -1

onready var isDraggingItem:bool = false
onready var mouseButtonReleased:bool = true
var draggedItemSlot:int = -1
onready var initial_mousePos:Vector2 = Vector2()
onready var cursor_insideItemList:bool = false

var isAwaitingSplit:bool = false
var splitItemSlot:int = -1


func _ready() -> void:

	set_process(false)
	set_process_input(true)


func load_town_data(town_name:String) -> void:
#	print(""+get_parent().get_parent().get_node("GUI/Nickname").text)
	url_TownData = "res://Database//TownData_" + town_name + ".json"
	townData = Global_DataParser.load_data(url_TownData)
	if (townData.empty()):
		var dict:Dictionary = {"inventory":{}}
		for slot in range (0, inventory_maxSlots):
			dict["inventory"][str(slot)] = {"id": "0", "amount": 0}
		Global_DataParser.write_data(url_TownData, dict)
		inventory = dict["inventory"]
		townData = dict
	else:
		inventory = townData["inventory"]
	load_items()


func save_data() -> void:
	Global_DataParser.write_data(url_TownData, {"inventory": inventory})

func inventory_getItem(slot:int):
	if(!inventory.empty()):
		return inventory[str(slot)]
	else:
		return 0

func inventory_getItemById(id:int):
	if(!inventory.empty()):
		for slot in range(0, inventory_maxSlots):
			if (inventory[str(slot)]["id"] == var2str(id)): 
				return inventory[str(slot)]
	else:
		return 0

func inventory_getEmptySlot() -> int:
	for slot in range(0, inventory_maxSlots):
		if (inventory[str(slot)]["id"] == "0"): 
			return int(slot)
	print ("Inventory is full!")
	return -1

func inventory_splitItem(slot, split_amount) -> int:
	if (split_amount <= 0):
		return -1
	var emptySlot = inventory_getEmptySlot()
	if emptySlot < 0:
		return emptySlot
		
	var new_amount = int(inventory_getItem(slot)["amount"]) - split_amount
	inventory[str(slot)]["amount"] = new_amount
	inventory[str(emptySlot)] = {"id": inventory[str(slot)]["id"], "amount": split_amount}
	return emptySlot

func inventory_addItem(itemId:int) -> int:
	var itemData:Dictionary = Global_ItemDatabase.get_item(str(itemId))
	if (itemData.empty()): 
		return -1
	if (int(itemData["stack_limit"]) <= 1):
		var slot = inventory_getEmptySlot()
		if (slot < 0): 
			return -1
		inventory[String(slot)] = {"id": String(itemId), "amount": 1}
		return slot
		
	
	for slot in range (0, inventory_maxSlots):
		if (inventory[String(slot)]["id"] == String(itemId)):
			if (int(itemData["stack_limit"]) > int(inventory[String(slot)]["amount"])):
				inventory[String(slot)]["amount"] = int(inventory[String(slot)]["amount"] + 1)
				return slot

	var slot = inventory_getEmptySlot()
	if (slot < 0): 
		return -1
	inventory[String(slot)] = {"id": String(itemId), "amount": 1}
	return slot


func inventory_removeItem(slot, isAll = false) -> int:
	var newAmount = inventory[String(slot)]["amount"] - 1
	if (newAmount < 1 || isAll == true):
		inventory_updateItem(slot, 0, 0)
		return 0
	inventory[String(slot)]["amount"] = newAmount
	return newAmount

func inventory_updateItem(slot:int, new_id:int, new_amount:int) -> void:
	if (slot < 0):
		return
	if (new_amount < 0):
		return
	if (Global_ItemDatabase.get_item(str(new_id)).empty()):
		return
	inventory[str(slot)] = {"id": str(new_id), "amount": int(new_amount)}
	
func inventory_mergeItem(fromSlot:int, toSlot:int) -> void:
	if (fromSlot < 0 or toSlot < 0):
		return
	
	var fromSlot_invData:Dictionary = inventory[str(fromSlot)]
	var toSlot_invData:Dictionary = inventory[str(toSlot)]
	
	var toSlot_stackLimit:int = (Global_ItemDatabase.get_item(inventory[str(toSlot)]["id"])["stack_limit"])
	var fromSlot_stackLimit:int = (Global_ItemDatabase.get_item(inventory[str(fromSlot)]["id"])["stack_limit"])
	
	if (toSlot_stackLimit <= 1 or fromSlot_stackLimit <=1):
		return
	
	
	if (fromSlot_invData["id"] != toSlot_invData["id"]):
		return
	if (int(toSlot_invData["amount"]) >= toSlot_stackLimit or int(fromSlot_invData["amount"] >= toSlot_stackLimit)):
		inventory_moveItem(fromSlot, toSlot)
		return
	
	var toSlot_newAmount:int = (toSlot_invData["amount"]) + (fromSlot_invData["amount"])
	var fromSlot_newAmount:int = 0
	if (toSlot_newAmount > toSlot_stackLimit):
		fromSlot_newAmount = toSlot_newAmount - toSlot_stackLimit
		inventory_updateItem(toSlot, int(inventory[str(toSlot)]["id"]), toSlot_stackLimit)
		inventory_updateItem(fromSlot, int(inventory[str(fromSlot)]["id"]), fromSlot_newAmount)
	else:
		inventory_updateItem(toSlot, int(inventory[str(toSlot)]["id"]), toSlot_newAmount)
		inventory_updateItem(fromSlot, 0, 0)
		

func inventory_moveItem(fromSlot:int, toSlot:int) -> void:
	var temp_ToSlotItem:Dictionary = inventory[str(toSlot)]
	inventory[str(toSlot)] = inventory[str(fromSlot)]
	inventory[str(fromSlot)] = temp_ToSlotItem

#warning-ignore:unused_argument
func _process(delta) -> void:
	if (isDraggingItem):
		$Sprite_DraggedItem.global_position = get_viewport().get_mouse_position()

func _input(event) -> void:
	if (!isDraggingItem):
#		if event.is_action_pressed("key_shift"):
#			isAwaitingSplit = true
		if event.is_action_released("key_shift"):
			isAwaitingSplit = false

	if (event is InputEventMouseButton):
		if (!isAwaitingSplit):
			if (event.is_action_pressed("mouse_leftbtn")):
				mouseButtonReleased = false
				initial_mousePos = get_viewport().get_mouse_position()
			if (event.is_action_released("mouse_leftbtn")):
				move_merge_item()
				end_drag_item()
		else:
			if (event.is_action_pressed("mouse_rightbtn")):
				if (activeItemSlot >= 0):
					begin_split_item()
	if (event is InputEventMouseMotion):
		if (cursor_insideItemList):
			activeItemSlot = $ItemList2.get_item_at_position($ItemList2.get_local_mouse_position(),true)
			if (activeItemSlot >= 0):
				$ItemList2.select(activeItemSlot, true)
				if (isDraggingItem or mouseButtonReleased):
					return
				if (!$ItemList2.is_item_selectable(activeItemSlot)):
					end_drag_item()
				if (initial_mousePos.distance_to(get_viewport().get_mouse_position()) > 0.0):
					begin_drag_item(activeItemSlot)
		else:
			activeItemSlot = -1


func load_items() -> void:
	$ItemList2.clear()
	for slot in range(0, inventory_maxSlots):
		$ItemList2.add_item("", null, false)
		update_slot(slot)


func update_slot(slot:int) -> void:
	if (slot < 0):
		return
	var inventoryItem:Dictionary = townData.inventory[str(slot)]
	var itemMetaData = Global_ItemDatabase.get_item(str(inventoryItem["id"])).duplicate()
	var icon = ResourceLoader.load(itemMetaData["icon"])
	var amount = int(inventoryItem["amount"])

	itemMetaData["amount"] = amount
	if (!itemMetaData["stackable"]):
		amount = " "
	$ItemList2.set_item_text(slot, String(amount))
	$ItemList2.set_item_icon(slot, icon)
	$ItemList2.set_item_selectable(slot, int(inventoryItem["id"]) > 0)
	$ItemList2.set_item_metadata(slot, itemMetaData)
	$ItemList2.set_item_tooltip(slot, itemMetaData["name"])
	$ItemList2.set_item_tooltip_enabled(slot, int(inventoryItem["id"]) > 0)

func _on_Button_AddItem_pressed() -> void:
#	Need to fix this later ^^
	$WindowDialog_AddItemWindow.rect_global_position = get_parent().get_parent().get_node("Camera2D").get_camera_position()
	$WindowDialog_AddItemWindow.popup()


func _on_AddItemWindow_Button_Close_pressed() -> void:
	$WindowDialog_AddItemWindow.hide()


func _on_AddItemWindow_Button_AddItem_pressed() -> void:
	var affectedSlot = inventory_addItem($WindowDialog_AddItemWindow/AddItemWindow_SpinBox_ItemID.get_value())
	if (affectedSlot >= 0):
		update_slot(affectedSlot)


#warning-ignore:unused_argument
func _on_ItemList2_item_rmb_selected(index:int, atpos:Vector2) -> void:
	if (isDraggingItem):
		return
	if (isAwaitingSplit):
		return

	dropItemSlot = index
	var itemData:Dictionary = $ItemList2.get_item_metadata(index)
	if (int(itemData["id"])) < 1: return
	var strItemInfo:String = ""

	$WindowDialog_ItemMenu.set_position(get_viewport().get_mouse_position())
	$WindowDialog_ItemMenu.set_title(itemData["name"])
	$WindowDialog_ItemMenu/ItemMenu_TextureFrame_Icon.set_texture($ItemList2.get_item_icon(index))

	strItemInfo = "Name: [color=#00aedb] " + itemData["name"] + "[/color]\n"
	strItemInfo = strItemInfo + "Type: [color=#f37735] " + itemData["type"] + "[/color]\n"
	strItemInfo = strItemInfo + "Weight: [color=#00b159] " + String(itemData["weight"]) + "[/color]\n"
	strItemInfo = strItemInfo + "Sell Price: [color=#ffc425] " + String(itemData["sell_price"]) + "[/color] gold\n"
	strItemInfo = strItemInfo + "\n[color=#b3cde0]" + itemData["description"] + "[/color]"

	$WindowDialog_ItemMenu/ItemMenu_RichTextLabel_ItemInfo.set_bbcode(strItemInfo)
	$WindowDialog_ItemMenu/ItemMenu_Button_DropItem.set_text("(" + String(itemData["amount"]) + ") Drop" )
	activeItemSlot = index
	$WindowDialog_ItemMenu.popup()


func _on_ItemMenu_Button_DropItem_pressed() -> void:
	var newAmount = inventory_removeItem(dropItemSlot)
	if (newAmount < 1):
		$WindowDialog_ItemMenu.hide()
	else:
		$WindowDialog_ItemMenu/ItemMenu_Button_DropItem.set_text("(" + String(newAmount) + ") Drop")
	update_slot(dropItemSlot)

func _on_ItemMenu_Button_DropAllItem_pressed() -> void:
	var newAmount = inventory_removeItem(dropItemSlot, true)
	if (newAmount < 1):
		$WindowDialog_ItemMenu.hide()
	else:
		$WindowDialog_ItemMenu/ItemMenu_Button_DropAllItem.set_text("(" + String(newAmount) + ") Drop")
	update_slot(dropItemSlot)

func _on_Button_Save_pressed() -> void:
	save_data()

func begin_split_item() -> void:
	if activeItemSlot < 0:
		return
	splitItemSlot = activeItemSlot
	var itemMetaData = $ItemList2.get_item_metadata(splitItemSlot)
	var availableAmount = int(itemMetaData["amount"])
	if (availableAmount > 1):
		$WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.min_value = 1
		$WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.max_value = availableAmount -1
		$WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.value = 1
		$WindowDialog_SplitItemWindow.popup()


func _on_SplitItemWindow_Button_Split_pressed() -> void:
	update_slot(inventory_splitItem(splitItemSlot, int($WindowDialog_SplitItemWindow/SplitItemWindow_HSlider_Amount.value)))
	update_slot(splitItemSlot)
	splitItemSlot = -1
	$WindowDialog_SplitItemWindow.hide()


func begin_drag_item(index:int) -> void:
	if (isDraggingItem):
		return
	if (index < 0):
		return

	set_process(true)
	$Sprite_DraggedItem.texture = $ItemList2.get_item_icon(index)
	$Sprite_DraggedItem.show()

	$ItemList2.set_item_text(index, " ")
	$ItemList2.set_item_icon(index, ResourceLoader.load(Global_ItemDatabase.get_item("0")["icon"]))

	draggedItemSlot = index
	isDraggingItem = true
	mouseButtonReleased = false
	$Sprite_DraggedItem.global_translate(get_viewport().get_mouse_position())


func end_drag_item() -> void:
	set_process(false)
	draggedItemSlot = -1
	$Sprite_DraggedItem.hide()
	mouseButtonReleased = true
	isDraggingItem = false
	activeItemSlot = -1


func move_merge_item() -> void:
	if (draggedItemSlot < 0):
		return
	if (activeItemSlot < 0):
		update_slot(draggedItemSlot)
		return

	if (activeItemSlot == draggedItemSlot):
		update_slot(draggedItemSlot)
	else:
		if ($ItemList2.get_item_metadata(activeItemSlot)["id"] == $ItemList2.get_item_metadata(draggedItemSlot)["id"]):
			var itemData = $ItemList2.get_item_metadata(activeItemSlot)
			if (int(itemData["stack_limit"]) >= 2):
				inventory_mergeItem(draggedItemSlot, activeItemSlot)
				update_slot(draggedItemSlot)
				update_slot(activeItemSlot)
				return
			else:
				update_slot(draggedItemSlot)
				return
		else:
			inventory_moveItem(draggedItemSlot, activeItemSlot)
			update_slot(draggedItemSlot)
			update_slot(activeItemSlot)


func _on_ItemList2_mouse_entered() -> void:
	cursor_insideItemList = true;


func _on_ItemList2_mouse_exited() -> void:
	cursor_insideItemList = false;

func _on_SplitItemWindow_Button_Cancel_pressed() -> void:
	$WindowDialog_SplitItemWindow.hide()


func _on_SplitItemWindow_HSlider_Amount_value_changed(value:int) -> void:
	$WindowDialog_SplitItemWindow/SplitItemWindow_Label_Amount.text = String(value)
