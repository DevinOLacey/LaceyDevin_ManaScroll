extends RefCounted


static func resolve_spell_effect(card_data: Dictionary, caster: String, target_key: String, target_name: String, multiplier: int, combat_state: Dictionary, enemy_name: String) -> Dictionary:
	var result := {
		"player_health": int(combat_state.get("player_health", 0)),
		"opponent_health": int(combat_state.get("opponent_health", 0)),
		"player_block": int(combat_state.get("player_block", 0)),
		"opponent_block": int(combat_state.get("opponent_block", 0)),
		"player_ember_guard_active": bool(combat_state.get("player_ember_guard_active", false)),
		"damage_done": 0,
		"block_done": 0,
		"heal_done": 0,
		"ember_burn_to_attacker": 0,
		"log_message": "",
	}

	var card_name := str(card_data.get("name", "Spell"))
	var total_damage := int(card_data.get("damage", 0)) * multiplier
	var total_block := int(card_data.get("block", 0)) * multiplier
	var total_heal := int(card_data.get("heal", 0)) * multiplier

	if total_damage > 0:
		var damage_resolution := _deal_damage_to_target(target_key, total_damage, result, caster)
		var damage_dealt := int(damage_resolution.get("health_damage", 0))
		result["damage_done"] = damage_dealt
		result["ember_burn_to_attacker"] = int(damage_resolution.get("ember_burn_to_attacker", 0))
		if caster == "player":
			result["log_message"] = "%s dealt %d damage to %s." % [card_name, damage_dealt, target_name]
		else:
			result["log_message"] = "%s cast %s on %s for %d damage." % [enemy_name, card_name, target_name, damage_dealt]
	elif total_block > 0:
		_add_block_to_target(target_key, total_block, result)
		result["block_done"] = total_block
		if caster == "player":
			result["log_message"] = "%s gave %s %d block." % [card_name, target_name, total_block]
		else:
			result["log_message"] = "%s gave %s %d block with %s." % [enemy_name, target_name, total_block, card_name]
	elif total_heal > 0:
		var healed_amount := _heal_target(target_key, total_heal, result, combat_state)
		result["heal_done"] = healed_amount
		if caster == "player":
			result["log_message"] = "%s healed %s for %d." % [card_name, target_name, healed_amount]
		else:
			result["log_message"] = "%s healed %s for %d with %s." % [enemy_name, target_name, healed_amount, card_name]

	return result


static func apply_status_damage(target_key: String, amount: int, combat_state: Dictionary) -> Dictionary:
	var result := {
		"player_health": int(combat_state.get("player_health", 0)),
		"opponent_health": int(combat_state.get("opponent_health", 0)),
		"player_block": int(combat_state.get("player_block", 0)),
		"opponent_block": int(combat_state.get("opponent_block", 0)),
		"player_ember_guard_active": bool(combat_state.get("player_ember_guard_active", false)),
		"health_damage": 0,
		"ember_burn_to_attacker": 0,
	}
	var damage_resolution := _deal_damage_to_target(target_key, amount, result, "status")
	result["health_damage"] = int(damage_resolution.get("health_damage", 0))
	result["ember_burn_to_attacker"] = int(damage_resolution.get("ember_burn_to_attacker", 0))
	return result


static func _deal_damage_to_target(target_key: String, amount: int, state: Dictionary, caster: String) -> Dictionary:
	var starting_block := _get_block_value(target_key, state)
	var ember_guard_active := target_key == "player" and bool(state.get("player_ember_guard_active", false))
	var block_loss_multiplier := 2 if ember_guard_active and starting_block > 0 else 1
	var blocked_damage := mini(amount, int(floor(float(starting_block) / float(block_loss_multiplier))))
	var block_spent := blocked_damage * block_loss_multiplier
	_set_block_value(target_key, maxi(0, starting_block - block_spent), state)

	var ember_burn_to_attacker := 0
	if ember_guard_active and starting_block > 0 and caster == "opponent":
		ember_burn_to_attacker = 1

	var health_damage := amount - blocked_damage
	_set_health_value(target_key, maxi(0, _get_health_value(target_key, state) - health_damage), state)

	if ember_guard_active and _get_block_value(target_key, state) <= 0:
		state["player_ember_guard_active"] = false

	return {
		"health_damage": health_damage,
		"ember_burn_to_attacker": ember_burn_to_attacker,
	}


static func _add_block_to_target(target_key: String, amount: int, state: Dictionary) -> void:
	_set_block_value(target_key, _get_block_value(target_key, state) + amount, state)


static func _heal_target(target_key: String, amount: int, state: Dictionary, combat_state: Dictionary) -> int:
	var max_health := _get_max_health_value(target_key, combat_state)
	var current_health := _get_health_value(target_key, state)
	var healed_amount := mini(amount, max_health - current_health)
	_set_health_value(target_key, current_health + healed_amount, state)
	return healed_amount


static func _get_health_value(target_key: String, state: Dictionary) -> int:
	if target_key == "player":
		return int(state.get("player_health", 0))
	return int(state.get("opponent_health", 0))


static func _get_max_health_value(target_key: String, state: Dictionary) -> int:
	if target_key == "player":
		return int(state.get("player_max_health", 0))
	return int(state.get("opponent_max_health", 0))


static func _set_health_value(target_key: String, value: int, state: Dictionary) -> void:
	if target_key == "player":
		state["player_health"] = value
	else:
		state["opponent_health"] = value


static func _get_block_value(target_key: String, state: Dictionary) -> int:
	if target_key == "player":
		return int(state.get("player_block", 0))
	return int(state.get("opponent_block", 0))


static func _set_block_value(target_key: String, value: int, state: Dictionary) -> void:
	if target_key == "player":
		state["player_block"] = value
	else:
		state["opponent_block"] = value
