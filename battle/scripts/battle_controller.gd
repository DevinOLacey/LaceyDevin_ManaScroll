extends Node2D

const CombatCardDatabase = preload("res://cards/data/card_database.gd")
const BattleCombatResolver = preload("res://battle/scripts/battle_combat_resolver.gd")
const BattleEnemyAI = preload("res://battle/scripts/battle_enemy_ai.gd")
const BattleEnemySceneResolverResource = preload("res://battle/scripts/battle_enemy_scene_resolver.gd")
const BattleFusionService = preload("res://battle/scripts/battle_fusion_service.gd")
const BattleLevelUpService = preload("res://battle/scripts/battle_level_up_service.gd")
const BattlePathEffectsService = preload("res://battle/scripts/battle_path_effects_service.gd")
const BattleTargeting = preload("res://battle/scripts/battle_targeting.gd")
const BattleUIPresenter = preload("res://battle/scripts/battle_ui_presenter.gd")
const EnemyDatabaseResource = preload("res://battle/data/enemy_database.gd")
const BattleConstants = preload("res://shared/constants/battle_constants.gd")
const SELECT_FROM_HAND_SCENE = preload("res://cards/scenes/select_from_hand.tscn")

var battle_timer: Timer
var end_turn_button: TextureButton
var deck_ref: Node
var player_hand_ref: Node
var player_target: Node2D
var enemy_sprites_ref: Node2D
var enemy_target: Node2D
var turn_state_label: Label
var turn_number_label: Label
var mana_counter_label: RichTextLabel
var opponent_mana_counter_label: RichTextLabel
var health_label: Label
var level_label: Label
var mana_regen_label: Label
var stage_label: Label
var player_name_label: Label
var player_health_value_label: Label
var player_health_bar: ProgressBar
var player_block_label: Label
var class_mechanics_panel: Control
var class_mechanics_label: Label
var player_spell_actions_container: HBoxContainer
var opponent_name_label: Label
var opponent_health_value_label: Label
var opponent_health_bar: ProgressBar
var opponent_block_label: Label
var opponent_ailments_panel: Control
var opponent_ailments_label: Label
var opponent_spell_actions_container: HBoxContainer
var battle_log_label: Label
var selection_scene_ref: Node2D
var combat_log_canvas_layer: CanvasLayer
var combat_log_entries_container: VBoxContainer
var combat_log_scroll_container: ScrollContainer
var defeat_transition_layer: CanvasLayer
var defeat_transition_rect: ColorRect
var level_up_overlay: CanvasLayer
var spell_preview_overlay: CanvasLayer
var combat_log_entries: Array[Dictionary] = []
var pending_level_up_options: Array[Dictionary] = []
var chosen_upgrade_paths: Array[String] = []
var player_path_runtime := BattlePathEffectsService.create_runtime_state()

var player_turn_number := 1
var opponent_turn_number := 0
var player_level := 1
var player_max_mana := 1
var player_current_mana := 1
var player_mana_regen := 1
var opponent_max_mana := 0
var opponent_current_mana := 0
var opponent_mana_regen := 1.0
var opponent_mana_progress := 0.0
var player_health := BattleConstants.STARTING_HEALTH
var opponent_max_health := BattleConstants.STARTING_HEALTH
var opponent_health := BattleConstants.STARTING_HEALTH
var current_stage_number := 1
var player_block := 0
var opponent_block := 0
var player_max_spell_actions := 1
var player_remaining_spell_actions := 1
var opponent_max_spell_actions := 1
var opponent_remaining_spell_actions := 1
var pending_fuse_charges := 0
var opponent_burn_stacks := 0
var opponent_burn_turns_remaining := 0
var active_side := "player"
var resolving_turn := false
var current_enemy_id := ""
var current_enemy_data: Dictionary = {}
var victory_sequence_started := false

var card_definitions := CombatCardDatabase.get_card_definitions()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = BattleConstants.AI_ACTION_DELAY
	end_turn_button = $"../EndTurnButton"
	deck_ref = $"../PlayerSide/PlayerDecks/Deck"
	player_hand_ref = $"../PlayerSide/PlayerDecks/PlayerHand"
	enemy_sprites_ref = $"../Enemies/EnemySprites"
	turn_state_label = $"../TurnPanel/TurnMargin/TurnVBox/TurnStateLabel"
	turn_number_label = $"../TurnPanel/TurnMargin/TurnVBox/TurnNumberLabel"
	mana_counter_label = $"../Mana/ManaCount"
	opponent_mana_counter_label = get_node_or_null("../EnemyMana/EnemyManaCount")
	health_label = $"../BattleHUDLayer/HUDBar/HUDMargin/HUDRow/HealthLabel"
	level_label = $"../BattleHUDLayer/HUDBar/HUDMargin/HUDRow/LevelLabel"
	mana_regen_label = $"../BattleHUDLayer/HUDBar/HUDMargin/HUDRow/ManaRegenLabel"
	stage_label = $"../BattleHUDLayer/HUDBar/HUDMargin/HUDRow/StageLabel"
	player_name_label = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/PlayerNameLabel"
	player_health_value_label = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/PlayerHealthValueLabel"
	player_health_bar = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/PlayerHealthRow/PlayerHealthBar"
	player_block_label = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/PlayerHealthRow/PlayerBlockLabel"
	class_mechanics_panel = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/ClassMechanicsPanel"
	class_mechanics_label = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/ClassMechanicsPanel/ClassMechanicsMargin/ClassMechanicsLabel"
	player_spell_actions_container = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/PlayerSpellActions"
	opponent_name_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentNameLabel"
	opponent_health_value_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentHealthValueLabel"
	opponent_health_bar = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentHealthRow/OpponentHealthBar"
	opponent_block_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentHealthRow/OpponentBlockLabel"
	opponent_ailments_panel = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentAilmentsPanel"
	opponent_ailments_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentAilmentsPanel/OpponentAilmentsMargin/OpponentAilmentsLabel"
	opponent_spell_actions_container = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentSpellActions"
	battle_log_label = $"../BattleLogLabel"
	combat_log_canvas_layer = $"../CombatLogOverlay"
	combat_log_entries_container = $"../CombatLogOverlay/CombatLogPanel/CombatLogMargin/CombatLogVBox/CombatLogScroll/CombatLogScrollMargin/CombatLogEntries"
	combat_log_scroll_container = $"../CombatLogOverlay/CombatLogPanel/CombatLogMargin/CombatLogVBox/CombatLogScroll"
	defeat_transition_layer = get_node_or_null("../DefeatTransitionLayer")
	defeat_transition_rect = get_node_or_null("../DefeatTransitionLayer/DefeatFade")
	level_up_overlay = get_node_or_null("../BattleLevelUpOverlay")
	spell_preview_overlay = get_node_or_null("../BattleSpellPreviewOverlay")
	player_target = $"../PlayerSide/PlayerSprites/Player"
	_wire_ui_signals()
	if deck_ref and deck_ref.has_method("set_card_draw_modifier"):
		deck_ref.set_card_draw_modifier(Callable(self, "_modify_drawn_player_card"))
	if deck_ref and deck_ref.has_method("set_deck_view_card_ids_provider"):
		deck_ref.set_deck_view_card_ids_provider(Callable(self, "_get_deck_view_card_ids"))
	if deck_ref and deck_ref.has_method("set_deck_view_card_data_provider"):
		deck_ref.set_deck_view_card_data_provider(Callable(self, "_get_deck_view_card_data"))
	_spawn_enemy_for_stage(current_stage_number)
	_begin_player_turn(true)


func _on_end_turn_button_pressed() -> void:
	if active_side != "player" or resolving_turn:
		return
	_end_player_turn("You ended your turn.")


func _on_combat_log_button_pressed() -> void:
	_refresh_combat_log_overlay()
	if combat_log_canvas_layer:
		combat_log_canvas_layer.visible = true
		call_deferred("_scroll_combat_log_to_top")


func _on_close_combat_log_button_pressed() -> void:
	if combat_log_canvas_layer:
		combat_log_canvas_layer.visible = false


func can_player_interact() -> bool:
	return active_side == "player" and not resolving_turn and selection_scene_ref == null and not _is_level_up_overlay_visible()


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

	if category == "spell" and player_remaining_spell_actions <= 0:
		_log_message("You have no spell actions left this turn.")
		_update_hud()
		return false

	if mana_cost > player_current_mana:
		_log_message("%s costs %d mana." % [card_name, mana_cost])
		_update_hud()
		return false

	if not BattleTargeting.is_valid_player_target(card_data, target, player_target, enemy_target):
		_log_message(BattleTargeting.get_invalid_target_message(card_data))
		_update_hud()
		return false

	match category:
		"enchantment":
			return _play_player_enchantment(card, card_data, mana_cost)
		"spell":
			return await _play_player_spell(card, card_data, mana_cost, target)
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
	if str(card_data.get("effect", "")) != "combine":
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
	var card_id := str(card.get_meta("card_id", ""))
	var path_resolution := BattlePathEffectsService.build_player_cast_resolution(player_path_runtime, card_id, card_data)
	var resolved_card_data: Dictionary = path_resolution.get("card_data", card_data)
	var card_name := str(resolved_card_data.get("name", card.name))

	if total_cost > player_current_mana:
		_log_message("You do not have enough mana for that spell.")
		_update_hud()
		return false

	player_current_mana -= total_cost
	player_remaining_spell_actions = maxi(0, player_remaining_spell_actions - 1)
	_discard_player_card(card)
	await _show_spell_preview(card_id, resolved_card_data, "player")
	var resolution := _resolve_spell_effect(resolved_card_data, "player", target, effect_multiplier)

	var extra_messages: Array[String] = []
	var path_messages = path_resolution.get("extra_messages", [])
	if path_messages is Array:
		for message in path_messages:
			if not str(message).is_empty():
				extra_messages.append(str(message))
	var granted_spell_actions := int(path_resolution.get("grant_spell_actions", 0))
	if granted_spell_actions > 0:
		player_max_spell_actions += granted_spell_actions
		extra_messages.append("You gain %d extra spell action%s for the rest of combat." % [granted_spell_actions, "" if granted_spell_actions == 1 else "s"])
	var burn_to_target := int(path_resolution.get("burn_to_target", 0))
	if burn_to_target > 0:
		var burn_message := _apply_burn_to_target(BattleTargeting.get_target_key(target, player_target), burn_to_target)
		if not burn_message.is_empty():
			extra_messages.append(burn_message)
	if bool(path_resolution.get("refresh_hand_cards", false)):
		_refresh_player_hand_path_cards()

	_log_message(_compose_battle_message(str(resolution.get("log_message", "")), extra_messages))

	if _is_battle_over():
		pending_fuse_charges = 0
		return true

	if effect_multiplier > 1:
		_log_message("%s fused %d matching spell(s)." % [card_name, effect_multiplier - 1])
	pending_fuse_charges = 0
	_update_hud()
	return true


func _resolve_spell_effect(card_data: Dictionary, caster: String, target: Node2D, multiplier: int = 1) -> Dictionary:
	var target_key := BattleTargeting.get_target_key(target, player_target)
	var target_name := BattleTargeting.get_target_display_name(target, player_target, enemy_target, _get_current_enemy_name())
	var resolution := BattleCombatResolver.resolve_spell_effect(
		card_data,
		caster,
		target_key,
		target_name,
		multiplier,
		{
			"player_health": player_health,
			"player_max_health": BattleConstants.STARTING_HEALTH,
			"player_block": player_block,
			"player_ember_guard_active": BattlePathEffectsService.is_ember_guard_active(player_path_runtime),
			"player_frost_armor_charges": BattlePathEffectsService.get_frost_armor_charges(player_path_runtime),
			"opponent_health": opponent_health,
			"opponent_max_health": opponent_max_health,
			"opponent_block": opponent_block,
		},
		_get_current_enemy_name()
	)
	player_health = int(resolution.get("player_health", player_health))
	opponent_health = int(resolution.get("opponent_health", opponent_health))
	player_block = int(resolution.get("player_block", player_block))
	opponent_block = int(resolution.get("opponent_block", opponent_block))
	BattlePathEffectsService.set_ember_guard_active(player_path_runtime, bool(resolution.get("player_ember_guard_active", BattlePathEffectsService.is_ember_guard_active(player_path_runtime))))
	BattlePathEffectsService.set_frost_armor_charges(player_path_runtime, int(resolution.get("player_frost_armor_charges", BattlePathEffectsService.get_frost_armor_charges(player_path_runtime))))
	_append_combat_log(
		card_data,
		caster,
		target_name,
		int(resolution.get("damage_done", 0)),
		int(resolution.get("block_done", 0)),
		int(resolution.get("heal_done", 0))
	)

	_update_hud()
	return resolution


func _end_player_turn(reason: String) -> void:
	if resolving_turn:
		return

	resolving_turn = true
	player_current_mana += player_mana_regen
	player_max_mana = max(player_max_mana, player_current_mana)
	active_side = "opponent"
	pending_fuse_charges = 0
	_set_end_turn_enabled(false)
	_log_message(reason)
	_update_hud()
	call_deferred("_run_opponent_turn")


func _run_opponent_turn() -> void:
	battle_timer.start()
	await battle_timer.timeout

	if _apply_turn_start_statuses("opponent"):
		return

	if _is_battle_over():
		return

	_begin_opponent_turn()
	var acted_this_turn := false
	while opponent_remaining_spell_actions > 0:
		var opponent_card := _choose_opponent_card()
		if opponent_card.is_empty():
			if not acted_this_turn:
				_log_message("%s could not act." % _get_current_enemy_name())
			break

		var card_data: Dictionary = card_definitions.get(opponent_card, {})
		var mana_cost := int(card_data.get("cost", 0))
		if mana_cost > opponent_current_mana:
			if not acted_this_turn:
				_log_message("%s passed." % _get_current_enemy_name())
			break

		opponent_mana_progress = maxf(0.0, opponent_mana_progress - float(mana_cost))
		_sync_opponent_mana()
		opponent_remaining_spell_actions = maxi(0, opponent_remaining_spell_actions - 1)
		await _show_spell_preview(opponent_card, card_data, "opponent")
		var resolution := _resolve_spell_effect(card_data, "opponent", BattleTargeting.get_default_target_for_opponent(card_data, player_target, enemy_target))
		var extra_messages: Array[String] = []
		var ember_burn_to_attacker := int(resolution.get("ember_burn_to_attacker", 0))
		if ember_burn_to_attacker > 0:
			var ember_burn_message := _apply_burn_to_target("opponent", ember_burn_to_attacker)
			if not ember_burn_message.is_empty():
				extra_messages.append(ember_burn_message)
		_log_message(_compose_battle_message(str(resolution.get("log_message", "")), extra_messages))
		acted_this_turn = true

		if _is_battle_over() or opponent_remaining_spell_actions <= 0:
			break

		_update_hud()
		battle_timer.start()
		await battle_timer.timeout

	_update_hud()

	battle_timer.start()
	await battle_timer.timeout

	if _is_battle_over():
		return

	opponent_mana_progress += opponent_mana_regen
	_sync_opponent_mana()
	_begin_player_turn(false)


func _begin_player_turn(is_first_turn: bool) -> void:
	resolving_turn = false
	active_side = "player"
	player_remaining_spell_actions = player_max_spell_actions
	pending_fuse_charges = 0

	if is_first_turn:
		player_turn_number = 1
		player_current_mana = max(player_current_mana, player_mana_regen)
	else:
		player_turn_number += 1
		if deck_ref and deck_ref.has_method("draw_up_to_max_hand_size"):
			deck_ref.draw_up_to_max_hand_size()

	player_max_mana = max(player_max_mana, player_current_mana)
	_set_end_turn_enabled(true)
	_log_message("Player turn %d." % player_turn_number)
	_update_hud()


func _begin_opponent_turn() -> void:
	active_side = "opponent"
	opponent_turn_number += 1
	opponent_remaining_spell_actions = opponent_max_spell_actions
	_log_message("%s turn %d." % [_get_current_enemy_name(), opponent_turn_number])
	_update_hud()


func _choose_opponent_card() -> String:
	return BattleEnemyAI.choose_card(
		current_enemy_data,
		card_definitions,
		opponent_current_mana,
		opponent_health,
		opponent_block
	)


func _discard_player_card(card) -> void:
	if card == null or not is_instance_valid(card):
		return
	var card_manager_ref := get_node_or_null("../CardManager")
	if card_manager_ref and card_manager_ref.has_method("_prepare_card_for_removal"):
		card_manager_ref._prepare_card_for_removal(card)
	if card_manager_ref and card_manager_ref.has_method("clear_card_hover"):
		card_manager_ref.clear_card_hover(card)
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
	BattleUIPresenter.update_hud(
		{
			"turn_state_label": turn_state_label,
			"turn_number_label": turn_number_label,
			"mana_counter_label": mana_counter_label,
			"opponent_mana_counter_label": opponent_mana_counter_label,
			"health_label": health_label,
			"level_label": level_label,
			"mana_regen_label": mana_regen_label,
			"stage_label": stage_label,
			"player_name_label": player_name_label,
			"player_health_value_label": player_health_value_label,
			"player_health_bar": player_health_bar,
			"player_block_label": player_block_label,
			"class_mechanics_panel": class_mechanics_panel,
			"class_mechanics_label": class_mechanics_label,
			"player_spell_actions_container": player_spell_actions_container,
			"opponent_name_label": opponent_name_label,
			"opponent_health_value_label": opponent_health_value_label,
			"opponent_health_bar": opponent_health_bar,
			"opponent_block_label": opponent_block_label,
			"opponent_ailments_panel": opponent_ailments_panel,
			"opponent_ailments_label": opponent_ailments_label,
			"opponent_spell_actions_container": opponent_spell_actions_container,
		},
		{
			"active_side": active_side,
			"enemy_name": _get_current_enemy_name(),
			"player_turn_number": player_turn_number,
			"player_current_mana": player_current_mana,
			"opponent_current_mana": opponent_current_mana,
			"player_health": player_health,
			"starting_health": BattleConstants.STARTING_HEALTH,
			"player_level": player_level,
			"player_mana_regen": player_mana_regen,
			"current_stage_number": current_stage_number,
			"player_block": player_block,
			"class_mechanics_text": _get_class_mechanics_text(),
			"player_remaining_spell_actions": player_remaining_spell_actions,
			"player_max_spell_actions": player_max_spell_actions,
			"opponent_health": opponent_health,
			"opponent_max_health": opponent_max_health,
			"opponent_block": opponent_block,
			"opponent_ailments_text": _get_opponent_ailments_text(),
			"opponent_remaining_spell_actions": opponent_remaining_spell_actions,
			"opponent_max_spell_actions": opponent_max_spell_actions,
		}
	)


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
		var fused_component_cards := _get_selected_card_snapshots(selected_cards)
		var fused_card := _combine_selected_cards(selected_cards)
		if fused_card:
			_apply_path_text_to_card(fused_card)
			var card_name := str(fused_card.get_meta("card_data", {}).get("name", fused_card.name))
			_append_combat_log({
				"id": "fuse_mana",
				"name": "Fuse Mana",
				"art": "res://cards/art/Fuse Mana.png",
				"category": "enchantment",
				"type": "[b]Enchant[/b]",
				"description": "Fuse the mana of 2 of the same spell together",
				"effect": "combine",
				"fused_components": fused_component_cards,
				"fusion_result": {
					"card_id": str(fused_card.get_meta("card_id", "")),
					"card_data": fused_card.get_meta("card_data", {}).duplicate(true),
				},
			}, "player", "", 0, 0)
			_log_message("%s was fused into a stronger spell." % card_name)
	_update_hud()


func _log_message(message: String) -> void:
	if battle_log_label:
		battle_log_label.text = message


func _append_combat_log(card_data: Dictionary, caster: String, target_name: String, damage_done: int, block_done: int, heal_done: int = 0) -> void:
	combat_log_entries.append({
		"card_id": str(card_data.get("id", card_data.get("name", ""))).to_lower().replace(" ", "_"),
		"card_data": card_data.duplicate(true),
		"caster": caster,
		"target_name": target_name,
		"damage_done": damage_done,
		"block_done": block_done,
		"heal_done": heal_done,
	})
	if combat_log_canvas_layer and combat_log_canvas_layer.visible:
		_refresh_combat_log_overlay()


func _refresh_combat_log_overlay() -> void:
	BattleUIPresenter.refresh_combat_log_overlay(
		combat_log_entries_container,
		combat_log_entries,
		_get_current_enemy_name(),
		current_enemy_id,
		current_enemy_data
	)
	call_deferred("_scroll_combat_log_to_top")


func _is_battle_over() -> bool:
	if player_health <= 0:
		resolving_turn = true
		active_side = "finished"
		_set_end_turn_enabled(false)
		_log_message("You were defeated.")
		_update_hud()
		call_deferred("_show_defeat_screen")
		return true

	if opponent_health <= 0:
		resolving_turn = true
		active_side = "finished"
		_set_end_turn_enabled(false)
		_log_message("%s defeated." % _get_current_enemy_name())
		_update_hud()
		if not victory_sequence_started:
			victory_sequence_started = true
			call_deferred("_show_level_up_overlay_after_victory")
		return true

	return false


func _show_defeat_screen() -> void:
	await _play_defeat_transition()
	get_tree().change_scene_to_file(BattleConstants.DEFEAT_SCENE_PATH)


func _play_defeat_transition() -> void:
	if BattleConstants.PLAYER_DEATH_ANIMATION_LEAD_TIME > 0.0:
		await get_tree().create_timer(BattleConstants.PLAYER_DEATH_ANIMATION_LEAD_TIME).timeout

	if defeat_transition_layer == null or defeat_transition_rect == null:
		return

	defeat_transition_layer.visible = true
	defeat_transition_rect.color = Color(0, 0, 0, 0)
	var tween := create_tween()
	tween.tween_property(defeat_transition_rect, "color", Color(0, 0, 0, 1), BattleConstants.DEFEAT_TRANSITION_FADE_DURATION)
	await tween.finished


func _can_open_fuse_selection() -> bool:
	if player_hand_ref == null or not player_hand_ref.has_method("get_cards"):
		return false

	return BattleFusionService.can_open_fuse_selection(player_hand_ref.get_cards())


func _combine_selected_cards(selected_cards: Array) -> Node2D:
	return BattleFusionService.combine_selected_cards(
		selected_cards,
		Callable(self, "_discard_player_card"),
		func():
			if player_hand_ref and player_hand_ref.has_method("update_hand_position"):
				player_hand_ref.update_hand_position(0.1)
	)


func _get_selected_card_snapshots(selected_cards: Array) -> Array[Dictionary]:
	return BattleFusionService.get_selected_card_snapshots(selected_cards)


func _scroll_combat_log_to_top() -> void:
	if combat_log_scroll_container:
		combat_log_scroll_container.scroll_vertical = 0


func _show_spell_preview(card_id: String, card_data: Dictionary, caster: String) -> void:
	if spell_preview_overlay == null or not spell_preview_overlay.has_method("show_spell_preview"):
		return
	await spell_preview_overlay.show_spell_preview(card_id, card_data, caster)


func _wire_ui_signals() -> void:
	var combat_log_button := get_node_or_null("../BattleHUDLayer/HUDBar/HUDMargin/HUDRow/CombatLogButton") as Button
	if combat_log_button and not combat_log_button.pressed.is_connected(_on_combat_log_button_pressed):
		combat_log_button.pressed.connect(_on_combat_log_button_pressed)

	var close_combat_log_button := get_node_or_null("../CombatLogOverlay/CombatLogPanel/CombatLogMargin/CombatLogVBox/CombatLogHeader/CloseCombatLogButton") as Button
	if close_combat_log_button and not close_combat_log_button.pressed.is_connected(_on_close_combat_log_button_pressed):
		close_combat_log_button.pressed.connect(_on_close_combat_log_button_pressed)

	if level_up_overlay and level_up_overlay.has_signal("option_selected") and not level_up_overlay.is_connected("option_selected", Callable(self, "_on_level_up_option_selected")):
		level_up_overlay.connect("option_selected", Callable(self, "_on_level_up_option_selected"))


func _show_level_up_overlay_after_victory() -> void:
	if enemy_target and enemy_target.has_method("play_defeat_animation") and enemy_target.has_signal("defeat_animation_finished"):
		enemy_target.play_defeat_animation()
		await enemy_target.defeat_animation_finished

	if BattleConstants.ENEMY_DEFEAT_MODAL_DELAY > 0.0:
		await get_tree().create_timer(BattleConstants.ENEMY_DEFEAT_MODAL_DELAY).timeout

	pending_level_up_options = BattleLevelUpService.build_level_up_options(3)
	if level_up_overlay and level_up_overlay.has_method("configure_options"):
		level_up_overlay.configure_options(pending_level_up_options)
	if level_up_overlay and level_up_overlay.has_method("show_overlay"):
		level_up_overlay.show_overlay()

	_log_message("Choose a path to continue.")


func _on_level_up_option_selected(option_id: String) -> void:
	var selected_option := BattleLevelUpService.get_option_by_id(option_id)
	if selected_option.is_empty():
		return

	if level_up_overlay and level_up_overlay.has_method("hide_overlay"):
		level_up_overlay.hide_overlay()

	player_level += 1
	BattlePathEffectsService.unlock_path(player_path_runtime, option_id)
	chosen_upgrade_paths.append(str(selected_option.get("title", option_id)))
	pending_level_up_options.clear()
	victory_sequence_started = false
	_log_message("You chose %s." % str(selected_option.get("title", "a new path")))
	_advance_to_next_stage()


func _advance_to_next_stage() -> void:
	current_stage_number += 1
	_reset_player_state_for_new_stage()
	_spawn_enemy_for_stage(current_stage_number)
	_begin_new_stage_player_turn()


func _is_level_up_overlay_visible() -> bool:
	return level_up_overlay != null and level_up_overlay.visible


func _spawn_enemy_for_stage(stage_number: int) -> void:
	current_enemy_data = EnemyDatabaseResource.get_enemy_for_stage(stage_number)
	current_enemy_id = str(current_enemy_data.get("id", "training_dummy"))
	opponent_max_health = int(current_enemy_data.get("max_health", BattleConstants.STARTING_HEALTH))
	opponent_health = opponent_max_health
	opponent_block = 0
	opponent_mana_progress = float(current_enemy_data.get("starting_mana", 0.0))
	opponent_mana_regen = float(current_enemy_data.get("mana_regen", 1.0))
	opponent_max_mana = maxi(0, int(floor(opponent_mana_progress)))
	_sync_opponent_mana()
	opponent_turn_number = 0
	opponent_burn_stacks = 0
	opponent_burn_turns_remaining = 0
	resolving_turn = false

	if enemy_sprites_ref == null:
		return

	for child in enemy_sprites_ref.get_children():
		child.queue_free()

	var enemy_scene := BattleEnemySceneResolverResource.get_enemy_scene(current_enemy_data)
	enemy_target = enemy_scene.instantiate()
	enemy_sprites_ref.add_child(enemy_target)
	enemy_target.position = Vector2(1547, 525)
	if enemy_target.has_method("apply_enemy_data"):
		enemy_target.apply_enemy_data(current_enemy_id, current_enemy_data)


func _reset_player_state_for_new_stage() -> void:
	player_block = 0
	player_current_mana = 0
	player_max_mana = 1
	player_remaining_spell_actions = player_max_spell_actions
	pending_fuse_charges = 0
	BattlePathEffectsService.reset_for_new_stage(player_path_runtime)
	active_side = "player"
	resolving_turn = false
	combat_log_entries.clear()
	_clear_player_hand()
	_refresh_combat_log_overlay()


func _begin_new_stage_player_turn() -> void:
	resolving_turn = false
	active_side = "player"
	player_turn_number = 1
	opponent_turn_number = 0
	player_remaining_spell_actions = player_max_spell_actions
	pending_fuse_charges = 0
	player_current_mana = player_mana_regen
	player_max_mana = max(player_max_mana, player_current_mana)

	if deck_ref and deck_ref.has_method("draw_starting_hand"):
		deck_ref.draw_starting_hand()

	_set_end_turn_enabled(true)
	_log_message("Player turn %d." % player_turn_number)
	_update_hud()


func _clear_player_hand() -> void:
	var card_manager_ref := get_node_or_null("../CardManager")
	if card_manager_ref and card_manager_ref.has_method("clear_card_hover"):
		card_manager_ref.clear_card_hover()

	if player_hand_ref == null or not player_hand_ref.has_method("get_cards"):
		return

	for card in player_hand_ref.get_cards():
		if card == null or not is_instance_valid(card):
			continue
		if player_hand_ref.has_method("remove_card_from_hand"):
			player_hand_ref.remove_card_from_hand(card)
		card.queue_free()


func _get_current_enemy_name() -> String:
	return str(current_enemy_data.get("name", "Enemy"))


func _sync_opponent_mana() -> void:
	opponent_current_mana = maxi(0, int(floor(opponent_mana_progress)))
	opponent_max_mana = max(opponent_max_mana, opponent_current_mana)


func _has_path(path_id: String) -> bool:
	return BattlePathEffectsService.has_path(player_path_runtime, path_id)


func _modify_drawn_player_card(card_id: String, base_card_data: Dictionary) -> Dictionary:
	return BattlePathEffectsService.modify_drawn_card(player_path_runtime, card_id, base_card_data)


func _get_deck_view_card_ids(base_card_ids: Array[String]) -> Array[String]:
	return BattlePathEffectsService.get_deck_view_card_ids(player_path_runtime, base_card_ids)


func _get_deck_view_card_data(card_id: String, base_card_data: Dictionary) -> Dictionary:
	return BattlePathEffectsService.decorate_card_data(player_path_runtime, card_id, base_card_data)


func _apply_path_text_to_card(card: Node2D) -> void:
	if card == null or not is_instance_valid(card):
		return

	var card_id := str(card.get_meta("card_id", ""))
	var card_data: Dictionary = card.get_meta("card_data", {})
	if card_data.is_empty():
		return

	var updated_card_data := BattlePathEffectsService.decorate_card_data(player_path_runtime, card_id, card_data)
	if card.has_method("apply_card_data"):
		card.apply_card_data(card_id, updated_card_data)


func _refresh_player_hand_path_cards(excluded_card: Node2D = null) -> void:
	if player_hand_ref == null or not player_hand_ref.has_method("get_cards"):
		return

	for hand_card in player_hand_ref.get_cards():
		if hand_card == excluded_card or hand_card == null or not is_instance_valid(hand_card):
			continue
		_apply_path_text_to_card(hand_card)


func _apply_burn_to_target(target_key: String, amount: int) -> String:
	if amount <= 0:
		return ""

	if target_key == "opponent":
		var burn_state := BattlePathEffectsService.apply_enemy_burn(opponent_burn_stacks, opponent_burn_turns_remaining, amount)
		opponent_burn_stacks = int(burn_state.get("stacks", opponent_burn_stacks))
		opponent_burn_turns_remaining = int(burn_state.get("turns_remaining", opponent_burn_turns_remaining))
		return "%s gains %d Burn." % [_get_current_enemy_name(), amount]

	return ""


func _apply_turn_start_statuses(side: String) -> bool:
	if side != "opponent":
		return false

	var pending_burn_damage := opponent_burn_stacks if opponent_burn_stacks > 0 and opponent_burn_turns_remaining > 0 else 0
	if pending_burn_damage <= 0:
		return false

	var burn_resolution := BattleCombatResolver.apply_status_damage(
		"opponent",
		pending_burn_damage,
		{
			"player_health": player_health,
			"opponent_health": opponent_health,
			"player_block": player_block,
			"opponent_block": opponent_block,
			"player_ember_guard_active": BattlePathEffectsService.is_ember_guard_active(player_path_runtime),
		}
	)
	opponent_health = int(burn_resolution.get("opponent_health", opponent_health))
	opponent_block = int(burn_resolution.get("opponent_block", opponent_block))

	var burn_tick := BattlePathEffectsService.tick_enemy_burn(opponent_health, opponent_burn_stacks, opponent_burn_turns_remaining)
	opponent_burn_stacks = int(burn_tick.get("stacks", opponent_burn_stacks))
	opponent_burn_turns_remaining = int(burn_tick.get("turns_remaining", opponent_burn_turns_remaining))
	_log_message("%s takes %d burn damage." % [_get_current_enemy_name(), pending_burn_damage])
	_update_hud()
	return _is_battle_over()


func _compose_battle_message(primary_message: String, extra_messages: Array[String]) -> String:
	var parts: Array[String] = []
	if not primary_message.is_empty():
		parts.append(primary_message)
	for message in extra_messages:
		if not str(message).is_empty():
			parts.append(str(message))
	return " ".join(parts)


func _get_class_mechanics_text() -> String:
	return BattlePathEffectsService.get_class_mechanics_text(player_path_runtime)


func _get_opponent_ailments_text() -> String:
	if opponent_burn_stacks <= 0 or opponent_burn_turns_remaining <= 0:
		return ""

	return "Burn %d\n%d turn%s remaining" % [
		opponent_burn_stacks,
		opponent_burn_turns_remaining,
		"" if opponent_burn_turns_remaining == 1 else "s",
	]
