extends Node2D

const DRAW_SPEED = 0.2
const CARD_SCENE = preload("res://cards/scenes/card.tscn")
const CardDatabase = preload("res://cards/data/card_database.gd")
const DECK_VIEW_SCENE = preload("res://deck/scenes/deck_view.tscn")
const DECK_VIEW_BACKDROP_COLOR = Color(0.02, 0.03, 0.06, 0.72)
const DECK_VIEW_CANVAS_LAYER = 10

var card_definitions := CardDatabase.get_card_definitions()
var card_draw_weights := CardDatabase.get_card_draw_weights()

var player_hand_ref
var deck_view_ref: Node2D
var deck_view_backdrop_ref: ColorRect
var deck_view_layer_ref: CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	player_hand_ref = $"../PlayerHand"
	_create_deck_view()
	call_deferred("draw_starting_hand")


func draw_card():
	if player_hand_ref and player_hand_ref.is_hand_full():
		return

	var new_card: Node2D = _draw_card_instance()
	if new_card == null:
		return

	player_hand_ref.add_card_to_hand(new_card, DRAW_SPEED)


func toggle_deck_view() -> void:
	if deck_view_ref == null:
		return

	var is_open: bool = deck_view_ref.visible
	if is_open:
		if deck_view_ref.has_method("hide_view"):
			deck_view_ref.hide_view()
	else:
		_show_deck_view()


func is_deck_view_open() -> bool:
	return deck_view_ref != null and deck_view_ref.visible


func draw_starting_hand() -> void:
	if player_hand_ref == null:
		return

	var starting_cards: Array[Node2D] = []
	var cards_to_draw: int = player_hand_ref.get_max_hand_size()

	for i in range(cards_to_draw):
		var new_card: Node2D = _draw_card_instance()
		if new_card != null:
			starting_cards.append(new_card)

	if starting_cards.is_empty():
		return

	player_hand_ref.populate_starting_hand(starting_cards)


func _draw_card_instance() -> Node2D:
	var card_drawn: String = _roll_weighted_card()
	if card_drawn.is_empty():
		return null

	var card_definition: Dictionary = card_definitions.get(card_drawn, {})
	if card_definition.is_empty():
		push_error("Unknown card definition: %s" % card_drawn)
		return null

	var new_card: Node2D = CARD_SCENE.instantiate()
	$"../CardManager".add_child(new_card)
	new_card.name = card_drawn
	if new_card.has_method("apply_card_data"):
		new_card.apply_card_data(card_drawn, card_definition)
	return new_card


func _create_deck_view() -> void:
	deck_view_layer_ref = CanvasLayer.new()
	deck_view_layer_ref.name = "DeckViewLayer"
	deck_view_layer_ref.layer = DECK_VIEW_CANVAS_LAYER

	deck_view_backdrop_ref = ColorRect.new()
	deck_view_backdrop_ref.name = "DeckViewBackdrop"
	deck_view_backdrop_ref.color = DECK_VIEW_BACKDROP_COLOR
	deck_view_backdrop_ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_view_backdrop_ref.visible = false

	deck_view_ref = DECK_VIEW_SCENE.instantiate()
	deck_view_ref.visible = false
	if deck_view_ref.has_method("configure"):
		deck_view_ref.configure(card_definitions, card_draw_weights, deck_view_backdrop_ref)
	get_parent().call_deferred("add_child", deck_view_layer_ref)
	deck_view_layer_ref.call_deferred("add_child", deck_view_backdrop_ref)
	deck_view_layer_ref.call_deferred("add_child", deck_view_ref)


func _show_deck_view() -> void:
	if deck_view_ref == null:
		return

	var unique_cards: Array[String] = _get_weighted_card_ids()
	if deck_view_ref.has_method("show_cards"):
		deck_view_ref.show_cards(unique_cards)


func _get_weighted_card_ids() -> Array[String]:
	var weighted_card_ids: Array[String] = []
	for card_id: String in card_draw_weights.keys():
		if float(card_draw_weights[card_id]) > 0.0:
			weighted_card_ids.append(card_id)
	return weighted_card_ids


func _roll_weighted_card() -> String:
	var total_weight: float = 0.0
	for weight_value in card_draw_weights.values():
		total_weight += float(weight_value)

	if total_weight <= 0.0:
		return ""

	var roll: float = randf() * total_weight
	var running_weight: float = 0.0
	for card_id: String in card_draw_weights.keys():
		running_weight += float(card_draw_weights[card_id])
		if roll <= running_weight:
			return card_id

	var fallback_card_ids = card_draw_weights.keys()
	return str(fallback_card_ids[0])
