extends Node2D

const COLLISON_MASK = 1
const COLLISON_MASK_TARGET = 8
const DEFAULT_DRAW_SPEED = 0.1
const RETURN_TO_HAND_SPEED = 0.1
const CARD_BOTTOM_OFFSET = 144.0
const HOVER_PREVIEW_SCENE = preload("res://cards/scenes/card_2_scale.tscn")
const DECK_VIEW_CARD_META = "deck_view_card"
const CARD_REMOVING_META = "card_removing"

var card_drag
var screen_size
var card_is_hovered
var player_hand_ref
var hover_preview
var hovered_card
var battle_manager_ref


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_ref = $"../PlayerSide/PlayerDecks/PlayerHand"
	battle_manager_ref = $"../BattleManager"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_release)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var deck_ref = $"../PlayerSide/PlayerDecks/Deck"
	if hovered_card and not is_instance_valid(hovered_card):
		hovered_card = null
		card_is_hovered = false
		hide_hover_preview()
	if battle_manager_ref and battle_manager_ref.has_method("is_selection_active") and battle_manager_ref.is_selection_active():
		if hovered_card:
			set_hovered_card(null)
		return
	if card_drag:
		var mouse_pos = get_global_mouse_position()
		card_drag.position = Vector2(clamp(mouse_pos.x, 0, screen_size.x), clamp(mouse_pos.y, 0, screen_size.y))
		return

	var card_under_mouse = raycast_check_for_card()
	if card_under_mouse != hovered_card:
		set_hovered_card(card_under_mouse)


#func _input(event):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.is_pressed():
			#var card = raycast_check_for_card()
			#if card:
				#start_drag(card)
		#else:
			#if card_drag:
				#finish_drag()


func start_drag(card):
	if player_hand_ref and player_hand_ref.has_method("has_card") and not player_hand_ref.has_card(card):
		return
	if battle_manager_ref and battle_manager_ref.has_method("can_player_interact") and not battle_manager_ref.can_player_interact():
		return

	card_drag = card
	set_hovered_card(null)
	card_drag.set_visuals_visible(true)
	hide_hover_preview()
	_set_card_collision_disabled(card_drag, true)
	card_drag.z_index = 3


func finish_drag():
	var target_found = raycast_check_for_target()
	if target_found and battle_manager_ref and battle_manager_ref.has_method("try_play_card"):
		if battle_manager_ref.try_play_card(card_drag, target_found):
			card_drag = null
			return

	set_hovered_card(null)
	card_drag.set_visuals_visible(true)
	hide_hover_preview()
	_set_card_collision_disabled(card_drag, false)
	card_drag.z_index = 1
	player_hand_ref.add_card_to_hand(card_drag, RETURN_TO_HAND_SPEED)
	card_drag = null


func discard_card(card):
	if card == null:
		return
	_prepare_card_for_removal(card)
	clear_card_hover(card)
	if player_hand_ref and player_hand_ref.has_method("has_card") and not player_hand_ref.has_card(card):
		return
	if battle_manager_ref and battle_manager_ref.has_method("discard_player_card_from_hand"):
		battle_manager_ref.discard_player_card_from_hand(card)


func connect_card_signals(card):
	card.connect("hovered", on_hover_card)
	card.connect("hovered_off", on_hover_off_card)


func on_left_click_release():
	if card_drag:
		finish_drag()


func on_hover_card(card):
	if card_drag:
		return
	if card and card.has_meta(CARD_REMOVING_META) and card.get_meta(CARD_REMOVING_META):
		return
	if battle_manager_ref and battle_manager_ref.has_method("is_selection_active") and battle_manager_ref.is_selection_active():
		return
	set_hovered_card(card)
	


func on_hover_off_card(card):
	if !card_drag:
		var new_card_hovered = raycast_check_for_card()
		if new_card_hovered == card:
			new_card_hovered = null
		set_hovered_card(new_card_hovered)


func highlight_card(card, hovered):
	var base_position = card.position
	if card.hand_position != null and card.position.distance_to(card.hand_position) <= 1.0:
		base_position = card.hand_position
	if hovered:
		card.set_visuals_visible(false)
		show_hover_preview(card, base_position)
		card.z_index = 2
	else:
		card.set_visuals_visible(true)
		hide_hover_preview()
		card.z_index = 1


func set_hovered_card(card):
	if hovered_card == card:
		return

	if hovered_card:
		highlight_card(hovered_card, false)

	hovered_card = card
	card_is_hovered = hovered_card != null

	if hovered_card:
		highlight_card(hovered_card, true)


func show_hover_preview(card, base_position: Vector2):
	hide_hover_preview()
	hover_preview = HOVER_PREVIEW_SCENE.instantiate()
	hover_preview.registers_hover_signals = false
	card.get_parent().add_child(hover_preview)
	hover_preview.copy_display_from(card)
	hover_preview.position = base_position - Vector2(0, CARD_BOTTOM_OFFSET)
	hover_preview.z_index = card.z_index + 10

	var preview_area = hover_preview.get_node_or_null("Area2D")
	if preview_area:
		preview_area.monitoring = false
		preview_area.monitorable = false

	var preview_collision = hover_preview.get_node_or_null("Area2D/CollisionShape2D")
	if preview_collision:
		preview_collision.disabled = true


func hide_hover_preview():
	if hover_preview:
		hover_preview.queue_free()
		hover_preview = null


func clear_card_hover(card = null) -> void:
	if card == null or hovered_card == card:
		set_hovered_card(null)
	if card_drag == card:
		hide_hover_preview()
		card_drag = null
	elif card == null:
		hide_hover_preview()


func _set_card_collision_disabled(card: Node2D, disabled: bool) -> void:
	if card == null:
		return

	var collision: CollisionShape2D = card.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = disabled


func _prepare_card_for_removal(card: Node2D) -> void:
	if card == null:
		return
	card.set_meta(CARD_REMOVING_META, true)
	_set_card_collision_disabled(card, true)
	if card.has_method("set_visuals_visible"):
		card.set_visuals_visible(true)


func raycast_check_for_target():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISON_MASK_TARGET
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return result[0].collider.get_parent()
	return null


func raycast_check_for_card():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISON_MASK
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var deck_ref = $"../PlayerSide/PlayerDecks/Deck"
		var deck_view_open: bool = deck_ref and deck_ref.has_method("is_deck_view_open") and deck_ref.is_deck_view_open()
		var filtered_cards: Array = []
		for hit in result:
			var card = hit.collider.get_parent()
			if card.has_meta(CARD_REMOVING_META) and card.get_meta(CARD_REMOVING_META):
				continue
			var is_deck_view_card: bool = card.has_meta(DECK_VIEW_CARD_META) and card.get_meta(DECK_VIEW_CARD_META)
			if deck_view_open and is_deck_view_card:
				filtered_cards.append(hit)
			elif not deck_view_open and not is_deck_view_card:
				filtered_cards.append(hit)
		if filtered_cards.size() > 0:
			return get_highest_z_card(filtered_cards)
	return null


func get_highest_z_card(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card
