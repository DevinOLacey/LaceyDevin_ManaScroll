extends Node2D

const CombatCardDatabase = preload("res://cards/data/card_database.gd")
const BattleCombatResolver = preload("res://battle/scripts/battle_combat_resolver.gd")
const BattleEnemyAI = preload("res://battle/scripts/battle_enemy_ai.gd")
const BattleFusionService = preload("res://battle/scripts/battle_fusion_service.gd")
const BattleTargeting = preload("res://battle/scripts/battle_targeting.gd")
const BattleUIPresenter = preload("res://battle/scripts/battle_ui_presenter.gd")
const EnemyDatabaseResource = preload("res://battle/data/enemy_database.gd")
const SELECT_FROM_HAND_SCENE = preload("res://cards/scenes/select_from_hand.tscn")
const ENEMY_SCENE = preload("res://scenes/enemy.tscn")
const DEFEAT_SCENE_PATH := "res://ui/scenes/defeat_menu.tscn"

const STARTING_HEALTH := 20
const AI_ACTION_DELAY := 0.8
const PLAYER_DEATH_ANIMATION_LEAD_TIME := 0.0
const DEFEAT_TRANSITION_FADE_DURATION := 0.35

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
var player_spell_actions_container: HBoxContainer
var opponent_name_label: Label
var opponent_health_value_label: Label
var opponent_health_bar: ProgressBar
var opponent_block_label: Label
var opponent_spell_actions_container: HBoxContainer
var battle_log_label: Label
var selection_scene_ref: Node2D
var combat_log_canvas_layer: CanvasLayer
var combat_log_entries_container: VBoxContainer
var combat_log_scroll_container: ScrollContainer
var defeat_transition_layer: CanvasLayer
var defeat_transition_rect: ColorRect
var combat_log_entries: Array[Dictionary] = []

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
var player_health := STARTING_HEALTH
var opponent_max_health := STARTING_HEALTH
var opponent_health := STARTING_HEALTH
var current_stage_number := 1
var player_block := 0
var opponent_block := 0
var player_max_spell_actions := 1
var player_remaining_spell_actions := 1
var opponent_max_spell_actions := 1
var opponent_remaining_spell_actions := 1
var pending_fuse_charges := 0
var active_side := "player"
var resolving_turn := false
var current_enemy_id := ""
var current_enemy_data: Dictionary = {}

var card_definitions := CombatCardDatabase.get_card_definitions()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	battle_timer = $"../BattleTimer"
	battle_timer.one_shot = true
	battle_timer.wait_time = AI_ACTION_DELAY
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
	player_spell_actions_container = $"../PlayerVitalsPanel/PlayerVitalsMargin/PlayerVitalsVBox/PlayerSpellActions"
	opponent_name_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentNameLabel"
	opponent_health_value_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentHealthValueLabel"
	opponent_health_bar = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentHealthRow/OpponentHealthBar"
	opponent_block_label = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentHealthRow/OpponentBlockLabel"
	opponent_spell_actions_container = $"../OpponentVitalsPanel/OpponentVitalsMargin/OpponentVitalsVBox/OpponentSpellActions"
	battle_log_label = $"../BattleLogLabel"
	combat_log_canvas_layer = $"../CombatLogOverlay"
	combat_log_entries_container = $"../CombatLogOverlay/CombatLogPanel/CombatLogMargin/CombatLogVBox/CombatLogScroll/CombatLogScrollMargin/CombatLogEntries"
	combat_log_scroll_container = $"../CombatLogOverlay/CombatLogPanel/CombatLogMargin/CombatLogVBox/CombatLogScroll"
	defeat_transition_layer = get_node_or_null("../DefeatTransitionLayer")
	defeat_transition_rect = get_node_or_null("../DefeatTransitionLayer/DefeatFade")
	player_target = $"../PlayerSide/PlayerSprites/Player"
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
	var card_name := str(card_data.get("name", card.name))

	if total_cost > player_current_mana:
		_log_message("You do not have enough mana for that spell.")
		_update_hud()
		return false

	player_current_mana -= total_cost
	player_remaining_spell_actions = maxi(0, player_remaining_spell_actions - 1)
	_resolve_spell_effect(card_data, "player", target, effect_multiplier)

	_discard_player_card(card)

	if effect_multiplier > 1:
		_log_message("%s fused %d matching spell(s)." % [card_name, effect_multiplier - 1])
	pending_fuse_charges = 0
	_update_hud()
	return true


func _resolve_spell_effect(card_data: Dictionary, caster: String, target: Node2D, multiplier: int = 1) -> void:
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
			"player_max_health": STARTING_HEALTH,
			"player_block": player_block,
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
	_append_combat_log(
		card_data,
		caster,
		target_name,
		int(resolution.get("damage_done", 0)),
		int(resolution.get("block_done", 0)),
		int(resolution.get("heal_done", 0))
	)
	_log_message(str(resolution.get("log_message", "")))

	_update_hud()


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
		_resolve_spell_effect(card_data, "opponent", BattleTargeting.get_default_target_for_opponent(card_data, player_target, enemy_target))
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
		player_current_mana = max(player_current_mana, 1)
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


func _discard_player_card(card: Node2D) -> void:
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
			"player_spell_actions_container": player_spell_actions_container,
			"opponent_name_label": opponent_name_label,
			"opponent_health_value_label": opponent_health_value_label,
			"opponent_health_bar": opponent_health_bar,
			"opponent_block_label": opponent_block_label,
			"opponent_spell_actions_container": opponent_spell_actions_container,
		},
		{
			"active_side": active_side,
			"enemy_name": _get_current_enemy_name(),
			"player_turn_number": player_turn_number,
			"player_current_mana": player_current_mana,
			"opponent_current_mana": opponent_current_mana,
			"player_health": player_health,
			"starting_health": STARTING_HEALTH,
			"player_level": player_level,
			"player_mana_regen": player_mana_regen,
			"current_stage_number": current_stage_number,
			"player_block": player_block,
			"player_remaining_spell_actions": player_remaining_spell_actions,
			"player_max_spell_actions": player_max_spell_actions,
			"opponent_health": opponent_health,
			"opponent_max_health": opponent_max_health,
			"opponent_block": opponent_block,
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
		return true

	return false


func _show_defeat_screen() -> void:
	await _play_defeat_transition()
	get_tree().change_scene_to_file(DEFEAT_SCENE_PATH)


func _play_defeat_transition() -> void:
	if PLAYER_DEATH_ANIMATION_LEAD_TIME > 0.0:
		await get_tree().create_timer(PLAYER_DEATH_ANIMATION_LEAD_TIME).timeout

	if defeat_transition_layer == null or defeat_transition_rect == null:
		return

	defeat_transition_layer.visible = true
	defeat_transition_rect.color = Color(0, 0, 0, 0)
	var tween := create_tween()
	tween.tween_property(defeat_transition_rect, "color", Color(0, 0, 0, 1), DEFEAT_TRANSITION_FADE_DURATION)
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


func _spawn_enemy_for_stage(stage_number: int) -> void:
	current_enemy_data = EnemyDatabaseResource.get_enemy_for_stage(stage_number)
	current_enemy_id = str(current_enemy_data.get("id", "training_dummy"))
	opponent_max_health = int(current_enemy_data.get("max_health", STARTING_HEALTH))
	opponent_health = opponent_max_health
	opponent_block = 0
	opponent_mana_progress = float(current_enemy_data.get("starting_mana", 0.0))
	opponent_mana_regen = float(current_enemy_data.get("mana_regen", 1.0))
	opponent_max_mana = maxi(0, int(floor(opponent_mana_progress)))
	_sync_opponent_mana()
	opponent_turn_number = 0

	if enemy_sprites_ref == null:
		return

	for child in enemy_sprites_ref.get_children():
		child.queue_free()

	enemy_target = ENEMY_SCENE.instantiate()
	enemy_sprites_ref.add_child(enemy_target)
	enemy_target.position = Vector2(1547, 437)
	if enemy_target.has_method("apply_enemy_data"):
		enemy_target.apply_enemy_data(current_enemy_id, current_enemy_data)


func _get_current_enemy_name() -> String:
	return str(current_enemy_data.get("name", "Enemy"))


func _sync_opponent_mana() -> void:
	opponent_current_mana = maxi(0, int(floor(opponent_mana_progress)))
	opponent_max_mana = max(opponent_max_mana, opponent_current_mana)
