extends Control
class_name PlayerListUI

const PLAYER_ROW_HEIGHT := 28.0
const MAX_VISIBLE_ROWS := 8
const RESERVED_VERTICAL_SPACE := 190.0

@onready var panel: PanelContainer = $SafeArea/CenterContainer/Panel
@onready var count_label: Label = $SafeArea/CenterContainer/Panel/MarginContainer/Content/Count
@onready var player_scroll: ScrollContainer = $SafeArea/CenterContainer/Panel/MarginContainer/Content/PlayerScroll
@onready var players_label: RichTextLabel = $SafeArea/CenterContainer/Panel/MarginContainer/Content/PlayerScroll/Players

var _player_count := 0

func _ready() -> void:
	resized.connect(_update_layout)
	_update_layout()
	hide()

func show_players(players: Dictionary, local_peer_id: int) -> void:
	refresh_players(players, local_peer_id)
	player_scroll.scroll_vertical = 0
	show()

func hide_players() -> void:
	hide()

func refresh_players(players: Dictionary, local_peer_id: int) -> void:
	var peer_ids: Array[int] = []
	for peer_id_value in players:
		var peer_id := int(peer_id_value)
		if peer_id > 0:
			peer_ids.append(peer_id)
	peer_ids.sort()
	_player_count = peer_ids.size()

	count_label.text = "%d online" % _player_count
	players_label.clear()
	for index in range(peer_ids.size()):
		var peer_id := peer_ids[index]
		var player_info: Dictionary = players.get(peer_id, {})
		var nickname := Network.sanitize_nickname(
			str(player_info.get("nick", "")),
			"Player_" + str(peer_id)
		)
		var local_marker := " [color=#8fdb9d](you)[/color]" if peer_id == local_peer_id else ""
		players_label.append_text(
			"[color=#77d28b]>[/color] [b]%s[/b]%s [color=#9aa6a0]#%d[/color]"
			% [_escape_bbcode(nickname), local_marker, peer_id]
		)
		if index < peer_ids.size() - 1:
			players_label.append_text("\n")
	_update_layout()

func _update_layout() -> void:
	if not panel or not player_scroll:
		return
	var panel_minimum_size := panel.custom_minimum_size
	panel_minimum_size.x = maxf(0.0, minf(420.0, size.x - 32.0))
	panel.custom_minimum_size = panel_minimum_size

	var visible_rows := maxi(1, mini(_player_count, MAX_VISIBLE_ROWS))
	var desired_height := float(visible_rows) * PLAYER_ROW_HEIGHT
	var viewport_limit := maxf(30.0, size.y - RESERVED_VERTICAL_SPACE)
	var scroll_minimum_size := player_scroll.custom_minimum_size
	scroll_minimum_size.y = minf(desired_height, viewport_limit)
	player_scroll.custom_minimum_size = scroll_minimum_size

	var players_minimum_size := players_label.custom_minimum_size
	players_minimum_size.y = float(maxi(1, _player_count)) * PLAYER_ROW_HEIGHT
	players_label.custom_minimum_size = players_minimum_size

func _escape_bbcode(text: String) -> String:
	return text.replace("[", "[lb]")
