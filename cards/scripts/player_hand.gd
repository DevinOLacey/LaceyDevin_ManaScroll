extends Node2D

const MAX_HAND_SIZE = 7
const CARD_WIDTH = 200
const HAND_Y_POSITION = 890
const DEFAULT_DRAW_SPEED = 0.1
const MANIFEST_DRAW_SPEED = 1
const STARTING_HAND_BASE_DELAY = 0.08
const STARTING_HAND_DELAY_VARIANCE = 0.07
const DRAW_STAGGER_DELAY = 0.08

var player_hand = []
var center_screen_x

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	center_screen_x = get_viewport().size.x / 2
	
	#var card_scene = preload(CARD_SCENE_PATH)
	#for i in range(HAND_COUNT):
		#var new_card = card_scene.instantiate()
		#$"../CardManager".add_child(new_card)
		#new_card.name = "card"
		#add_card_to_hand(new_card)


func add_card_to_hand(card, speed):
	if card not in player_hand:
		player_hand.insert(0, card)
		update_hand_position(speed, card)
	else:
		animate_card_to_position(card, card.hand_position, speed, true)


func add_cards_to_hand(cards: Array[Node2D], speed: float, manifest_new_cards: bool = true) -> void:
	var added_cards: Array[Node2D] = []
	for card in cards:
		if card in player_hand:
			continue
		player_hand.insert(0, card)
		added_cards.append(card)

	if added_cards.is_empty():
		return

	for i in range(player_hand.size()):
		var hand_card = player_hand[i]
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		hand_card.hand_position = new_position
		if hand_card not in added_cards or not manifest_new_cards:
			animate_card_to_position(hand_card, new_position, speed)

	if manifest_new_cards:
		_manifest_added_cards_staggered(added_cards)
	else:
		for hand_card in added_cards:
			animate_card_to_position(hand_card, hand_card.hand_position, speed)


func get_max_hand_size() -> int:
	return MAX_HAND_SIZE


func get_hand_size() -> int:
	return player_hand.size()


func get_cards() -> Array:
	return player_hand.duplicate()


func is_hand_full() -> bool:
	return player_hand.size() >= MAX_HAND_SIZE


func populate_starting_hand(cards: Array[Node2D]) -> void:
	for card in cards:
		if card in player_hand:
			continue
		player_hand.append(card)
		card.visible = false
		var collision: CollisionShape2D = card.get_node_or_null("Area2D/CollisionShape2D")
		if collision:
			collision.disabled = true

	update_hand_targets()
	await _manifest_starting_hand(cards)


func update_hand_position(speed, manifested_card = null):
	for i in range(player_hand.size()):
		var new_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)
		var card = player_hand[i]
		card.hand_position = new_position
		if card == manifested_card and card.has_method("manifest_to_position"):
			card.visible = true
			card.manifest_to_position(new_position, MANIFEST_DRAW_SPEED)
		else:
			animate_card_to_position(card, new_position, speed)


func update_hand_targets() -> void:
	for i in range(player_hand.size()):
		var card = player_hand[i]
		card.hand_position = Vector2(calculate_card_position(i), HAND_Y_POSITION)


func layout_cards_at_row(cards: Array, row_y: float, speed: float = DEFAULT_DRAW_SPEED) -> void:
	for i in range(cards.size()):
		var card: Node2D = cards[i]
		var new_position = Vector2(calculate_card_position_for_count(i, cards.size()), row_y)
		card.hand_position = new_position
		animate_card_to_position(card, new_position, speed)


func calculate_card_position(index):
	return calculate_card_position_for_count(index, player_hand.size())


func calculate_card_position_for_count(index: int, total_cards: int) -> float:
	var total_width = (total_cards - 1) * CARD_WIDTH
	var x_offset = center_screen_x + index * CARD_WIDTH - total_width / 2.0
	return x_offset


func animate_card_to_position(card, target_position, speed, restore_collision_on_finish: bool = false):
	if card and card.has_method("stop_motion_tweens"):
		card.stop_motion_tweens(true)

	var collision: CollisionShape2D = card.get_node_or_null("Area2D/CollisionShape2D")
	if restore_collision_on_finish and collision:
		collision.disabled = true

	var tween = get_tree().create_tween()
	tween.tween_property(card, "position", target_position, speed)
	if restore_collision_on_finish:
		tween.tween_callback(func():
			if collision:
				collision.disabled = false
		)


func remove_card_from_hand(card):
	if card in player_hand:
		player_hand.erase(card)
		update_hand_position(DEFAULT_DRAW_SPEED)


func has_card(card: Node2D) -> bool:
	return card in player_hand


func find_matching_card_by_id(card_id: String, excluded_card: Node2D = null) -> Node2D:
	for card in player_hand:
		if card == excluded_card:
			continue
		if str(card.get_meta("card_id", "")) == card_id:
			return card
	return null


func _manifest_starting_hand(cards: Array[Node2D]) -> void:
	var manifest_queue: Array[Node2D] = cards.duplicate()
	manifest_queue.shuffle()

	for card in manifest_queue:
		if not is_instance_valid(card):
			continue

		card.visible = true
		if card.has_method("manifest_to_position"):
			card.manifest_to_position(card.hand_position, MANIFEST_DRAW_SPEED)
		else:
			animate_card_to_position(card, card.hand_position, MANIFEST_DRAW_SPEED)

		var delay: float = STARTING_HAND_BASE_DELAY + randf_range(0.0, STARTING_HAND_DELAY_VARIANCE)
		await get_tree().create_timer(delay).timeout


func _manifest_added_cards_staggered(cards: Array[Node2D]) -> void:
	for card in cards:
		if not is_instance_valid(card):
			continue

		card.visible = true
		if card.has_method("manifest_to_position"):
			card.manifest_to_position(card.hand_position, MANIFEST_DRAW_SPEED)
		else:
			animate_card_to_position(card, card.hand_position, MANIFEST_DRAW_SPEED)

		if card != cards.back():
			await get_tree().create_timer(DRAW_STAGGER_DELAY).timeout
