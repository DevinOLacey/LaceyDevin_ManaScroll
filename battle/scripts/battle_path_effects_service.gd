extends RefCounted

const BattleFirePathService = preload("res://battle/scripts/battle_fire_path_service.gd")

const PATH_OF_FLAME := "path_of_flame"


static func create_runtime_state() -> Dictionary:
	return {
		"active_path_ids": [],
		"path_states": {},
	}


static func unlock_path(runtime_state: Dictionary, path_id: String) -> void:
	var active_path_ids: Array = runtime_state.get("active_path_ids", [])
	if not active_path_ids.has(path_id):
		active_path_ids.append(path_id)
	runtime_state["active_path_ids"] = active_path_ids


static func has_path(runtime_state: Dictionary, path_id: String) -> bool:
	var active_path_ids: Array = runtime_state.get("active_path_ids", [])
	return active_path_ids.has(path_id)


static func reset_for_new_stage(runtime_state: Dictionary) -> void:
	if has_path(runtime_state, PATH_OF_FLAME):
		runtime_state["path_states"][PATH_OF_FLAME] = _build_default_fire_state()


static func build_player_cast_resolution(runtime_state: Dictionary, card_id: String, card_data: Dictionary) -> Dictionary:
	var result := {
		"card_data": card_data.duplicate(true),
		"extra_messages": [],
		"burn_to_target": 0,
	}

	if has_path(runtime_state, PATH_OF_FLAME):
		var fire_state := _get_fire_state(runtime_state)
		var fire_resolution := BattleFirePathService.build_player_cast_resolution(
			card_id,
			card_data,
			int(fire_state.get("flame_charge", 0)),
			int(fire_state.get("ember_charge", 0)),
			true
		)
		result["card_data"] = fire_resolution.get("card_data", card_data)
		result["burn_to_target"] = int(fire_resolution.get("burn_to_target", 0))
		fire_state["flame_charge"] = int(fire_resolution.get("flame_charge", fire_state.get("flame_charge", 0)))
		fire_state["ember_charge"] = int(fire_resolution.get("ember_charge", fire_state.get("ember_charge", 0)))
		fire_state["flame_bolt_primed"] = bool(fire_resolution.get("flame_bolt_primed", false)) or bool(fire_state.get("flame_bolt_primed", false))
		fire_state["ember_shield_primed"] = bool(fire_resolution.get("ember_shield_primed", false)) or bool(fire_state.get("ember_shield_primed", false))
		if bool(fire_resolution.get("grant_ember_guard", false)):
			fire_state["ember_guard_active"] = true
			var extra_messages: Array = result.get("extra_messages", [])
			extra_messages.append("Ember Shield ignites your guard.")
			result["extra_messages"] = extra_messages
		_store_fire_state(runtime_state, fire_state)

	return result


static func modify_drawn_card(runtime_state: Dictionary, card_id: String, base_card_data: Dictionary) -> Dictionary:
	var result := {
		"card_data": base_card_data.duplicate(true),
	}

	if has_path(runtime_state, PATH_OF_FLAME):
		var fire_state := _get_fire_state(runtime_state)
		var modified_result := BattleFirePathService.modify_drawn_card(
			card_id,
			base_card_data,
			true,
			bool(fire_state.get("flame_bolt_primed", false)),
			bool(fire_state.get("ember_shield_primed", false))
		)
		if bool(modified_result.get("consume_flame_bolt_primed", false)):
			fire_state["flame_bolt_primed"] = false
		if bool(modified_result.get("consume_ember_shield_primed", false)):
			fire_state["ember_shield_primed"] = false
		_store_fire_state(runtime_state, fire_state)
		result = modified_result

	return result


static func decorate_card_data(runtime_state: Dictionary, card_id: String, card_data: Dictionary) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	if has_path(runtime_state, PATH_OF_FLAME):
		updated_card_data = BattleFirePathService.append_path_gain_text(card_id, updated_card_data)
	return updated_card_data


static func get_class_mechanics_text(runtime_state: Dictionary) -> String:
	if has_path(runtime_state, PATH_OF_FLAME):
		var fire_state := _get_fire_state(runtime_state)
		var flame_status := "Flame %d/%d" % [int(fire_state.get("flame_charge", 0)), BattleFirePathService.FLAME_THRESHOLD]
		if bool(fire_state.get("flame_bolt_primed", false)):
			flame_status = "Flame Bolt primed"

		var ember_status := "Ember %d/%d" % [int(fire_state.get("ember_charge", 0)), BattleFirePathService.EMBER_THRESHOLD]
		if bool(fire_state.get("ember_shield_primed", false)):
			ember_status = "Ember Shield primed"

		var guard_status := "Ember Guard active" if bool(fire_state.get("ember_guard_active", false)) else "Ember Guard inactive"
		return "Path of Flame\n%s | %s | %s" % [flame_status, ember_status, guard_status]

	return ""


static func apply_enemy_burn(current_stacks: int, current_turns_remaining: int, amount: int) -> Dictionary:
	return BattleFirePathService.apply_burn(current_stacks, current_turns_remaining, amount)


static func tick_enemy_burn(current_health: int, current_stacks: int, current_turns_remaining: int) -> Dictionary:
	return BattleFirePathService.tick_burn(current_health, current_stacks, current_turns_remaining)


static func is_ember_guard_active(runtime_state: Dictionary) -> bool:
	if not has_path(runtime_state, PATH_OF_FLAME):
		return false
	return bool(_get_fire_state(runtime_state).get("ember_guard_active", false))


static func set_ember_guard_active(runtime_state: Dictionary, active: bool) -> void:
	if not has_path(runtime_state, PATH_OF_FLAME):
		return
	var fire_state := _get_fire_state(runtime_state)
	fire_state["ember_guard_active"] = active
	_store_fire_state(runtime_state, fire_state)


static func _get_fire_state(runtime_state: Dictionary) -> Dictionary:
	var path_states = runtime_state.get("path_states", {})
	var fire_state: Dictionary = path_states.get(PATH_OF_FLAME, _build_default_fire_state()).duplicate(true)
	return fire_state


static func _store_fire_state(runtime_state: Dictionary, fire_state: Dictionary) -> void:
	var path_states = runtime_state.get("path_states", {})
	path_states[PATH_OF_FLAME] = fire_state.duplicate(true)
	runtime_state["path_states"] = path_states


static func _build_default_fire_state() -> Dictionary:
	return {
		"flame_charge": 0,
		"ember_charge": 0,
		"flame_bolt_primed": false,
		"ember_shield_primed": false,
		"ember_guard_active": false,
	}
