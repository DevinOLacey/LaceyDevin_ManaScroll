extends Node2D

const BattleConstants = preload("res://shared/constants/battle_constants.gd")
const DeckConstants = preload("res://shared/constants/deck_constants.gd")
const HOVER_PREVIEW_SCENE = preload("res://cards/scenes/card_x_4_scale.tscn")

var card_definitions := {}
var draw_weights := {}
var backdrop_ref: ColorRect
var hover_preview
var hovered_card_slot
var card_data_provider: Callable


func _ready() -> void:
	for card_slot: Node2D in get_card_slots():
		_prepare_card_slot(card_slot)


func _process(_delta: float) -> void:
	if hovered_card_slot != null and not _is_mouse_over_card_slot(hovered_card_slot):
		hovered_card_slot = null
		_hide_hover_preview()


func configure(definitions: Dictionary, weights: Dictionary, backdrop: ColorRect) -> void:
	card_definitions = definitions.duplicate(true)
	draw_weights = weights.duplicate()
	backdrop_ref = backdrop


func set_card_data_provider(provider: Callable) -> void:
	card_data_provider = provider


func connect_card_signals(card) -> void:
	if card == null:
		return

	_connect_local_hover_signals(card)


func get_card_slots() -> Array[Node2D]:
	var card_slots: Array[Node2D] = []
	for child: Node in get_children():
		if child is Node2D and child.name.begins_with("Card"):
			card_slots.append(child)
	return card_slots


func show_cards(card_ids: Array[String]) -> void:
	var card_slots: Array[Node2D] = get_card_slots()
	for i in range(card_slots.size()):
		var card_slot: Node2D = card_slots[i]
		if i < card_ids.size():
			_populate_card_slot(card_slot, card_ids[i])
			card_slot.visible = true
		else:
			card_slot.visible = false

	_resize_backdrop()
	if backdrop_ref:
		backdrop_ref.visible = true
	visible = true


func hide_view() -> void:
	hovered_card_slot = null
	_hide_hover_preview()
	if backdrop_ref:
		backdrop_ref.visible = false
	visible = false


func _prepare_card_slot(card_slot: Node2D) -> void:
	card_slot.set_meta(BattleConstants.DECK_VIEW_CARD_META, true)

	if "registers_hover_signals" in card_slot:
		card_slot.registers_hover_signals = true

	var area: Area2D = card_slot.get_node_or_null("Area2D")
	if area:
		area.monitoring = true
		area.monitorable = true

	var collision: CollisionShape2D = card_slot.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = false

	for label_name in ["Name", "Cost", "Type", "Description", "DrawChance"]:
		var label: Control = card_slot.get_node_or_null(label_name)
		if label:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	connect_card_signals(card_slot)


func _populate_card_slot(card_slot: Node2D, card_name: String) -> void:
	var card_definition: Dictionary = card_definitions.get(card_name, {})
	if card_definition.is_empty():
		card_slot.visible = false
		return

	if card_data_provider.is_valid():
		var provided_card_data = card_data_provider.call(card_name, card_definition.duplicate(true))
		if provided_card_data is Dictionary and not provided_card_data.is_empty():
			card_definition = provided_card_data

	if card_slot.has_method("apply_card_data"):
		card_slot.apply_card_data(card_name, card_definition)
	_apply_draw_chance_label(card_slot, card_name)


func _apply_draw_chance_label(card_slot: Node2D, card_name: String) -> void:
	var draw_chance_text := "[b][i]Path card[/i][/b]"
	if draw_weights.has(card_name):
		var weight: float = float(draw_weights.get(card_name, 0.0))
		var total_weight: float = 0.0
		for weight_value in draw_weights.values():
			total_weight += float(weight_value)

		var chance_percent: float = 0.0
		if total_weight > 0.0:
			chance_percent = (weight / total_weight) * 100.0
		draw_chance_text = "[b][i]Draw chance: %.0f%%[/i][/b]" % chance_percent

	var draw_chance_label: RichTextLabel = card_slot.get_node_or_null("DrawChance")
	if draw_chance_label:
		draw_chance_label.set_meta("bbcode_source", draw_chance_text)
		draw_chance_label.bbcode_enabled = true
		draw_chance_label.clear()
		draw_chance_label.append_text(draw_chance_text)


func _resize_backdrop() -> void:
	if backdrop_ref == null:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	backdrop_ref.position = Vector2.ZERO
	backdrop_ref.size = viewport_size


func _connect_local_hover_signals(card_slot: Node2D) -> void:
	if not card_slot.is_connected("hovered", Callable(self, "_on_card_slot_hovered")):
		card_slot.connect("hovered", Callable(self, "_on_card_slot_hovered"))

	if not card_slot.is_connected("hovered_off", Callable(self, "_on_card_slot_unhovered")):
		card_slot.connect("hovered_off", Callable(self, "_on_card_slot_unhovered"))


func _on_card_slot_hovered(card_slot: Node2D) -> void:
	if hovered_card_slot == card_slot:
		return

	hovered_card_slot = card_slot
	_show_hover_preview(card_slot)


func _on_card_slot_unhovered(card_slot: Node2D) -> void:
	if hovered_card_slot == card_slot:
		call_deferred("_resolve_hover_exit", card_slot)


func _show_hover_preview(card_slot: Node2D) -> void:
	_hide_hover_preview()

	hover_preview = HOVER_PREVIEW_SCENE.instantiate()
	add_child(hover_preview)
	_copy_card_display(hover_preview, card_slot)
	_disable_preview_mouse_interactions(hover_preview)
	hover_preview.position = card_slot.position + DeckConstants.HOVER_PREVIEW_OFFSET
	hover_preview.z_index = 100


func _hide_hover_preview() -> void:
	if hover_preview:
		hover_preview.queue_free()
		hover_preview = null


func _copy_card_display(target_card: Node2D, source_card: Node2D) -> void:
	if target_card.has_method("copy_display_from"):
		target_card.copy_display_from(source_card)
		return

	var target_sprite: Sprite2D = target_card.get_node_or_null("Sprite2D")
	var source_sprite: Sprite2D = source_card.get_node_or_null("Sprite2D")
	if target_sprite and source_sprite:
		target_sprite.texture = source_sprite.texture

	for label_name in ["Name", "Cost", "Type", "Description"]:
		var target_label: RichTextLabel = target_card.get_node_or_null(label_name)
		var source_label: RichTextLabel = source_card.get_node_or_null(label_name)
		if target_label and source_label:
			target_label.text = source_label.text


func _resolve_hover_exit(card_slot: Node2D) -> void:
	if hovered_card_slot == card_slot:
		hovered_card_slot = null
		_hide_hover_preview()


func _is_mouse_over_card_slot(card_slot: Node2D) -> bool:
	if card_slot == null or not card_slot.visible:
		return false

	var collision: CollisionShape2D = card_slot.get_node_or_null("Area2D/CollisionShape2D")
	if collision == null or collision.shape == null:
		return false

	var rectangle_shape := collision.shape as RectangleShape2D
	if rectangle_shape == null:
		return false

	var local_mouse_position: Vector2 = collision.to_local(get_global_mouse_position())
	var card_rect := Rect2(-rectangle_shape.size / 2.0, rectangle_shape.size)
	return card_rect.has_point(local_mouse_position)


func _disable_preview_mouse_interactions(root_node: Node) -> void:
	if root_node == null:
		return

	if root_node is Area2D:
		var area: Area2D = root_node as Area2D
		area.monitoring = false
		area.monitorable = false

	if root_node is CollisionShape2D:
		var collision: CollisionShape2D = root_node as CollisionShape2D
		collision.disabled = true

	if root_node is Control:
		var control: Control = root_node as Control
		control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for child: Node in root_node.get_children():
		_disable_preview_mouse_interactions(child)
