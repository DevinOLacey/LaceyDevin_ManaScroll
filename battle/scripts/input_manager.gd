extends Node2D

signal left_mouse_button_clicked
signal left_mouse_button_released
signal right_mouse_button_clicked

const COLLISON_MASK_CARD = 1
const COLLISON_MASK_CARD_DECK = 4
const DECK_VIEW_CARD_META = "deck_view_card"

var card_manager_ref
var deck_ref

func _ready() -> void:
	card_manager_ref = $"../CardManager"
	deck_ref = $"../PlayerSide/PlayerDecks/Deck"


func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.is_pressed():
				emit_signal("left_mouse_button_clicked")
				raycast_at_cursor("left")
			else:
				emit_signal("left_mouse_button_released")
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed():
			emit_signal("right_mouse_button_clicked")
			raycast_at_cursor("right")


func raycast_at_cursor(mouse_button: String):
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISON_MASK_CARD:
			var card_found = result[0].collider.get_parent()
			if card_found and not (card_found.has_meta(DECK_VIEW_CARD_META) and card_found.get_meta(DECK_VIEW_CARD_META)):
				if mouse_button == "left":
					card_manager_ref.start_drag(card_found)
				elif mouse_button == "right" and card_manager_ref.has_method("discard_card"):
					card_manager_ref.discard_card(card_found)
		elif result_collision_mask == COLLISON_MASK_CARD_DECK:
			deck_ref.toggle_deck_view()
