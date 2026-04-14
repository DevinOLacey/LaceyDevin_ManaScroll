extends Node2D

const CARD_SCENE = preload("res://cards/scenes/card.tscn")
const DeckCardDatabase = preload("res://cards/data/card_database.gd")
const DECK_VIEW_SCENE = preload("res://deck/scenes/deck_view.tscn")
const DeckConstants = preload("res://shared/constants/deck_constants.gd")

var card_definitions := DeckCardDatabase.get_card_definitions()
var card_draw_weights := DeckCardDatabase.get_card_draw_weights()

var player_hand_ref
var deck_view_ref: Node2D
var deck_view_backdrop_ref: ColorRect
var deck_view_layer_ref: CanvasLayer
var card_draw_modifier: Callable
var deck_view_card_ids_provider: Callable
var deck_view_card_data_provider: Callable

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	player_hand_ref = get_node_or_null("../PlayerHand")
	_create_deck_view()
	call_deferred("draw_starting_hand")


func draw_card():
	var player_hand := _get_player_hand_ref()
	if player_hand and player_hand.has_method("is_hand_full") and player_hand.is_hand_full():
		return

	var new_card: Node2D = _draw_card_instance()
	if new_card == null:
		return

	if player_hand and player_hand.has_method("add_card_to_hand"):
		player_hand.add_card_to_hand(new_card, DeckConstants.DRAW_SPEED)
	else:
		push_error("PlayerHand is missing add_card_to_hand(). Check the PlayerHand scene script path.")


func draw_up_to_max_hand_size() -> void:
	var player_hand := _get_player_hand_ref()
	if player_hand == null:
		return

	var current_hand_size := 0
	if player_hand.has_method("get_hand_size"):
		current_hand_size = player_hand.get_hand_size()

	var max_hand_size := DeckConstants.DEFAULT_HAND_SIZE
	if player_hand.has_method("get_max_hand_size"):
		max_hand_size = player_hand.get_max_hand_size()

	var cards_needed := maxi(0, max_hand_size - current_hand_size)
	var drawn_cards: Array[Node2D] = []
	for i in range(cards_needed):
		var new_card: Node2D = _draw_card_instance()
		if new_card == null:
			break
		drawn_cards.append(new_card)

	if drawn_cards.is_empty():
		return

	if player_hand.has_method("add_cards_to_hand"):
		player_hand.add_cards_to_hand(drawn_cards, DeckConstants.DRAW_SPEED)
	else:
		for card in drawn_cards:
			if player_hand.has_method("add_card_to_hand"):
				player_hand.add_card_to_hand(card, DeckConstants.DRAW_SPEED)


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
	var player_hand := _get_player_hand_ref()
	if player_hand == null:
		return

	var starting_cards: Array[Node2D] = []
	var cards_to_draw: int = DeckConstants.DEFAULT_HAND_SIZE
	if player_hand.has_method("get_max_hand_size"):
		cards_to_draw = player_hand.get_max_hand_size()
	else:
		push_error("PlayerHand is missing get_max_hand_size(). Using default hand size.")

	for i in range(cards_to_draw):
		var new_card: Node2D = _draw_card_instance()
		if new_card != null:
			starting_cards.append(new_card)

	if starting_cards.is_empty():
		return

	if player_hand.has_method("populate_starting_hand"):
		player_hand.populate_starting_hand(starting_cards)
	else:
		push_error("PlayerHand is missing populate_starting_hand(). Check the PlayerHand scene script path.")


func set_card_draw_modifier(modifier: Callable) -> void:
	card_draw_modifier = modifier


func set_deck_view_card_ids_provider(provider: Callable) -> void:
	deck_view_card_ids_provider = provider


func set_deck_view_card_data_provider(provider: Callable) -> void:
	deck_view_card_data_provider = provider


func _draw_card_instance() -> Node2D:
	var card_drawn: String = _roll_weighted_card()
	if card_drawn.is_empty():
		return null

	var card_definition: Dictionary = card_definitions.get(card_drawn, {})
	if card_definition.is_empty():
		push_error("Unknown card definition: %s" % card_drawn)
		return null

	if card_draw_modifier.is_valid():
		var modified_result = card_draw_modifier.call(card_drawn, card_definition.duplicate(true))
		if modified_result is Dictionary and not modified_result.is_empty():
			card_drawn = str(modified_result.get("card_id", card_drawn))
			card_definition = modified_result.get("card_data", card_definition)

	var new_card: Node2D = CARD_SCENE.instantiate()
	$"../../../CardManager".add_child(new_card)
	new_card.name = card_drawn
	new_card.visible = false
	var collision: CollisionShape2D = new_card.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true
	if new_card.has_method("apply_card_data"):
		new_card.apply_card_data(card_drawn, card_definition)
	return new_card


func _create_deck_view() -> void:
	deck_view_layer_ref = CanvasLayer.new()
	deck_view_layer_ref.name = "DeckViewLayer"
	deck_view_layer_ref.layer = DeckConstants.DECK_VIEW_CANVAS_LAYER

	deck_view_backdrop_ref = ColorRect.new()
	deck_view_backdrop_ref.name = "DeckViewBackdrop"
	deck_view_backdrop_ref.color = DeckConstants.DECK_VIEW_BACKDROP_COLOR
	deck_view_backdrop_ref.mouse_filter = Control.MOUSE_FILTER_IGNORE
	deck_view_backdrop_ref.visible = false

	deck_view_ref = DECK_VIEW_SCENE.instantiate()
	deck_view_ref.visible = false
	if deck_view_ref.has_method("configure"):
		deck_view_ref.configure(card_definitions, card_draw_weights, deck_view_backdrop_ref)
	if deck_view_ref and deck_view_ref.has_method("set_card_data_provider"):
		deck_view_ref.set_card_data_provider(Callable(self, "_get_deck_view_card_data"))
	get_parent().call_deferred("add_child", deck_view_layer_ref)
	deck_view_layer_ref.call_deferred("add_child", deck_view_backdrop_ref)
	deck_view_layer_ref.call_deferred("add_child", deck_view_ref)


func _show_deck_view() -> void:
	if deck_view_ref == null:
		return

	var unique_cards: Array[String] = _get_weighted_card_ids()
	if deck_view_card_ids_provider.is_valid():
		var provided_card_ids = deck_view_card_ids_provider.call(unique_cards.duplicate())
		if provided_card_ids is Array:
			unique_cards = []
			for card_id in provided_card_ids:
				unique_cards.append(str(card_id))
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


func _get_player_hand_ref() -> Node:
	if player_hand_ref == null or not is_instance_valid(player_hand_ref):
		player_hand_ref = get_node_or_null("../PlayerHand")
	return player_hand_ref


func _get_deck_view_card_data(card_id: String, base_card_data: Dictionary) -> Dictionary:
	if deck_view_card_data_provider.is_valid():
		var provided_card_data = deck_view_card_data_provider.call(card_id, base_card_data.duplicate(true))
		if provided_card_data is Dictionary and not provided_card_data.is_empty():
			return provided_card_data
	return base_card_data.duplicate(true)
