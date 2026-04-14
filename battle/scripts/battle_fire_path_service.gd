extends RefCounted

const CardArtDatabaseResource = preload("res://cards/data/card_art_database.gd")
const BattleConstants = preload("res://shared/constants/battle_constants.gd")


static func build_player_cast_resolution(card_id: String, base_card_data: Dictionary, flame_charge: int, ember_charge: int, fire_path_unlocked: bool) -> Dictionary:
	var result := {
		"card_data": base_card_data.duplicate(true),
		"flame_charge": flame_charge,
		"ember_charge": ember_charge,
		"burn_to_target": 0,
		"grant_ember_guard": false,
		"flame_bolt_primed": false,
		"ember_shield_primed": false,
	}

	if not fire_path_unlocked:
		return result

	var is_fused := bool(base_card_data.has("fused_components"))

	match card_id:
		"mana_bolt":
			if str(base_card_data.get("name", "")) == "Flame Bolt":
				result["burn_to_target"] = 1
			else:
				result["flame_charge"] = flame_charge + 1
				if int(result.get("flame_charge", 0)) >= BattleConstants.FIRE_FLAME_THRESHOLD:
					result["flame_charge"] = 0
					result["flame_bolt_primed"] = true
		"mana_shield":
			if str(base_card_data.get("name", "")) == "Ember Shield":
				result["grant_ember_guard"] = true
			else:
				result["ember_charge"] = ember_charge + 1
				if int(result.get("ember_charge", 0)) >= BattleConstants.FIRE_EMBER_THRESHOLD:
					result["ember_charge"] = 0
					result["ember_shield_primed"] = true

	if is_fused:
		result["card_data"] = base_card_data.duplicate(true)

	return result


static func modify_drawn_card(card_id: String, base_card_data: Dictionary, fire_path_unlocked: bool, flame_bolt_primed: bool, ember_shield_primed: bool) -> Dictionary:
	var result := {
		"card_data": base_card_data.duplicate(true),
		"consume_flame_bolt_primed": false,
		"consume_ember_shield_primed": false,
	}

	if not fire_path_unlocked:
		return result

	result["card_data"] = append_path_gain_text(card_id, base_card_data.duplicate(true))

	if bool(base_card_data.has("fused_components")):
		return result

	if card_id == "mana_bolt" and flame_bolt_primed:
		result["card_data"] = _build_flame_bolt_data(base_card_data)
		result["consume_flame_bolt_primed"] = true
	elif card_id == "mana_shield" and ember_shield_primed:
		result["card_data"] = _build_ember_shield_data(base_card_data)
		result["consume_ember_shield_primed"] = true

	return result


static func apply_burn(current_stacks: int, current_turns_remaining: int, amount: int) -> Dictionary:
	if amount <= 0:
		return {
			"stacks": current_stacks,
			"turns_remaining": current_turns_remaining,
		}

	return {
		"stacks": current_stacks + amount,
		"turns_remaining": BattleConstants.FIRE_BURN_DURATION,
	}


static func tick_burn(current_health: int, current_stacks: int, current_turns_remaining: int) -> Dictionary:
	if current_stacks <= 0 or current_turns_remaining <= 0:
		return {
			"health": current_health,
			"damage": 0,
			"stacks": 0,
			"turns_remaining": 0,
		}

	var damage := current_stacks
	var next_health := maxi(0, current_health - damage)
	var next_turns := current_turns_remaining - 1
	var next_stacks := current_stacks
	if next_turns <= 0:
		next_turns = 0
		next_stacks = 0

	return {
		"health": next_health,
		"damage": damage,
		"stacks": next_stacks,
		"turns_remaining": next_turns,
	}


static func _build_flame_bolt_data(base_card_data: Dictionary) -> Dictionary:
	var card_data := base_card_data.duplicate(true)
	card_data["name"] = "Flame Bolt"
	card_data["cost"] = 1
	card_data["damage"] = 5
	card_data["description"] = "Loose a blazing bolt dealing [i][b]5[/b] damage[/i] and inflicting [i][b]1 Burn[/b][/i]"
	card_data["fusion_match_id"] = "flame_bolt"
	return CardArtDatabaseResource.apply_variant_art(card_data, "flame_bolt")


static func _build_ember_shield_data(base_card_data: Dictionary) -> Dictionary:
	var card_data := base_card_data.duplicate(true)
	card_data["name"] = "Ember Shield"
	card_data["cost"] = 1
	card_data["block"] = int(base_card_data.get("block", 0)) + 1
	card_data["description"] = "Wrap yourself in embers [i]blocking [b]3[/b][/i] and gain Ember Guard while you still have block"
	card_data["fusion_match_id"] = "ember_shield"
	return CardArtDatabaseResource.apply_variant_art(card_data, "ember_shield")


static func append_path_gain_text(card_id: String, card_data: Dictionary) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	var description := str(updated_card_data.get("description", ""))

	if description.contains("Gain 1 Flame") or description.contains("Gain 1 Ember"):
		return updated_card_data

	match card_id:
		"mana_bolt":
			updated_card_data["description"] = "%s\n[i]Gain 1 Flame[/i]" % description
		"mana_shield":
			updated_card_data["description"] = "%s\n[i]Gain 1 Ember[/i]" % description

	return updated_card_data
