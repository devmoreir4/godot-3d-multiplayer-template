extends Control
class_name MultiplayerChatUI

@onready var chat: RichTextLabel = $ChatLayout/Chat
@onready var message: LineEdit = $ChatLayout/Message
@onready var feed_timer: Timer = $FeedTimer

signal message_sent(message_text: String)

const MAX_CHAT_MESSAGES: int = 100
const MAX_VISIBLE_MESSAGES: int = 8
const FEED_VISIBLE_SECONDS: float = 6.0
const FEED_FADE_SECONDS: float = 0.35

var chat_visible: bool = false
var chat_history: Array[String] = []
var fade_tween: Tween

func _ready() -> void:
	message.text_submitted.connect(_on_message_submitted)
	feed_timer.timeout.connect(_on_feed_timer_timeout)
	feed_timer.wait_time = FEED_VISIBLE_SECONDS
	show()
	clear_chat()

func toggle_chat() -> void:
	if chat_visible:
		close_chat()
		return

	chat_visible = true
	_stop_feed_animation()
	_show_feed()
	message.show()
	await get_tree().process_frame
	if not chat_visible:
		return
	message.grab_focus()

func close_chat() -> void:
	chat_visible = false
	message.text = ""
	message.release_focus()
	message.hide()

	if chat_history.is_empty():
		chat.hide()
	else:
		_show_feed_temporarily()

func is_chat_visible() -> bool:
	return chat_visible

func _on_message_submitted(_submitted_text: String) -> void:
	var message_text := message.text.strip_edges()
	if message_text.is_empty():
		return

	close_chat()
	message_sent.emit(message_text)

func add_message(nick: String, msg: String) -> void:
	var formatted_message := _escape_bbcode("%s: %s" % [nick, msg])
	chat_history.append(formatted_message)
	while chat_history.size() > MAX_CHAT_MESSAGES:
		chat_history.pop_front()

	_render_chat_history()
	if chat_visible:
		_stop_feed_animation()
		_show_feed()
	else:
		_show_feed_temporarily()

func _render_chat_history() -> void:
	chat.clear()
	var first_message := maxi(0, chat_history.size() - MAX_VISIBLE_MESSAGES)
	for index in range(first_message, chat_history.size()):
		chat.append_text(chat_history[index])
		if index < chat_history.size() - 1:
			chat.append_text("\n")

func _show_feed_temporarily() -> void:
	_stop_feed_animation()
	_show_feed()
	feed_timer.start()

func _show_feed() -> void:
	chat.modulate.a = 1.0
	chat.show()

func _on_feed_timer_timeout() -> void:
	if chat_visible:
		return

	_stop_fade_tween()
	fade_tween = create_tween()
	fade_tween.tween_property(chat, "modulate:a", 0.0, FEED_FADE_SECONDS)
	fade_tween.tween_callback(chat.hide)

func _stop_feed_animation() -> void:
	feed_timer.stop()
	_stop_fade_tween()

func _stop_fade_tween() -> void:
	if fade_tween and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = null

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")

func clear_chat() -> void:
	_stop_feed_animation()
	chat_history.clear()
	chat.clear()
	chat.modulate.a = 1.0
	chat.hide()
	message.text = ""
	message.release_focus()
	message.hide()
	chat_visible = false
