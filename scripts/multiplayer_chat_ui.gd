extends Control
class_name MultiplayerChatUI

@onready var message: LineEdit = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Message
@onready var send: Button = $Panel/MarginContainer/VBoxContainer/HBoxContainer/Send
@onready var chat: RichTextLabel = $Panel/MarginContainer/VBoxContainer/Chat

signal message_sent(message_text: String)

const MAX_CHAT_MESSAGES: int = 100

var chat_visible: bool = false
var chat_history: Array[String] = []

func _ready():
	send.pressed.connect(_on_send_pressed)
	message.text_submitted.connect(_on_send_pressed)
	clear_chat()
	hide()

func toggle_chat():
	chat_visible = !chat_visible
	if chat_visible:
		show()
		await get_tree().process_frame
		message.grab_focus()
	else:
		hide()
		message.text = ""
		get_viewport().set_input_as_handled()

func is_chat_visible() -> bool:
	return chat_visible

func _on_send_pressed():
	var message_text = message.text.strip_edges()
	if message_text.is_empty():
		return

	message_sent.emit(message_text)

	message.text = ""
	message.grab_focus()

func add_message(nick: String, msg: String) -> void:
	var time: String = Time.get_time_string_from_system()
	var formatted_message := _escape_bbcode("[%s] %s: %s\n" % [time, nick, msg])
	chat_history.append(formatted_message)
	chat.append_text(formatted_message)
	_limit_chat_history()

func _limit_chat_history() -> void:
	if chat_history.size() <= MAX_CHAT_MESSAGES:
		return
	while chat_history.size() > MAX_CHAT_MESSAGES:
		chat_history.pop_front()
	_render_chat_history()

func _render_chat_history() -> void:
	chat.clear()
	for entry in chat_history:
		chat.append_text(entry)

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")

func clear_chat() -> void:
	chat_history.clear()
	chat.clear()
