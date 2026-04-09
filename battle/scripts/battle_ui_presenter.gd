extends RefCounted

const CARD_SCENE = preload("res://cards/scenes/card.tscn")
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")


static func update_hud(refs: Dictionary, state: Dictionary) -> void:
	var turn_state_label := refs.get("turn_state_label") as Label
	if turn_state_label:
		var side_text := "Your Turn"
		if str(state.get("active_side", "")) == "opponent":
			side_text = "%s Turn" % str(state.get("enemy_name", "Enemy"))
		elif str(state.get("active_side", "")) == "finished":
			side_text = "Battle Finished"
		turn_state_label.text = side_text

	var turn_number_label := refs.get("turn_number_label") as Label
	if turn_number_label:
		turn_number_label.text = "Turn %d" % int(state.get("player_turn_number", 1))

	var mana_counter_label := refs.get("mana_counter_label") as RichTextLabel
	if mana_counter_label:
		mana_counter_label.clear()
		mana_counter_label.append_text("[center][b]%d[/b][/center]" % int(state.get("player_current_mana", 0)))

	var opponent_mana_counter_label := refs.get("opponent_mana_counter_label") as RichTextLabel
	if opponent_mana_counter_label:
		opponent_mana_counter_label.clear()
		opponent_mana_counter_label.append_text("[center][b]%d[/b][/center]" % int(state.get("opponent_current_mana", 0)))

	var health_label := refs.get("health_label") as Label
	if health_label:
		health_label.text = "Health: %d / %d" % [int(state.get("player_health", 0)), int(state.get("starting_health", 0))]

	var level_label := refs.get("level_label") as Label
	if level_label:
		level_label.text = "Level: %d" % int(state.get("player_level", 1))

	var mana_regen_label := refs.get("mana_regen_label") as Label
	if mana_regen_label:
		mana_regen_label.text = "Mana Regen: +%d / turn" % int(state.get("player_mana_regen", 0))

	var stage_label := refs.get("stage_label") as Label
	if stage_label:
		stage_label.text = "Stage: %d" % int(state.get("current_stage_number", 1))

	var player_name_label := refs.get("player_name_label") as Label
	if player_name_label:
		player_name_label.text = "Player"

	var player_health_value_label := refs.get("player_health_value_label") as Label
	if player_health_value_label:
		player_health_value_label.text = "HP %d/%d" % [int(state.get("player_health", 0)), int(state.get("starting_health", 0))]

	var player_health_bar := refs.get("player_health_bar") as ProgressBar
	if player_health_bar:
		player_health_bar.max_value = int(state.get("starting_health", 0))
		player_health_bar.value = int(state.get("player_health", 0))

	var player_block_label := refs.get("player_block_label") as Label
	if player_block_label:
		player_block_label.text = "Block %d" % int(state.get("player_block", 0))

	_refresh_spell_action_pips(
		refs.get("player_spell_actions_container") as HBoxContainer,
		int(state.get("player_remaining_spell_actions", 0)),
		int(state.get("player_max_spell_actions", 1)),
		Color(0.36, 0.82, 1.0, 1.0),
		Color(0.1, 0.18, 0.26, 0.88)
	)

	var opponent_name_label := refs.get("opponent_name_label") as Label
	if opponent_name_label:
		opponent_name_label.text = str(state.get("enemy_name", "Enemy"))

	var opponent_health_value_label := refs.get("opponent_health_value_label") as Label
	if opponent_health_value_label:
		opponent_health_value_label.text = "HP %d/%d" % [int(state.get("opponent_health", 0)), int(state.get("opponent_max_health", 0))]

	var opponent_health_bar := refs.get("opponent_health_bar") as ProgressBar
	if opponent_health_bar:
		opponent_health_bar.max_value = int(state.get("opponent_max_health", 0))
		opponent_health_bar.value = int(state.get("opponent_health", 0))

	var opponent_block_label := refs.get("opponent_block_label") as Label
	if opponent_block_label:
		opponent_block_label.text = "Block %d" % int(state.get("opponent_block", 0))

	_refresh_spell_action_pips(
		refs.get("opponent_spell_actions_container") as HBoxContainer,
		int(state.get("opponent_remaining_spell_actions", 0)),
		int(state.get("opponent_max_spell_actions", 1)),
		Color(0.96, 0.38, 0.36, 1.0),
		Color(0.28, 0.09, 0.09, 0.92)
	)


static func refresh_combat_log_overlay(entries_container: VBoxContainer, combat_log_entries: Array[Dictionary], current_enemy_name: String, current_enemy_id: String, current_enemy_data: Dictionary) -> void:
	if entries_container == null:
		return

	for child in entries_container.get_children():
		child.queue_free()

	if combat_log_entries.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No spells have been played yet."
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", Color(0.84, 0.9, 0.96, 1.0))
		entries_container.add_child(empty_label)
		return

	for index in range(combat_log_entries.size() - 1, -1, -1):
		entries_container.add_child(_build_combat_log_entry(combat_log_entries[index], current_enemy_name, current_enemy_id, current_enemy_data))


static func _build_combat_log_entry(entry: Dictionary, current_enemy_name: String, current_enemy_id: String, current_enemy_data: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 300)
	panel.add_theme_stylebox_override("panel", _build_combat_log_style(str(entry.get("caster", ""))))

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	panel.add_child(root)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 24)
	top_row.custom_minimum_size = Vector2(0, 220)
	root.add_child(top_row)

	var card_data: Dictionary = entry.get("card_data", {})
	if str(card_data.get("effect", "")) == "combine":
		for fusion_preview in _build_fusion_previews(card_data):
			top_row.add_child(fusion_preview)
	else:
		top_row.add_child(_build_actor_preview(str(entry.get("caster", "")), current_enemy_id, current_enemy_data))
		top_row.add_child(_build_card_preview(entry))
		if not str(entry.get("target_name", "")).is_empty():
			top_row.add_child(_build_actor_preview(_get_actor_key_for_target_name(str(entry.get("target_name", ""))), current_enemy_id, current_enemy_data))

	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 6)
	root.add_child(details)

	var summary_label := Label.new()
	summary_label.text = _build_combat_log_summary(entry, card_data, current_enemy_name)
	summary_label.add_theme_font_size_override("font_size", 18)
	summary_label.add_theme_color_override("font_color", Color(0.96, 0.98, 1.0, 1.0))
	details.add_child(summary_label)

	var result_label := Label.new()
	var damage_done := int(entry.get("damage_done", 0))
	var block_done := int(entry.get("block_done", 0))
	var heal_done := int(entry.get("heal_done", 0))
	if damage_done > 0:
		result_label.text = "Damage Dealt: %d" % damage_done
	elif block_done > 0:
		result_label.text = "Block Granted: %d" % block_done
	elif heal_done > 0:
		result_label.text = "Healing Done: %d" % heal_done
	else:
		result_label.text = "Effect resolved."
	result_label.add_theme_font_size_override("font_size", 16)
	result_label.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0, 1.0))
	details.add_child(result_label)

	var stats_text: Array[String] = []
	if int(card_data.get("damage", 0)) > 0:
		stats_text.append("Base Damage: %d" % int(card_data.get("damage", 0)))
	if int(card_data.get("block", 0)) > 0:
		stats_text.append("Base Block: %d" % int(card_data.get("block", 0)))
	if int(card_data.get("heal", 0)) > 0:
		stats_text.append("Base Heal: %d" % int(card_data.get("heal", 0)))
	stats_text.append("Cost: %d" % int(card_data.get("cost", 0)))

	var stats_label := Label.new()
	stats_label.text = " | ".join(stats_text)
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.69, 0.77, 0.87, 1.0))
	details.add_child(stats_label)

	var fused_components = card_data.get("fused_components", [])
	if fused_components is Array and not fused_components.is_empty():
		var fused_label := Label.new()
		fused_label.text = "Fused from: %s" % " + ".join(PackedStringArray(_get_fused_component_names(card_data)))
		fused_label.add_theme_font_size_override("font_size", 14)
		fused_label.add_theme_color_override("font_color", Color(0.82, 0.88, 0.97, 1.0))
		details.add_child(fused_label)

	return panel


static func _build_combat_log_summary(entry: Dictionary, card_data: Dictionary, current_enemy_name: String) -> String:
	var caster_name := "Player" if str(entry.get("caster", "")) == "player" else current_enemy_name
	var card_name := str(card_data.get("name", "Spell"))
	var target_name := str(entry.get("target_name", ""))
	var fused_component_names := _get_fused_component_names(card_data)

	if str(card_data.get("effect", "")) == "combine" and fused_component_names.size() >= 2:
		var fusion_result_name := _get_fusion_result_name(card_data)
		if not fusion_result_name.is_empty():
			return "%s used %s to fuse %s with %s into %s" % [caster_name, card_name, fused_component_names[0], fused_component_names[1], fusion_result_name]
		return "%s used %s to fuse %s with %s" % [caster_name, card_name, fused_component_names[0], fused_component_names[1]]

	if target_name.is_empty():
		return "%s used %s" % [caster_name, card_name]

	return "%s used %s on %s" % [caster_name, card_name, target_name]


static func _build_card_preview(entry: Dictionary) -> Control:
	var card_holder := Control.new()
	card_holder.custom_minimum_size = Vector2(180, 220)

	var card_instance: Node2D = CARD_SCENE.instantiate()
	card_instance.position = Vector2(90, 118)
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


static func _build_card_preview_from_snapshot(card_snapshot: Dictionary) -> Control:
	return _build_card_preview({
		"card_id": str(card_snapshot.get("card_id", "")),
		"card_data": card_snapshot.get("card_data", {}).duplicate(true),
	})


static func _build_fusion_previews(card_data: Dictionary) -> Array[Control]:
	var previews: Array[Control] = []
	previews.append(_build_card_preview({
		"card_id": str(card_data.get("id", "fuse_mana")),
		"card_data": card_data,
	}))

	var fused_components = card_data.get("fused_components", [])
	if fused_components is Array:
		for component in fused_components:
			if component is Dictionary:
				previews.append(_build_card_preview_from_snapshot(component))

	var fusion_result = card_data.get("fusion_result", {})
	if fusion_result is Dictionary and not fusion_result.is_empty():
		previews.append(_build_card_preview_from_snapshot(fusion_result))

	return previews


static func _build_actor_preview(actor_key: String, current_enemy_id: String, current_enemy_data: Dictionary) -> Control:
	var holder := Control.new()
	holder.custom_minimum_size = Vector2(170, 220)

	var actor_scene: PackedScene = PLAYER_SCENE if actor_key == "player" else ENEMY_SCENE
	var actor_instance: Node2D = actor_scene.instantiate()
	actor_instance.position = Vector2(85, 118)
	if actor_key == "player":
		actor_instance.scale = Vector2(1.5, 1.5)
	elif actor_instance.has_method("apply_enemy_data"):
		actor_instance.apply_enemy_data(current_enemy_id, current_enemy_data)
		actor_instance.scale = Vector2(1.35, 1.35)
	holder.add_child(actor_instance)

	var collision: CollisionShape2D = actor_instance.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true

	return holder


static func _build_combat_log_style(caster: String) -> StyleBoxFlat:
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


static func _get_actor_key_for_target_name(target_name: String) -> String:
	if target_name == "Player":
		return "player"
	return "enemy"


static func _get_fusion_result_name(card_data: Dictionary) -> String:
	var fusion_result = card_data.get("fusion_result", {})
	if fusion_result is Dictionary:
		var result_data: Dictionary = fusion_result.get("card_data", {})
		return str(result_data.get("name", fusion_result.get("card_id", "")))
	return ""


static func _get_fused_component_names(card_data: Dictionary) -> Array[String]:
	var component_names: Array[String] = []
	var fused_components = card_data.get("fused_components", [])
	if fused_components is Array:
		for component in fused_components:
			if component is Dictionary:
				var component_data: Dictionary = component.get("card_data", {})
				component_names.append(str(component_data.get("name", component.get("card_id", "Spell"))))
			else:
				component_names.append(str(component))
	return component_names


static func _refresh_spell_action_pips(container: HBoxContainer, remaining: int, total: int, ready_color: Color, spent_color: Color) -> void:
	if container == null:
		return

	total = maxi(total, 1)
	if container.get_child_count() != total:
		for child in container.get_children():
			child.queue_free()
		for index in range(total):
			var pip := Panel.new()
			pip.custom_minimum_size = Vector2(22, 22)
			pip.name = "SpellActionPip%d" % index
			container.add_child(pip)

	for index in range(container.get_child_count()):
		var pip_panel := container.get_child(index) as Panel
		if pip_panel == null:
			continue
		pip_panel.add_theme_stylebox_override(
			"panel",
			_build_spell_action_style(ready_color if index < remaining else spent_color)
		)


static func _build_spell_action_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color(1, 0.95, 0.85, 0.42)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 999
	style.corner_radius_top_right = 999
	style.corner_radius_bottom_right = 999
	style.corner_radius_bottom_left = 999
	return style
