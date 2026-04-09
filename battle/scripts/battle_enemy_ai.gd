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
