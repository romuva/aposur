extends Control

var chat_display
var chat_input

var msg

var network_id
var nick


func _ready():
	chat_display = $RoomUI/ChatDisplay
	chat_input = $RoomUI/ChatInput
	
	get_tree().connect("connected_to_server", self, "enter_room")
	get_tree().connect("network_peer_connected", self, "user_entered")
	get_tree().connect("network_peer_disconnected", self, "user_exited")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func _server_disconnected():
	chat_display.text += "Disconnected from Server\n"
	leave_room()


func user_entered(id):
	chat_display.text += str(id) + " joined the room\n"


func user_exited(id):
	chat_display.text += str(id) + " left the room\n"


func host_room():
	chat_display.text = "Room Created\n"
	enter_room()


func enter_room():
	chat_display.text = "Successfully joined room\n"


func leave_room():
	get_tree().set_network_peer(null)
	chat_display.text += "Left Room\n"


func _input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ENTER:
			send_message()


func send_message():
	msg = chat_input.text
	chat_input.text = ""
	network_id = get_tree().get_network_unique_id()
	nick = get_parent().get_node("GUI/Nickname").get_text()
	rpc("receive_message", network_id, nick, msg)


sync func receive_message(id, player_name, msg):
	for player in get_tree().get_nodes_in_group("players"):
		if(!msg.empty()):
			player.get_node("ChatRoom/RoomUI/ChatDisplay").text += str(player_name) + ": " + msg + "\n"


func _on_ChatInput_focus_entered():
	get_parent().is_chat_focused = true


func _on_ChatInput_focus_exited():
	get_parent().is_chat_focused = false


func _on_ChatInput_text_entered(new_text):
	$RoomUI/ChatInput.release_focus()
