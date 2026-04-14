extends RefCounted

const CombatCardDatabase = preload("res://cards/data/card_database.gd")
const BattleEnergyPathService = preload("res://battle/scripts/battle_energy_path_service.gd")
const BattleFirePathService = preload("res://battle/scripts/battle_fire_path_service.gd")
const BattleFrostPathService = preload("res://battle/scripts/battle_frost_path_service.gd")
const BattleConstants = preload("res://shared/constants/battle_constants.gd")


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
	if has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
		runtime_state["path_states"][BattleConstants.PATH_OF_FLAME] = _build_default_fire_state()
	if has_path(runtime_state, BattleConstants.PATH_OF_ENERGY):
		runtime_state["path_states"][BattleConstants.PATH_OF_ENERGY] = BattleEnergyPathService.build_default_state()
	if has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		runtime_state["path_states"][BattleConstants.PATH_OF_FROST] = BattleFrostPathService.build_default_state()


static func build_player_cast_resolution(runtime_state: Dictionary, card_id: String, card_data: Dictionary) -> Dictionary:
	var result := {
		"card_data": card_data.duplicate(true),
		"extra_messages": [],
		"burn_to_target": 0,
		"grant_spell_actions": 0,
		"refresh_hand_cards": false,
	}

	if has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
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

	if has_path(runtime_state, BattleConstants.PATH_OF_ENERGY):
		var energy_state := _get_energy_state(runtime_state)
		var energy_resolution := BattleEnergyPathService.build_player_cast_resolution(
			card_id,
			result.get("card_data", card_data),
			energy_state,
			true
		)
		result["card_data"] = energy_resolution.get("card_data", result.get("card_data", card_data))
		result["grant_spell_actions"] = int(energy_resolution.get("grant_spell_actions", 0))
		result["refresh_hand_cards"] = bool(energy_resolution.get("refresh_hand_cards", false))
		energy_state["charge_stacks"] = int(energy_resolution.get("charge_stacks", energy_state.get("charge_stacks", 0)))
		energy_state["shock_stacks"] = int(energy_resolution.get("shock_stacks", energy_state.get("shock_stacks", 0)))
		energy_state["queued_draw_card_ids"] = energy_resolution.get("queued_draw_card_ids", energy_state.get("queued_draw_card_ids", [])).duplicate()
		energy_state["unstable_discharge_bonus"] = int(energy_resolution.get("unstable_discharge_bonus", energy_state.get("unstable_discharge_bonus", 0)))
		_store_energy_state(runtime_state, energy_state)
		var extra_messages: Array = result.get("extra_messages", [])
		var energy_messages = energy_resolution.get("extra_messages", [])
		if energy_messages is Array:
			for message in energy_messages:
				if not str(message).is_empty():
					extra_messages.append(str(message))
		result["extra_messages"] = extra_messages

	if has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		var frost_state := _get_frost_state(runtime_state)
		var frost_resolution := BattleFrostPathService.build_player_cast_resolution(
			card_id,
			result.get("card_data", card_data),
			frost_state,
			true
		)
		result["card_data"] = frost_resolution.get("card_data", result.get("card_data", card_data))
		frost_state["frost_stacks"] = int(frost_resolution.get("frost_stacks", frost_state.get("frost_stacks", 0)))
		frost_state["chill_stacks"] = int(frost_resolution.get("chill_stacks", frost_state.get("chill_stacks", 0)))
		frost_state["ice_bolt_primed"] = bool(frost_resolution.get("ice_bolt_primed", frost_state.get("ice_bolt_primed", false)))
		frost_state["frost_armor_primed"] = bool(frost_resolution.get("frost_armor_primed", frost_state.get("frost_armor_primed", false)))
		frost_state["frost_armor_charges"] = int(frost_resolution.get("frost_armor_charges", frost_state.get("frost_armor_charges", 0)))
		_store_frost_state(runtime_state, frost_state)
		var extra_messages: Array = result.get("extra_messages", [])
		var frost_messages = frost_resolution.get("extra_messages", [])
		if frost_messages is Array:
			for message in frost_messages:
				if not str(message).is_empty():
					extra_messages.append(str(message))
		result["extra_messages"] = extra_messages

	return result


static func modify_drawn_card(runtime_state: Dictionary, card_id: String, base_card_data: Dictionary) -> Dictionary:
	var result := {
		"card_id": card_id,
		"card_data": base_card_data.duplicate(true),
	}

	if has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
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

	if has_path(runtime_state, BattleConstants.PATH_OF_ENERGY):
		var energy_state := _get_energy_state(runtime_state)
		var card_definitions := CombatCardDatabase.get_card_definitions()
		var modified_result := BattleEnergyPathService.modify_drawn_card(
			str(result.get("card_id", card_id)),
			result.get("card_data", base_card_data),
			energy_state,
			card_definitions,
			true
		)
		energy_state["queued_draw_card_ids"] = modified_result.get("queued_draw_card_ids", energy_state.get("queued_draw_card_ids", [])).duplicate()
		_store_energy_state(runtime_state, energy_state)
		result["card_id"] = str(modified_result.get("card_id", result.get("card_id", card_id)))
		result["card_data"] = modified_result.get("card_data", result.get("card_data", base_card_data))

	if has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		var frost_state := _get_frost_state(runtime_state)
		var modified_result := BattleFrostPathService.modify_drawn_card(
			str(result.get("card_id", card_id)),
			result.get("card_data", base_card_data),
			true,
			bool(frost_state.get("ice_bolt_primed", false)),
			bool(frost_state.get("frost_armor_primed", false))
		)
		if bool(modified_result.get("consume_ice_bolt_primed", false)):
			frost_state["ice_bolt_primed"] = false
		if bool(modified_result.get("consume_frost_armor_primed", false)):
			frost_state["frost_armor_primed"] = false
		_store_frost_state(runtime_state, frost_state)
		result["card_data"] = modified_result.get("card_data", result.get("card_data", base_card_data))

	return result


static func decorate_card_data(runtime_state: Dictionary, card_id: String, card_data: Dictionary) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	if has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
		updated_card_data = BattleFirePathService.append_path_gain_text(card_id, updated_card_data)
	if has_path(runtime_state, BattleConstants.PATH_OF_ENERGY):
		var energy_state := _get_energy_state(runtime_state)
		updated_card_data = BattleEnergyPathService.decorate_card_data(
			card_id,
			updated_card_data,
			int(energy_state.get("unstable_discharge_bonus", 0)),
			true
		)
	if has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		updated_card_data = BattleFrostPathService.append_path_gain_text(card_id, updated_card_data)
	return updated_card_data


static func get_class_mechanics_text(runtime_state: Dictionary) -> String:
	var mechanic_sections: Array[String] = []
	if has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
		var fire_state := _get_fire_state(runtime_state)
		var flame_status := "Flame %d/%d" % [int(fire_state.get("flame_charge", 0)), BattleConstants.FIRE_FLAME_THRESHOLD]
		if bool(fire_state.get("flame_bolt_primed", false)):
			flame_status = "Flame Bolt primed"

		var ember_status := "Ember %d/%d" % [int(fire_state.get("ember_charge", 0)), BattleConstants.FIRE_EMBER_THRESHOLD]
		if bool(fire_state.get("ember_shield_primed", false)):
			ember_status = "Ember Shield primed"

		var guard_status := "Ember Guard active" if bool(fire_state.get("ember_guard_active", false)) else "Ember Guard inactive"
		mechanic_sections.append("Path of Flame\n%s | %s | %s" % [flame_status, ember_status, guard_status])

	if has_path(runtime_state, BattleConstants.PATH_OF_ENERGY):
		var energy_state := _get_energy_state(runtime_state)
		mechanic_sections.append(BattleEnergyPathService.get_mechanics_text(energy_state))
	if has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		var frost_state := _get_frost_state(runtime_state)
		mechanic_sections.append(BattleFrostPathService.get_mechanics_text(frost_state))

	return "\n\n".join(mechanic_sections)


static func get_deck_view_card_ids(runtime_state: Dictionary, base_card_ids: Array[String]) -> Array[String]:
	var deck_view_card_ids: Array[String] = base_card_ids.duplicate()
	if has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
		_append_unique_card_ids(deck_view_card_ids, BattleConstants.FLAME_DECK_VIEW_CARD_IDS)
	if has_path(runtime_state, BattleConstants.PATH_OF_ENERGY):
		_append_unique_card_ids(deck_view_card_ids, BattleConstants.ENERGY_DECK_VIEW_CARD_IDS)
	if has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		_append_unique_card_ids(deck_view_card_ids, BattleConstants.FROST_DECK_VIEW_CARD_IDS)
	return deck_view_card_ids


static func apply_enemy_burn(current_stacks: int, current_turns_remaining: int, amount: int) -> Dictionary:
	return BattleFirePathService.apply_burn(current_stacks, current_turns_remaining, amount)


static func tick_enemy_burn(current_health: int, current_stacks: int, current_turns_remaining: int) -> Dictionary:
	return BattleFirePathService.tick_burn(current_health, current_stacks, current_turns_remaining)


static func is_ember_guard_active(runtime_state: Dictionary) -> bool:
	if not has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
		return false
	return bool(_get_fire_state(runtime_state).get("ember_guard_active", false))


static func set_ember_guard_active(runtime_state: Dictionary, active: bool) -> void:
	if not has_path(runtime_state, BattleConstants.PATH_OF_FLAME):
		return
	var fire_state := _get_fire_state(runtime_state)
	fire_state["ember_guard_active"] = active
	_store_fire_state(runtime_state, fire_state)


static func get_frost_armor_charges(runtime_state: Dictionary) -> int:
	if not has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		return 0
	return int(_get_frost_state(runtime_state).get("frost_armor_charges", 0))


static func set_frost_armor_charges(runtime_state: Dictionary, charges: int) -> void:
	if not has_path(runtime_state, BattleConstants.PATH_OF_FROST):
		return
	var frost_state := _get_frost_state(runtime_state)
	frost_state["frost_armor_charges"] = maxi(0, charges)
	_store_frost_state(runtime_state, frost_state)


static func _get_fire_state(runtime_state: Dictionary) -> Dictionary:
	var path_states = runtime_state.get("path_states", {})
	var fire_state: Dictionary = path_states.get(BattleConstants.PATH_OF_FLAME, _build_default_fire_state()).duplicate(true)
	return fire_state


static func _store_fire_state(runtime_state: Dictionary, fire_state: Dictionary) -> void:
	var path_states = runtime_state.get("path_states", {})
	path_states[BattleConstants.PATH_OF_FLAME] = fire_state.duplicate(true)
	runtime_state["path_states"] = path_states


static func _get_energy_state(runtime_state: Dictionary) -> Dictionary:
	var path_states = runtime_state.get("path_states", {})
	var energy_state: Dictionary = path_states.get(BattleConstants.PATH_OF_ENERGY, BattleEnergyPathService.build_default_state()).duplicate(true)
	return energy_state


static func _store_energy_state(runtime_state: Dictionary, energy_state: Dictionary) -> void:
	var path_states = runtime_state.get("path_states", {})
	path_states[BattleConstants.PATH_OF_ENERGY] = energy_state.duplicate(true)
	runtime_state["path_states"] = path_states


static func _get_frost_state(runtime_state: Dictionary) -> Dictionary:
	var path_states = runtime_state.get("path_states", {})
	var frost_state: Dictionary = path_states.get(BattleConstants.PATH_OF_FROST, BattleFrostPathService.build_default_state()).duplicate(true)
	return frost_state


static func _store_frost_state(runtime_state: Dictionary, frost_state: Dictionary) -> void:
	var path_states = runtime_state.get("path_states", {})
	path_states[BattleConstants.PATH_OF_FROST] = frost_state.duplicate(true)
	runtime_state["path_states"] = path_states


static func _build_default_fire_state() -> Dictionary:
	return {
		"flame_charge": 0,
		"ember_charge": 0,
		"flame_bolt_primed": false,
		"ember_shield_primed": false,
		"ember_guard_active": false,
	}


static func _append_unique_card_ids(target_card_ids: Array, additional_card_ids: Array) -> void:
	for card_id in additional_card_ids:
		var normalized_card_id := str(card_id)
		if not target_card_ids.has(normalized_card_id):
			target_card_ids.append(normalized_card_id)
