extends Node2D

signal selection_confirmed(selected_cards: Array)

const ROW_Y := 400.0
const LAYOUT_SPEED := 0.15
const BASE_SCALE := Vector2.ONE
const SELECTED_SCALE := Vector2(1.2, 1.2)
const DISABLED_MODULATE := Color(1, 1, 1, 0.35)
const ENABLED_MODULATE := Color(1, 1, 1, 1)

var source_cards: Array[Node2D] = []
var selected_cards: Array[Node2D] = []
var selection_count := 1
var allowed_category := ""
var require_matching_card_id := false
var confirm_button: TextureButton
var player_hand_ref: Node


func _ready() -> void:
	_hide_placeholder_cards()
	confirm_button = $TextureButton
	confirm_button.disabled = true
	confirm_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	confirm_button.pressed.connect(_on_confirm_pressed)


func configure(action_config: Dictionary, hand_cards: Array[Node2D], player_hand: Node) -> void:
	selection_count = int(action_config.get("selection_count", 1))
	allowed_category = str(action_config.get("allowed_category", "")).to_lower()
	require_matching_card_id = bool(action_config.get("require_matching_card_id", false))
	source_cards = hand_cards.duplicate()
	player_hand_ref = player_hand

	if not is_node_ready():
		await ready

	_connect_card_inputs()
	_layout_source_cards()
	_refresh_selection_state()


func _exit_tree() -> void:
	_restore_cards()


func _connect_card_inputs() -> void:
	for source_card in source_cards:
		var area: Area2D = source_card.get_node_or_null("Area2D")
		if area and not area.is_connected("input_event", Callable(self, "_on_card_input_event").bind(source_card)):
			area.input_event.connect(_on_card_input_event.bind(source_card))


func _on_card_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, source_card: Node2D) -> void:
	if source_card == null or not is_instance_valid(source_card):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_toggle_card_selection(source_card)


func _toggle_card_selection(source_card: Node2D) -> void:
	if not _is_card_selectable(source_card):
		return

	if source_card in selected_cards:
		selected_cards.erase(source_card)
	else:
		if selected_cards.size() >= selection_count:
			return
		selected_cards.append(source_card)

	_refresh_selection_state()


func _refresh_selection_state() -> void:
	for source_card in source_cards:
		if source_card == null or not is_instance_valid(source_card):
			continue
		var is_selected := source_card in selected_cards
		source_card.scale = SELECTED_SCALE if is_selected else BASE_SCALE
		source_card.z_index = 20 if is_selected else 10
		source_card.modulate = ENABLED_MODULATE if _is_card_selectable(source_card) or is_selected else DISABLED_MODULATE

	confirm_button.disabled = not _is_selection_complete()
	confirm_button.mouse_filter = Control.MOUSE_FILTER_STOP if not confirm_button.disabled else Control.MOUSE_FILTER_IGNORE


func _is_card_selectable(source_card: Node2D) -> bool:
	if source_card == null or not is_instance_valid(source_card):
		return false

	var card_data: Dictionary = source_card.get_meta("card_data", {})
	if allowed_category != "" and str(card_data.get("category", "")).to_lower() != allowed_category:
		return false

	if require_matching_card_id and not selected_cards.is_empty() and source_card not in selected_cards:
		var first_selected_card := selected_cards[0]
		if first_selected_card and str(source_card.get_meta("card_id", "")) != str(first_selected_card.get_meta("card_id", "")):
			return false

	return true


func _is_selection_complete() -> bool:
	if selected_cards.size() != selection_count:
		return false

	if require_matching_card_id and selected_cards.size() > 1:
		var first_card_id := str(selected_cards[0].get_meta("card_id", ""))
		for source_card in selected_cards:
			if source_card == null or not is_instance_valid(source_card):
				return false
			if str(source_card.get_meta("card_id", "")) != first_card_id:
				return false

	return true


func _on_confirm_pressed() -> void:
	if not _is_selection_complete():
		return
	emit_signal("selection_confirmed", selected_cards.duplicate())


func _layout_source_cards() -> void:
	if player_hand_ref and player_hand_ref.has_method("layout_cards_at_row"):
		player_hand_ref.layout_cards_at_row(source_cards, ROW_Y, LAYOUT_SPEED)


func _restore_cards() -> void:
	for source_card in source_cards:
		if source_card == null or not is_instance_valid(source_card):
			continue
		source_card.scale = BASE_SCALE
		source_card.modulate = ENABLED_MODULATE
		source_card.z_index = 1

	if player_hand_ref and player_hand_ref.has_method("update_hand_position"):
		player_hand_ref.update_hand_position(LAYOUT_SPEED)


func _hide_placeholder_cards() -> void:
	for child in get_children():
		if child is Node2D and String(child.name).begins_with("Card"):
			child.visible = false
