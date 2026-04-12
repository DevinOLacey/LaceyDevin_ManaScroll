extends RefCounted

const CHARGE_THRESHOLD := 10
const SHOCK_THRESHOLD := 2
const ACCELERATE_MANA_GATES_CARD_ID := "accelerate_mana_gates"
const UNSTABLE_DISCHARGE_CARD_ID := "unstable_discharge"


static func build_player_cast_resolution(card_id: String, base_card_data: Dictionary, energy_state: Dictionary, energy_path_unlocked: bool) -> Dictionary:
	var result := {
		"card_data": base_card_data.duplicate(true),
		"charge_stacks": int(energy_state.get("charge_stacks", 0)),
		"shock_stacks": int(energy_state.get("shock_stacks", 0)),
		"queued_draw_card_ids": energy_state.get("queued_draw_card_ids", []).duplicate(),
		"unstable_discharge_bonus": int(energy_state.get("unstable_discharge_bonus", 0)),
		"grant_spell_actions": 0,
		"refresh_hand_cards": false,
		"extra_messages": [],
	}

	if not energy_path_unlocked:
		return result

	match card_id:
		"mana_shield":
			result["charge_stacks"] = int(result.get("charge_stacks", 0)) + 1
			if int(result.get("charge_stacks", 0)) >= CHARGE_THRESHOLD:
				result["charge_stacks"] = 0
				var queued_draws: Array = result.get("queued_draw_card_ids", [])
				queued_draws.append(ACCELERATE_MANA_GATES_CARD_ID)
				result["queued_draw_card_ids"] = queued_draws
				var charge_messages: Array = result.get("extra_messages", [])
				charge_messages.append("Charge surges. Accelerate Mana Gates is guaranteed on a future draw.")
				result["extra_messages"] = charge_messages
		"mana_bolt":
			result["shock_stacks"] = int(result.get("shock_stacks", 0)) + 1
			if int(result.get("shock_stacks", 0)) >= SHOCK_THRESHOLD:
				result["shock_stacks"] = 0
				var queued_draws: Array = result.get("queued_draw_card_ids", [])
				queued_draws.append(UNSTABLE_DISCHARGE_CARD_ID)
				result["queued_draw_card_ids"] = queued_draws
				var shock_messages: Array = result.get("extra_messages", [])
				shock_messages.append("Shock peaks. Unstable Discharge is guaranteed on a future draw.")
				result["extra_messages"] = shock_messages
		ACCELERATE_MANA_GATES_CARD_ID:
			result["grant_spell_actions"] = 1
			result["refresh_hand_cards"] = true
		UNSTABLE_DISCHARGE_CARD_ID:
			result["unstable_discharge_bonus"] = int(result.get("unstable_discharge_bonus", 0)) + 1
			result["refresh_hand_cards"] = true
			var discharge_messages: Array = result.get("extra_messages", [])
			discharge_messages.append("Your Mana Bolts and Mana Shields grow stronger.")
			result["extra_messages"] = discharge_messages

	result["card_data"] = _apply_unstable_discharge_bonus(card_id, base_card_data, int(result.get("unstable_discharge_bonus", 0)))
	return result


static func modify_drawn_card(card_id: String, base_card_data: Dictionary, energy_state: Dictionary, card_definitions: Dictionary, energy_path_unlocked: bool) -> Dictionary:
	var result := {
		"card_id": card_id,
		"card_data": _decorate_card_data(card_id, base_card_data, int(energy_state.get("unstable_discharge_bonus", 0)), energy_path_unlocked),
		"queued_draw_card_ids": energy_state.get("queued_draw_card_ids", []).duplicate(),
	}

	if not energy_path_unlocked:
		return result

	var queued_draws: Array = energy_state.get("queued_draw_card_ids", []).duplicate()
	if queued_draws.is_empty():
		return result

	var queued_card_id := str(queued_draws.pop_front())
	var queued_card_data: Dictionary = card_definitions.get(queued_card_id, {}).duplicate(true)
	if queued_card_data.is_empty():
		return result

	result["card_id"] = queued_card_id
	result["card_data"] = _decorate_card_data(queued_card_id, queued_card_data, int(energy_state.get("unstable_discharge_bonus", 0)), energy_path_unlocked)
	result["queued_draw_card_ids"] = queued_draws
	return result


static func append_path_gain_text(card_id: String, card_data: Dictionary) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	var description := str(updated_card_data.get("description", ""))

	if description.contains("Gain 1 Charge") or description.contains("Gain 1 Shock"):
		return updated_card_data

	match card_id:
		"mana_shield":
			updated_card_data["description"] = "%s\n[i]Gain 1 Charge[/i]" % description
		"mana_bolt":
			updated_card_data["description"] = "%s\n[i]Gain 1 Shock[/i]" % description

	return updated_card_data


static func decorate_card_data(card_id: String, card_data: Dictionary, unstable_discharge_bonus: int, energy_path_unlocked: bool) -> Dictionary:
	if not energy_path_unlocked:
		return card_data.duplicate(true)
	return _decorate_card_data(card_id, card_data, unstable_discharge_bonus, true)


static func get_mechanics_text(energy_state: Dictionary) -> String:
	return "Path of Energy\nCharge %d/%d | Shock %d/%d | Discharge +%d" % [
		int(energy_state.get("charge_stacks", 0)),
		CHARGE_THRESHOLD,
		int(energy_state.get("shock_stacks", 0)),
		SHOCK_THRESHOLD,
		int(energy_state.get("unstable_discharge_bonus", 0)),
	]


static func build_default_state() -> Dictionary:
	return {
		"charge_stacks": 0,
		"shock_stacks": 0,
		"queued_draw_card_ids": [],
		"unstable_discharge_bonus": 0,
	}


static func _decorate_card_data(card_id: String, card_data: Dictionary, unstable_discharge_bonus: int, include_path_text: bool) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	if include_path_text:
		updated_card_data = append_path_gain_text(card_id, updated_card_data)
	return _apply_unstable_discharge_bonus(card_id, updated_card_data, unstable_discharge_bonus)


static func _apply_unstable_discharge_bonus(card_id: String, card_data: Dictionary, unstable_discharge_bonus: int) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	var previously_applied_bonus := int(updated_card_data.get("energy_bonus_applied", 0))

	match card_id:
		"mana_bolt":
			var base_damage := int(updated_card_data.get("damage", 0)) - previously_applied_bonus
			updated_card_data["damage"] = max(base_damage, 0) + unstable_discharge_bonus
			updated_card_data["description"] = _replace_first_number(str(updated_card_data.get("description", "")), int(updated_card_data.get("damage", 0)))
		"mana_shield":
			var base_block := int(updated_card_data.get("block", 0)) - previously_applied_bonus
			updated_card_data["block"] = max(base_block, 0) + unstable_discharge_bonus
			updated_card_data["description"] = _replace_first_number(str(updated_card_data.get("description", "")), int(updated_card_data.get("block", 0)))

	updated_card_data["energy_bonus_applied"] = unstable_discharge_bonus
	return updated_card_data


static func _replace_first_number(text: String, replacement_value: int) -> String:
	if text.is_empty():
		return text

	var regex := RegEx.new()
	regex.compile("\\d+")
	var match := regex.search(text)
	if match == null:
		return text

	return text.substr(0, match.get_start()) + str(replacement_value) + text.substr(match.get_end())
