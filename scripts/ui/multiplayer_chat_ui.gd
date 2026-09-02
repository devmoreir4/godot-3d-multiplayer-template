class_name MultiplayerChatUI
extends Control

signal message_sent(message_text: String)

const MAX_CHAT_MESSAGES: int = 100
const MAX_VISIBLE_MESSAGES: int = 8
const FEED_VISIBLE_SECONDS: float = 6.0
const FEED_FADE_SECONDS: float = 0.35
const SAFE_AREA_MARGIN := 16.0
const MIN_CHAT_WIDTH := 280.0
const MAX_CHAT_WIDTH := 480.0
const MAX_CHAT_HEIGHT := 268.0

var chat_visible: bool = false
var chat_history: Array[String] = []
var fade_tween: Tween

@onready var chat: RichTextLabel = $ChatLayout/Chat
@onready var message: LineEdit = $ChatLayout/Message
@onready var feed_timer: Timer = $FeedTimer


func _ready() -> void:
	message.text_submitted.connect(_on_message_submitted)
	feed_timer.timeout.connect(_on_feed_timer_timeout)
	feed_timer.wait_time = FEED_VISIBLE_SECONDS
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	show()
	clear_chat()


func _update_responsive_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var available_width := maxf(1.0, viewport_size.x - SAFE_AREA_MARGIN * 2.0)
	var preferred_width := clampf(viewport_size.x * 0.42, MIN_CHAT_WIDTH, MAX_CHAT_WIDTH)
	var target_width := minf(available_width, preferred_width)
	var target_height := minf(MAX_CHAT_HEIGHT, maxf(1.0, viewport_size.y - SAFE_AREA_MARGIN * 2.0))

	offset_left = SAFE_AREA_MARGIN
	offset_right = SAFE_AREA_MARGIN + target_width
	offset_bottom = -SAFE_AREA_MARGIN
	offset_top = -SAFE_AREA_MARGIN - target_height


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
