extends RefCounted


static func is_valid_player_target(card_data: Dictionary, target: Node2D, player_target: Node2D, enemy_target: Node2D) -> bool:
	if target == null:
		return false

	match str(card_data.get("target_group", "")).to_lower():
		"enemy":
			return target == enemy_target
		"ally", "self":
			return target == player_target
		_:
			return false


static func get_invalid_target_message(card_data: Dictionary) -> String:
	match str(card_data.get("target_group", "")).to_lower():
		"enemy":
			return "That spell must target an enemy."
		"ally", "self":
			return "That spell must target yourself or an ally."
		_:
			return "That target is not valid for this card."


static func get_default_target_for_opponent(card_data: Dictionary, player_target: Node2D, enemy_target: Node2D) -> Node2D:
	match str(card_data.get("target_group", "")).to_lower():
		"enemy":
			return player_target
		"ally", "self":
			return enemy_target
		_:
			return enemy_target


static func get_target_key(target: Node2D, player_target: Node2D) -> String:
	if target == player_target:
		return "player"
	return "opponent"


static func get_target_display_name(target: Node2D, player_target: Node2D, enemy_target: Node2D, enemy_name: String) -> String:
	if target == player_target:
		return "Player"
	if target == enemy_target:
		return enemy_name
	return "Target"
