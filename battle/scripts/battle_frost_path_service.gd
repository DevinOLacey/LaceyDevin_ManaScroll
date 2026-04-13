extends RefCounted

const CardArtDatabaseResource = preload("res://cards/data/card_art_database.gd")

const FROST_THRESHOLD := 2
const CHILL_THRESHOLD := 3


static func build_player_cast_resolution(card_id: String, base_card_data: Dictionary, frost_state: Dictionary, frost_path_unlocked: bool) -> Dictionary:
	var result := {
		"card_data": base_card_data.duplicate(true),
		"frost_stacks": int(frost_state.get("frost_stacks", 0)),
		"chill_stacks": int(frost_state.get("chill_stacks", 0)),
		"ice_bolt_primed": bool(frost_state.get("ice_bolt_primed", false)),
		"frost_armor_primed": bool(frost_state.get("frost_armor_primed", false)),
		"frost_armor_charges": int(frost_state.get("frost_armor_charges", 0)),
		"extra_messages": [],
	}

	if not frost_path_unlocked:
		return result

	match card_id:
		"mana_bolt":
			if str(base_card_data.get("name", "")) == "Ice Bolt":
				pass
			else:
				result["frost_stacks"] = int(result.get("frost_stacks", 0)) + 1
				if int(result.get("frost_stacks", 0)) >= FROST_THRESHOLD:
					result["frost_stacks"] = 0
					result["ice_bolt_primed"] = true
					var frost_messages: Array = result.get("extra_messages", [])
					frost_messages.append("Frost peaks. Your next Mana Bolt becomes Ice Bolt.")
					result["extra_messages"] = frost_messages
		"mana_shield":
			if str(base_card_data.get("name", "")) == "Frost Armor":
				result["frost_armor_charges"] = int(result.get("frost_armor_charges", 0)) + 1
				var armor_messages: Array = result.get("extra_messages", [])
				armor_messages.append("Frost Armor gains 1 charge.")
				result["extra_messages"] = armor_messages
			else:
				result["chill_stacks"] = int(result.get("chill_stacks", 0)) + 1
				if int(result.get("chill_stacks", 0)) >= CHILL_THRESHOLD:
					result["chill_stacks"] = 0
					result["frost_armor_primed"] = true
					var chill_messages: Array = result.get("extra_messages", [])
					chill_messages.append("Chill deepens. Your next Mana Shield becomes Frost Armor.")
					result["extra_messages"] = chill_messages

	return result


static func modify_drawn_card(card_id: String, base_card_data: Dictionary, frost_path_unlocked: bool, ice_bolt_primed: bool, frost_armor_primed: bool) -> Dictionary:
	var result := {
		"card_data": base_card_data.duplicate(true),
		"consume_ice_bolt_primed": false,
		"consume_frost_armor_primed": false,
	}

	if not frost_path_unlocked:
		return result

	result["card_data"] = append_path_gain_text(card_id, base_card_data.duplicate(true))

	if bool(base_card_data.has("fused_components")):
		return result

	if card_id == "mana_bolt" and ice_bolt_primed:
		result["card_data"] = _build_ice_bolt_data(base_card_data)
		result["consume_ice_bolt_primed"] = true
	elif card_id == "mana_shield" and frost_armor_primed:
		result["card_data"] = _build_frost_armor_data(base_card_data)
		result["consume_frost_armor_primed"] = true

	return result


static func append_path_gain_text(card_id: String, card_data: Dictionary) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	var description := str(updated_card_data.get("description", ""))

	if description.contains("Gain 1 Frost") or description.contains("Gain 1 Chill"):
		return updated_card_data

	match card_id:
		"mana_bolt":
			updated_card_data["description"] = "%s\n[i]Gain 1 Frost[/i]" % description
		"mana_shield":
			updated_card_data["description"] = "%s\n[i]Gain 1 Chill[/i]" % description

	return updated_card_data


static func get_mechanics_text(frost_state: Dictionary) -> String:
	var frost_status := "Frost %d/%d" % [
		int(frost_state.get("frost_stacks", 0)),
		FROST_THRESHOLD,
	]
	if bool(frost_state.get("ice_bolt_primed", false)):
		frost_status = "Ice Bolt primed"

	var chill_status := "Chill %d/%d" % [
		int(frost_state.get("chill_stacks", 0)),
		CHILL_THRESHOLD,
	]
	if bool(frost_state.get("frost_armor_primed", false)):
		chill_status = "Frost Armor primed"

	var armor_charges := int(frost_state.get("frost_armor_charges", 0))
	var armor_status := "Frost Armor inactive"
	if armor_charges > 0:
		armor_status = "Frost Armor %d charge%s" % [armor_charges, "" if armor_charges == 1 else "s"]

	return "Path of Frost\n%s | %s | %s" % [frost_status, chill_status, armor_status]


static func build_default_state() -> Dictionary:
	return {
		"frost_stacks": 0,
		"chill_stacks": 0,
		"ice_bolt_primed": false,
		"frost_armor_primed": false,
		"frost_armor_charges": 0,
	}


static func _build_ice_bolt_data(base_card_data: Dictionary) -> Dictionary:
	var card_data := base_card_data.duplicate(true)
	card_data["name"] = "Ice Bolt"
	card_data["cost"] = 1
	card_data["damage"] = 6
	card_data["effect"] = "ice_bolt"
	card_data["description"] = "Hurl a razor shard of frost that [i][b]shatters block[/b][/i] and then deals [i][b]6[/b] damage[/i]"
	card_data["fusion_match_id"] = "ice_bolt"
	return CardArtDatabaseResource.apply_variant_art(card_data, "ice_bolt")


static func _build_frost_armor_data(base_card_data: Dictionary) -> Dictionary:
	var card_data := base_card_data.duplicate(true)
	card_data["name"] = "Frost Armor"
	card_data["cost"] = 1
	card_data.erase("block")
	card_data["effect"] = "frost_armor"
	card_data["description"] = "Wrap yourself in frozen wards and gain [i][b]1 Frost Armor[/b][/i]. Each charge reflects the next attack"
	card_data["fusion_match_id"] = "frost_armor"
	return CardArtDatabaseResource.apply_variant_art(card_data, "frost_armor")
