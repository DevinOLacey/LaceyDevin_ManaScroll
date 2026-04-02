extends Node2D

const COLLISON_MASK = 1
const COLLISON_MASK_CARD_SLOT = 2
const DEFAULT_DRAW_SPEED = 0.1
const RETURN_TO_HAND_SPEED = 0.1
const CARD_BOTTOM_OFFSET = 144.0
const HOVER_PREVIEW_SCENE = preload("res://cards/scenes/card_2_scale.tscn")
const DECK_VIEW_CARD_META = "deck_view_card"

var card_drag
var screen_size
var card_is_hovered
var player_hand_ref
var hover_preview
var hovered_card


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_viewport_rect().size
	player_hand_ref = $"../PlayerHand"
	$"../InputManager".connect("left_mouse_button_released", on_left_click_release)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var deck_ref = $"../Deck"
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
	card_drag = card
	set_hovered_card(null)
	card_drag.set_visuals_visible(true)
	hide_hover_preview()
	_set_card_collision_disabled(card_drag, true)
	card_drag.z_index = 3


func finish_drag():
	var card_slot_found = raycast_check_for_card_slot()
	if card_slot_found and not card_slot_found.card_in_slot:
		player_hand_ref.remove_card_from_hand(card_drag)
		card_drag.position = card_slot_found.position
		_set_card_collision_disabled(card_drag, true)
		card_drag.z_index = 1
		card_slot_found.card_in_slot = true
	else:
		set_hovered_card(null)
		card_drag.set_visuals_visible(true)
		hide_hover_preview()
		_set_card_collision_disabled(card_drag, false)
		card_drag.z_index = 1
		player_hand_ref.add_card_to_hand(card_drag, RETURN_TO_HAND_SPEED)
	card_drag = null


func connect_card_signals(card):
	card.connect("hovered", on_hover_card)
	card.connect("hovered_off", on_hover_off_card)


func on_left_click_release():
	if card_drag:
		finish_drag()


func on_hover_card(card):
	if card_drag:
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


func _set_card_collision_disabled(card: Node2D, disabled: bool) -> void:
	if card == null:
		return

	var collision: CollisionShape2D = card.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = disabled


func raycast_check_for_card_slot():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISON_MASK_CARD_SLOT
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
		var deck_ref = $"../Deck"
		var deck_view_open: bool = deck_ref and deck_ref.has_method("is_deck_view_open") and deck_ref.is_deck_view_open()
		var filtered_cards: Array = []
		for hit in result:
			var card = hit.collider.get_parent()
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
