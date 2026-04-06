extends Node2D

const CombatCardDatabase = preload("res://cards/data/card_database.gd")
const SELECT_FROM_HAND_SCENE = preload("res://cards/scenes/select_from_hand.tscn")
const CARD_SCENE = preload("res://cards/scenes/card.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const DUMMY_SCENE = preload("res://scenes/dummy.tscn")

const STARTING_HEALTH := 20
const AI_ACTION_DELAY := 0.8

var battle_timer: Timer
var end_turn_button: TextureButton
var deck_ref: Node
var player_hand_ref: Node
var player_target: Node2D
var dummy_target: Node2D
var turn_label: Label
var mana_counter_label: RichTextLabel
var health_label: Label
var level_label: Label
var mana_regen_label: Label
var stage_label: Label
var player_status_label: Label
var enemy_status_label: Label
var battle_log_label: Label
var selection_scene_ref: Node2D
var combat_log_canvas_layer: CanvasLayer
var combat_log_entries_container: VBoxContainer
var combat_log_entries: Array[Dictionary] = []

var player_turn_number := 1
var opponent_turn_number := 0
var player_level := 1
var player_max_mana := 1
var player_current_mana := 1
var player_mana_regen := 1
var opponent_max_mana := 0
var opponent_current_mana := 0
var player_health := STARTING_HEALTH
var opponent_health := STARTING_HEALTH
var current_stage_number := 1
var player_block := 0
var opponent_block := 0
var player_spell_played := false
var pending_fuse_charges := 0
var active_side := "player"
var resolving_turn := false

var card_definitions := CombatCardDatabase.get_card_definitions()
var card_draw_weights := CombatCardDatabase.get_card_draw_weights()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = AI_ACTION_DELAY
	end_turn_button = $"../EndTurnButton"
	deck_ref = $"../PlayerSide/PlayerDecks/Deck"
	player_hand_ref = $"../PlayerSide/PlayerDecks/PlayerHand"
	turn_label = $"../TurnLabel"
	mana_counter_label = $"../Mana/ManaCount"
	health_label = $"../CanvasLayer/HUDBar/HUDMargin/HUDRow/HealthLabel"
	level_label = $"../CanvasLayer/HUDBar/HUDMargin/HUDRow/LevelLabel"
	mana_regen_label = $"../CanvasLayer/HUDBar/HUDMargin/HUDRow/ManaRegenLabel"
	stage_label = $"../CanvasLayer/HUDBar/HUDMargin/HUDRow/StageLabel"
	player_status_label = $"../PlayerStatusLabel"
	enemy_status_label = $"../OpponentStatusLabel"
	battle_log_label = $"../BattleLogLabel"
	combat_log_canvas_layer = $"../CombatLogCanvasLayer"
	combat_log_entries_container = $"../CombatLogCanvasLayer/CombatLogPanel/CombatLogMargin/CombatLogVBox/CombatLogScroll/CombatLogEntries"
	player_target = $"../PlayerSide/PlayerSprites/Player"
	dummy_target = $"../Enemies/EnemySprites/Dummy"
	_begin_player_turn(true)


func _on_end_turn_button_pressed() -> void:
	if active_side != "player" or resolving_turn:
		return
	_end_player_turn("You ended your turn.")


func _on_combat_log_button_pressed() -> void:
	_refresh_combat_log_overlay()
	if combat_log_canvas_layer:
		combat_log_canvas_layer.visible = true


func _on_close_combat_log_button_pressed() -> void:
	if combat_log_canvas_layer:
		combat_log_canvas_layer.visible = false


func can_player_interact() -> bool:
	return active_side == "player" and not resolving_turn and selection_scene_ref == null


func is_selection_active() -> bool:
	return selection_scene_ref != null


func try_play_card(card: Node2D, target: Node2D = null) -> bool:
	if not can_player_interact():
		_log_message("Wait for your turn.")
		_update_hud()
		return false
	if player_hand_ref == null or not player_hand_ref.has_method("has_card") or not player_hand_ref.has_card(card):
		return false

	var card_data: Dictionary = card.get_meta("card_data", {})
	if card_data.is_empty():
		return false

	var category: String = str(card_data.get("category", "")).to_lower()
	var card_name: String = str(card_data.get("name", card.name))
	var mana_cost: int = int(card_data.get("cost", 0))

	if category == "spell" and player_spell_played:
		_log_message("You can only cast 1 spell each turn.")
		_update_hud()
		return false

	if mana_cost > player_current_mana:
		_log_message("%s costs %d mana." % [card_name, mana_cost])
		_update_hud()
		return false

	if not _is_valid_player_target(card_data, target):
		_log_message(_get_invalid_target_message(card_data))
		_update_hud()
		return false

	match category:
		"enchantment":
			return _play_player_enchantment(card, card_data, mana_cost)
		"spell":
			return _play_player_spell(card, card_data, mana_cost, target)
		_:
			_log_message("That card type is not playable yet.")
			_update_hud()
			return false


func _play_player_enchantment(card: Node2D, card_data: Dictionary, mana_cost: int) -> bool:
	if str(card_data.get("effect", "")) == "combine" and not _can_open_fuse_selection():
		_log_message("Fuse Mana needs 2 matching spells in hand.")
		_update_hud()
		return false

	player_current_mana -= mana_cost
	_append_combat_log(card_data, "player", "Player", 0, 0)

	if str(card_data.get("effect", "")) == "combine":
		_log_message("Choose 2 matching spells to fuse.")
	else:
		_log_message("%s resolves." % str(card_data.get("name", card.name)))

	_discard_player_card(card)
	if str(card_data.get("effect", "")) == "combine":
		_open_select_from_hand({
			"selection_count": 2,
			"allowed_category": "spell",
			"require_matching_card_id": true,
		})
	_update_hud()
	return true


func _play_player_spell(card: Node2D, card_data: Dictionary, mana_cost: int, target: Node2D) -> bool:
	var total_cost := mana_cost
	var effect_multiplier := 1
	var card_name := str(card_data.get("name", card.name))

	if total_cost > player_current_mana:
		_log_message("You do not have enough mana for that spell.")
		_update_hud()
		return false

	player_current_mana -= total_cost
	player_spell_played = true
	_resolve_spell_effect(card_data, "player", target, effect_multiplier)

	_discard_player_card(card)

	if effect_multiplier > 1:
		_log_message("%s fused %d matching spell(s)." % [card_name, effect_multiplier - 1])
	pending_fuse_charges = 0
	_update_hud()
	return true


func _resolve_spell_effect(card_data: Dictionary, caster: String, target: Node2D, multiplier: int = 1) -> void:
	var card_name: String = str(card_data.get("name", "Spell"))
	var total_damage := int(card_data.get("damage", 0)) * multiplier
	var total_block := int(card_data.get("block", 0)) * multiplier
	var target_name := _get_target_display_name(target)

	if total_damage > 0:
		var damage_dealt := _deal_damage_to_target(target, total_damage)
		_append_combat_log(card_data, caster, target_name, damage_dealt, 0)
		if caster == "player":
			_log_message("%s dealt %d damage to %s." % [card_name, damage_dealt, target_name])
		else:
			_log_message("Opponent cast %s on %s for %d damage." % [card_name, target_name, damage_dealt])
	elif total_block > 0:
		_add_block_to_target(target, total_block)
		_append_combat_log(card_data, caster, target_name, 0, total_block)
		if caster == "player":
			_log_message("%s gave %s %d block." % [card_name, target_name, total_block])
		else:
			_log_message("Opponent gave %s %d block with %s." % [target_name, total_block, card_name])

	_update_hud()


func _deal_damage_to_target(target: Node2D, amount: int) -> int:
	var target_key := _get_target_key(target)
	var blocked := mini(amount, _get_block_value(target_key))
	_set_block_value(target_key, _get_block_value(target_key) - blocked)
	var health_damage := amount - blocked
	_set_health_value(target_key, maxi(0, _get_health_value(target_key) - health_damage))
	return health_damage


func _add_block_to_target(target: Node2D, amount: int) -> void:
	var target_key := _get_target_key(target)
	_set_block_value(target_key, _get_block_value(target_key) + amount)


func _end_player_turn(reason: String) -> void:
	if resolving_turn:
		return

	resolving_turn = true
	active_side = "opponent"
	pending_fuse_charges = 0
	_set_end_turn_enabled(false)
	_log_message(reason)
	_update_hud()
	call_deferred("_run_opponent_turn")


func _run_opponent_turn() -> void:
	battle_timer.start()
	await battle_timer.timeout

	if _is_battle_over():
		return

	_begin_opponent_turn()
	var opponent_card := _choose_opponent_card()
	if opponent_card.is_empty():
		_log_message("Opponent could not act.")
	else:
		var card_data: Dictionary = card_definitions.get(opponent_card, {})
		var mana_cost := int(card_data.get("cost", 0))
		if mana_cost <= opponent_current_mana:
			opponent_current_mana -= mana_cost
			_resolve_spell_effect(card_data, "opponent", _get_default_target_for_opponent(card_data))
		else:
			_log_message("Opponent passed.")

	_update_hud()

	battle_timer.start()
	await battle_timer.timeout

	if _is_battle_over():
		return

	_begin_player_turn(false)


func _begin_player_turn(is_first_turn: bool) -> void:
	resolving_turn = false
	active_side = "player"
	player_spell_played = false
	pending_fuse_charges = 0

	if is_first_turn:
		player_turn_number = 1
		player_current_mana = max(player_current_mana, 1)
	else:
		player_turn_number += 1
		player_current_mana += player_mana_regen
		if deck_ref and deck_ref.has_method("draw_up_to_max_hand_size"):
			deck_ref.draw_up_to_max_hand_size()

	player_max_mana = max(player_max_mana, player_current_mana)
	_set_end_turn_enabled(true)
	_log_message("Player turn %d. Mana refreshed." % player_turn_number)
	_update_hud()


func _begin_opponent_turn() -> void:
	active_side = "opponent"
	opponent_turn_number += 1
	opponent_current_mana += 1
	opponent_max_mana = max(opponent_max_mana, opponent_current_mana)
	_log_message("Opponent turn %d." % opponent_turn_number)
	_update_hud()


func _choose_opponent_card() -> String:
	if opponent_health <= 8 and opponent_block == 0:
		return "mana_shield"

	var affordable_spells: Array[String] = []
	for card_id: String in card_draw_weights.keys():
		var card_data: Dictionary = card_definitions.get(card_id, {})
		if str(card_data.get("category", "")).to_lower() != "spell":
			continue
		if int(card_data.get("cost", 0)) <= opponent_current_mana:
			affordable_spells.append(card_id)

	if affordable_spells.is_empty():
		return ""

	var weighted_total := 0.0
	for card_id in affordable_spells:
		weighted_total += float(card_draw_weights.get(card_id, 0.0))

	var roll := randf() * maxf(weighted_total, 0.001)
	var running := 0.0
	for card_id in affordable_spells:
		running += float(card_draw_weights.get(card_id, 0.0))
		if roll <= running:
			return card_id

	return affordable_spells[0]


func _discard_player_card(card: Node2D) -> void:
	if card == null or not is_instance_valid(card):
		return
	if player_hand_ref and player_hand_ref.has_method("remove_card_from_hand"):
		player_hand_ref.remove_card_from_hand(card)
	card.queue_free()


func discard_player_card_from_hand(card: Node2D) -> void:
	if not can_player_interact():
		return
	if card == null or not is_instance_valid(card):
		return
	if player_hand_ref == null or not player_hand_ref.has_method("has_card") or not player_hand_ref.has_card(card):
		return

	var card_name := str(card.get_meta("card_data", {}).get("name", card.name))
	_discard_player_card(card)
	_log_message("Discarded %s." % card_name)
	_update_hud()


func _set_end_turn_enabled(enabled: bool) -> void:
	if end_turn_button == null:
		return
	end_turn_button.disabled = not enabled
	end_turn_button.visible = true
	end_turn_button.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.55)


func _update_hud() -> void:
	if turn_label:
		var side_text := "Your turn"
		if active_side == "opponent":
			side_text = "Opponent turn"
		turn_label.text = "%s | Turn %d" % [side_text, player_turn_number]

	if mana_counter_label:
		mana_counter_label.clear()
		mana_counter_label.append_text("[center][b]%d[/b][/center]" % player_current_mana)

	if health_label:
		health_label.text = "Health: %d / %d" % [player_health, STARTING_HEALTH]

	if level_label:
		level_label.text = "Level: %d" % player_level

	if mana_regen_label:
		mana_regen_label.text = "Mana Regen: +%d / turn" % player_mana_regen

	if stage_label:
		stage_label.text = "Stage: %d" % current_stage_number

	if player_status_label:
		player_status_label.text = "Player HP: %d  Block: %d  Mana: %d/%d  Spell: %s  Fuse: %d" % [
			player_health,
			player_block,
			player_current_mana,
			player_max_mana,
			"Used" if player_spell_played else "Ready",
			pending_fuse_charges
		]

	if enemy_status_label:
		enemy_status_label.text = "Opponent HP: %d  Block: %d  Mana: %d/%d" % [
			opponent_health,
			opponent_block,
			opponent_current_mana,
			opponent_max_mana
		]


func _open_select_from_hand(action_config: Dictionary) -> void:
	if selection_scene_ref != null:
		selection_scene_ref.queue_free()

	var hand_cards: Array[Node2D] = []
	if player_hand_ref and player_hand_ref.has_method("get_cards"):
		hand_cards.assign(player_hand_ref.get_cards())

	selection_scene_ref = SELECT_FROM_HAND_SCENE.instantiate()
	get_parent().add_child(selection_scene_ref)
	selection_scene_ref.selection_confirmed.connect(_on_select_from_hand_confirmed)
	selection_scene_ref.configure(action_config, hand_cards, player_hand_ref)


func _on_select_from_hand_confirmed(selected_cards: Array) -> void:
	if selection_scene_ref:
		selection_scene_ref.queue_free()
		selection_scene_ref = null

	if selected_cards.size() >= 2:
		var fused_card := _combine_selected_cards(selected_cards)
		if fused_card:
			var card_name := str(fused_card.get_meta("card_data", {}).get("name", fused_card.name))
			_log_message("%s was fused into a stronger spell." % card_name)
	_update_hud()


func _log_message(message: String) -> void:
	if battle_log_label:
		battle_log_label.text = message


func _append_combat_log(card_data: Dictionary, caster: String, target_name: String, damage_done: int, block_done: int) -> void:
	combat_log_entries.append({
		"card_id": str(card_data.get("id", card_data.get("name", ""))).to_lower().replace(" ", "_"),
		"card_data": card_data.duplicate(true),
		"caster": caster,
		"target_name": target_name,
		"damage_done": damage_done,
		"block_done": block_done,
	})
	if combat_log_canvas_layer and combat_log_canvas_layer.visible:
		_refresh_combat_log_overlay()


func _refresh_combat_log_overlay() -> void:
	if combat_log_entries_container == null:
		return

	for child in combat_log_entries_container.get_children():
		child.queue_free()

	if combat_log_entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No spells have been played yet."
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.84, 0.9, 0.96, 1.0))
		combat_log_entries_container.add_child(empty_label)
		return

	for index in range(combat_log_entries.size() - 1, -1, -1):
		combat_log_entries_container.add_child(_build_combat_log_entry(combat_log_entries[index]))


func _build_combat_log_entry(entry: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 300)
	panel.add_theme_stylebox_override("panel", _build_combat_log_style(str(entry.get("caster", ""))))

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	panel.add_child(root)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 24)
	root.add_child(top_row)

	top_row.add_child(_build_actor_preview(str(entry.get("caster", ""))))
	top_row.add_child(_build_card_preview(entry))
	top_row.add_child(_build_actor_preview(_get_actor_key_for_target_name(str(entry.get("target_name", "")))))

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 6)
	root.add_child(details)

	var card_data: Dictionary = entry.get("card_data", {})

	var summary_label := Label.new()
	summary_label.text = "%s used %s on %s" % [
		"Player" if str(entry.get("caster", "")) == "player" else "Enemy",
		str(card_data.get("name", "Spell")),
		str(entry.get("target_name", "Target"))
	]
	summary_label.add_theme_font_size_override("font_size", 24)
	summary_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	details.add_child(summary_label)

	var result_label := Label.new()
	var damage_done := int(entry.get("damage_done", 0))
	var block_done := int(entry.get("block_done", 0))
	if damage_done > 0:
		result_label.text = "Damage Dealt: %d" % damage_done
	elif block_done > 0:
		result_label.text = "Block Granted: %d" % block_done
	else:
		result_label.text = "Effect resolved."
	result_label.add_theme_font_size_override("font_size", 18)
	result_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
	details.add_child(result_label)

	var stats_text: Array[String] = []
	if int(card_data.get("damage", 0)) > 0:
		stats_text.append("Base Damage: %d" % int(card_data.get("damage", 0)))
	if int(card_data.get("block", 0)) > 0:
		stats_text.append("Base Block: %d" % int(card_data.get("block", 0)))
	stats_text.append("Cost: %d" % int(card_data.get("cost", 0)))

	var stats_label := Label.new()
	stats_label.text = " | ".join(stats_text)
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.69, 0.77, 0.87, 1.0))
	details.add_child(stats_label)

	return panel


func _build_card_preview(entry: Dictionary) -> Control:
	var card_holder := Control.new()
	card_holder.custom_minimum_size = Vector2(180, 200)

	var card_instance: Node2D = CARD_SCENE.instantiate()
	card_instance.position = Vector2(90, 108)
	card_instance.scale = Vector2(0.8, 0.8)
	card_holder.add_child(card_instance)
	if card_instance.has_method("apply_card_data"):
		card_instance.apply_card_data(str(entry.get("card_id", "")), entry.get("card_data", {}))
	if card_instance.has_method("set_visuals_visible"):
		card_instance.set_visuals_visible(true)
	card_instance.set("registers_hover_signals", false)
	var collision: CollisionShape2D = card_instance.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true

	return card_holder


func _build_actor_preview(actor_key: String) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(160, 180)

	var actor_scene: PackedScene = PLAYER_SCENE if actor_key == "player" else DUMMY_SCENE
	var actor_instance: Node2D = actor_scene.instantiate()
	actor_instance.position = Vector2(80, 95)
	actor_instance.scale = Vector2(1.7, 1.7)
	holder.add_child(actor_instance)

	var collision: CollisionShape2D = actor_instance.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true

	var name_label := Label.new()
	name_label.text = "Player" if actor_key == "player" else "Enemy"
	name_label.position = Vector2(42, 142)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0, 1.0))
	holder.add_child(name_label)

	return holder


func _build_combat_log_style(caster: String) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 16.0
	style.content_margin_top = 16.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 16.0
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	if caster == "player":
		style.bg_color = Color(0.11, 0.24, 0.43, 0.92)
		style.border_color = Color(0.36, 0.67, 1.0, 0.96)
	else:
		style.bg_color = Color(0.39, 0.12, 0.14, 0.92)
		style.border_color = Color(1.0, 0.46, 0.46, 0.96)
	return style


func _get_actor_key_for_target_name(target_name: String) -> String:
	if target_name == "Player":
		return "player"
	return "enemy"


func _is_battle_over() -> bool:
	if player_health <= 0:
		resolving_turn = true
		active_side = "finished"
		_set_end_turn_enabled(false)
		_log_message("You were defeated.")
		_update_hud()
		return true

	if opponent_health <= 0:
		resolving_turn = true
		active_side = "finished"
		_set_end_turn_enabled(false)
		_log_message("Opponent defeated.")
		_update_hud()
		return true

	return false


func _can_open_fuse_selection() -> bool:
	if player_hand_ref == null or not player_hand_ref.has_method("get_cards"):
		return false

	var spell_counts := {}
	for hand_card in player_hand_ref.get_cards():
		var card_data: Dictionary = hand_card.get_meta("card_data", {})
		if str(card_data.get("category", "")).to_lower() != "spell":
			continue
		var card_id := str(hand_card.get_meta("card_id", ""))
		spell_counts[card_id] = int(spell_counts.get(card_id, 0)) + 1
		if int(spell_counts[card_id]) >= 2:
			return true

	return false


func _combine_selected_cards(selected_cards: Array) -> Node2D:
	if selected_cards.is_empty():
		return null

	var primary_card: Node2D = selected_cards[0]
	if primary_card == null or not is_instance_valid(primary_card):
		return null

	var combined_data: Dictionary = primary_card.get_meta("card_data", {}).duplicate(true)
	if combined_data.is_empty():
		return null

	var combined_cost := 0
	var combined_damage := 0
	var combined_block := 0
	for selected_card in selected_cards:
		if selected_card == null or not is_instance_valid(selected_card):
			continue
		var selected_data: Dictionary = selected_card.get_meta("card_data", {})
		combined_cost += int(selected_data.get("cost", 0))
		combined_damage += int(selected_data.get("damage", 0))
		combined_block += int(selected_data.get("block", 0))

	combined_data["cost"] = combined_cost
	if combined_damage > 0:
		combined_data["damage"] = combined_damage
	if combined_block > 0:
		combined_data["block"] = combined_block

	var base_name := str(combined_data.get("name", primary_card.name))
	if base_name.begins_with("Fused "):
		base_name = base_name.trim_prefix("Fused ")
	combined_data["name"] = "Fused %s" % base_name
	combined_data["description"] = _build_fused_description(combined_data)

	if primary_card.has_method("apply_card_data"):
		primary_card.apply_card_data(str(primary_card.get_meta("card_id", "")), combined_data)

	for i in range(1, selected_cards.size()):
		var extra_card: Node2D = selected_cards[i]
		if extra_card == null or not is_instance_valid(extra_card):
			continue
		_discard_player_card(extra_card)

	if player_hand_ref and player_hand_ref.has_method("update_hand_position"):
		player_hand_ref.update_hand_position(0.1)

	return primary_card


func _build_fused_description(card_data: Dictionary) -> String:
	var description := str(card_data.get("description", ""))
	var replacement_value := 0
	if int(card_data.get("damage", 0)) > 0:
		replacement_value = int(card_data.get("damage", 0))
	elif int(card_data.get("block", 0)) > 0:
		replacement_value = int(card_data.get("block", 0))

	if description.is_empty() or replacement_value <= 0:
		return description

	var regex := RegEx.new()
	regex.compile("\\d+")
	var match := regex.search(description)
	if match == null:
		return description

	return description.substr(0, match.get_start()) + str(replacement_value) + description.substr(match.get_end())


func _is_valid_player_target(card_data: Dictionary, target: Node2D) -> bool:
	if target == null:
		return false

	match str(card_data.get("target_group", "")).to_lower():
		"enemy":
			return target == dummy_target
		"ally", "self":
			return target == player_target
		_:
			return false


func _get_invalid_target_message(card_data: Dictionary) -> String:
	match str(card_data.get("target_group", "")).to_lower():
		"enemy":
			return "That spell must target an enemy."
		"ally", "self":
			return "That spell must target yourself or an ally."
		_:
			return "That target is not valid for this card."


func _get_default_target_for_opponent(card_data: Dictionary) -> Node2D:
	match str(card_data.get("target_group", "")).to_lower():
		"enemy":
			return player_target
		"ally", "self":
			return dummy_target
		_:
			return dummy_target


func _get_target_key(target: Node2D) -> String:
	if target == player_target:
		return "player"
	return "opponent"


func _get_target_display_name(target: Node2D) -> String:
	if target == player_target:
		return "Player"
	if target == dummy_target:
		return "Dummy"
	return "Target"


func _get_health_value(target_key: String) -> int:
	if target_key == "player":
		return player_health
	return opponent_health


func _set_health_value(target_key: String, value: int) -> void:
	if target_key == "player":
		player_health = value
	else:
		opponent_health = value


func _get_block_value(target_key: String) -> int:
	if target_key == "player":
		return player_block
	return opponent_block


func _set_block_value(target_key: String, value: int) -> void:
	if target_key == "player":
		player_block = value
	else:
		opponent_block = value
