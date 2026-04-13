extends RefCounted


static func choose_card(current_enemy_data: Dictionary, card_definitions: Dictionary, opponent_current_mana: int, opponent_health: int, opponent_block: int) -> String:
	var enemy_draw_weights: Dictionary = current_enemy_data.get("deck_weights", {})
	if enemy_draw_weights.is_empty():
		return ""

	var defensive_spell_id := str(current_enemy_data.get("defensive_spell_id", "mana_shield"))
	if opponent_health <= 8 and opponent_block == 0 and enemy_draw_weights.has(defensive_spell_id):
		return defensive_spell_id

	var affordable_spells: Array[String] = []
	for card_id: String in enemy_draw_weights.keys():
		var card_data: Dictionary = card_definitions.get(card_id, {})
		if str(card_data.get("category", "")).to_lower() != "spell":
			continue
		if int(card_data.get("cost", 0)) <= opponent_current_mana:
			affordable_spells.append(card_id)

	if affordable_spells.is_empty():
		return ""

	var healing_spell_id := _choose_healing_spell(affordable_spells, card_definitions, opponent_health, current_enemy_data)
	if not healing_spell_id.is_empty():
		return healing_spell_id

	var weighted_total := 0.0
	for card_id in affordable_spells:
		weighted_total += float(enemy_draw_weights.get(card_id, 0.0))

	var roll := randf() * maxf(weighted_total, 0.001)
	var running := 0.0
	for card_id in affordable_spells:
		running += float(enemy_draw_weights.get(card_id, 0.0))
		if roll <= running:
			return card_id

	return affordable_spells[0]


static func _choose_healing_spell(affordable_spells: Array[String], card_definitions: Dictionary, opponent_health: int, current_enemy_data: Dictionary) -> String:
	var max_health := int(current_enemy_data.get("max_health", 0))
	if max_health <= 0:
		return ""

	var missing_health := max_health - opponent_health
	if missing_health <= 0:
		return ""

	var best_healing_card_id := ""
	var best_heal_amount := 0
	for card_id in affordable_spells:
		var card_data: Dictionary = card_definitions.get(card_id, {})
		var heal_amount := int(card_data.get("heal", 0))
		if heal_amount <= 0:
			continue
		if heal_amount > best_heal_amount:
			best_heal_amount = heal_amount
			best_healing_card_id = card_id

	if best_healing_card_id.is_empty():
		return ""

	if missing_health >= best_heal_amount or float(opponent_health) / float(max_health) <= 0.55:
		return best_healing_card_id

	return ""
