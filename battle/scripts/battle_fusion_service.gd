extends RefCounted


static func can_open_fuse_selection(hand_cards: Array) -> bool:
	var spell_counts := {}
	for hand_card in hand_cards:
		if hand_card == null or not is_instance_valid(hand_card):
			continue
		var card_data: Dictionary = hand_card.get_meta("card_data", {})
		if str(card_data.get("category", "")).to_lower() != "spell":
			continue
		var card_id := str(hand_card.get_meta("card_id", ""))
		spell_counts[card_id] = int(spell_counts.get(card_id, 0)) + 1
		if int(spell_counts[card_id]) >= 2:
			return true

	return false


static func combine_selected_cards(selected_cards: Array, discard_card: Callable, update_hand_position: Callable) -> Node2D:
	if selected_cards.is_empty():
		return null

	var primary_card: Node2D = selected_cards[0]
	if primary_card == null or not is_instance_valid(primary_card):
		return null

	var combined_data := _build_combined_card_data(selected_cards, primary_card)
	if combined_data.is_empty():
		return null

	if primary_card.has_method("apply_card_data"):
		primary_card.apply_card_data(str(primary_card.get_meta("card_id", "")), combined_data)

	for i in range(1, selected_cards.size()):
		var extra_card: Node2D = selected_cards[i]
		if extra_card == null or not is_instance_valid(extra_card):
			continue
		discard_card.call(extra_card)

	update_hand_position.call()
	return primary_card


static func get_selected_card_snapshots(selected_cards: Array) -> Array[Dictionary]:
	var selected_snapshots: Array[Dictionary] = []
	for selected_card in selected_cards:
		if selected_card == null or not is_instance_valid(selected_card):
			continue
		selected_snapshots.append({
			"card_id": str(selected_card.get_meta("card_id", "")),
			"card_data": selected_card.get_meta("card_data", {}).duplicate(true),
		})
	return selected_snapshots


static func _build_combined_card_data(selected_cards: Array, primary_card: Node2D) -> Dictionary:
	var combined_data: Dictionary = primary_card.get_meta("card_data", {}).duplicate(true)
	if combined_data.is_empty():
		return {}

	var combined_cost := 0
	var combined_damage := 0
	var combined_block := 0
	var fused_components: Array[String] = []
	for selected_card in selected_cards:
		if selected_card == null or not is_instance_valid(selected_card):
			continue
		var selected_data: Dictionary = selected_card.get_meta("card_data", {})
		combined_cost += int(selected_data.get("cost", 0))
		combined_damage += int(selected_data.get("damage", 0))
		combined_block += int(selected_data.get("block", 0))
		fused_components.append(str(selected_data.get("name", selected_card.name)))

	combined_data["cost"] = combined_cost
	if combined_damage > 0:
		combined_data["damage"] = combined_damage
	if combined_block > 0:
		combined_data["block"] = combined_block
	combined_data["fused_components"] = fused_components

	var base_name := str(combined_data.get("name", primary_card.name))
	if base_name.begins_with("Fused "):
		base_name = base_name.trim_prefix("Fused ")
	combined_data["name"] = "Fused %s" % base_name
	combined_data["description"] = _build_fused_description(combined_data)
	return combined_data


static func _build_fused_description(card_data: Dictionary) -> String:
	var description := str(card_data.get("description", ""))
	var replacement_value := 0
	if int(card_data.get("damage", 0)) > 0:
		replacement_value = int(card_data.get("damage", 0))
	elif int(card_data.get("block", 0)) > 0:
		replacement_value = int(card_data.get("block", 0))
	elif int(card_data.get("heal", 0)) > 0:
		replacement_value = int(card_data.get("heal", 0))

	if description.is_empty() or replacement_value <= 0:
		return description

	var regex := RegEx.new()
	regex.compile("\\d+")
	var match := regex.search(description)
	if match == null:
		return description

	return description.substr(0, match.get_start()) + str(replacement_value) + description.substr(match.get_end())
