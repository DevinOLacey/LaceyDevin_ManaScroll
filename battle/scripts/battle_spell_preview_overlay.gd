extends CanvasLayer

signal preview_finished

const CARD_PREVIEW_SCENE = preload("res://cards/scenes/card_x_4_scale.tscn")
const BattleConstants = preload("res://shared/constants/battle_constants.gd")

@onready var preview_anchor: Control = $PreviewAnchor
@onready var backdrop: ColorRect = $PreviewAnchor/Backdrop
@onready var caster_label: Label = $PreviewAnchor/CasterLabel

var active_card_preview: Node2D
var active_tween: Tween
var base_preview_position := Vector2.ZERO


func _ready() -> void:
	base_preview_position = preview_anchor.position


func show_spell_preview(card_id: String, card_data: Dictionary, caster: String) -> void:
	visible = true
	_clear_active_preview()
	backdrop.color = Color(0.03, 0.05, 0.09, 0.0)
	preview_anchor.modulate = Color(1, 1, 1, 0)
	preview_anchor.scale = Vector2(0.82, 0.82)
	preview_anchor.position = base_preview_position + Vector2(0, 36)

	caster_label.text = "Player Cast" if caster == "player" else "Enemy Cast"
	caster_label.modulate = BattleConstants.SPELL_PREVIEW_PLAYER_TINT if caster == "player" else BattleConstants.SPELL_PREVIEW_OPPONENT_TINT

	active_card_preview = CARD_PREVIEW_SCENE.instantiate()
	preview_anchor.add_child(active_card_preview)
	active_card_preview.position = BattleConstants.SPELL_PREVIEW_CARD_CENTER_POSITION
	active_card_preview.set("registers_hover_signals", false)
	if active_card_preview.has_method("apply_card_data"):
		active_card_preview.apply_card_data(card_id, card_data)
	var collision: CollisionShape2D = active_card_preview.get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true

	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.set_parallel(true)
	active_tween.tween_property(backdrop, "color", Color(0.03, 0.05, 0.09, 0.34), BattleConstants.SPELL_PREVIEW_ENTRANCE_DURATION)
	active_tween.tween_property(preview_anchor, "modulate:a", 1.0, BattleConstants.SPELL_PREVIEW_ENTRANCE_DURATION)
	active_tween.tween_property(preview_anchor, "scale", Vector2.ONE, BattleConstants.SPELL_PREVIEW_ENTRANCE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(preview_anchor, "position", base_preview_position, BattleConstants.SPELL_PREVIEW_ENTRANCE_DURATION).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	await active_tween.finished

	await get_tree().create_timer(BattleConstants.SPELL_PREVIEW_HOLD_DURATION).timeout

	active_tween = create_tween()
	active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	active_tween.set_parallel(true)
	active_tween.tween_property(backdrop, "color", Color(0.03, 0.05, 0.09, 0.0), BattleConstants.SPELL_PREVIEW_EXIT_DURATION)
	active_tween.tween_property(preview_anchor, "modulate:a", 0.0, BattleConstants.SPELL_PREVIEW_EXIT_DURATION)
	active_tween.tween_property(preview_anchor, "scale", Vector2(1.08, 1.08), BattleConstants.SPELL_PREVIEW_EXIT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.tween_property(preview_anchor, "position", base_preview_position + Vector2(0, -18), BattleConstants.SPELL_PREVIEW_EXIT_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await active_tween.finished

	_clear_active_preview()
	visible = false
	preview_finished.emit()


func _clear_active_preview() -> void:
	if active_tween and is_instance_valid(active_tween):
		active_tween.kill()
	active_tween = null

	if active_card_preview and is_instance_valid(active_card_preview):
		active_card_preview.queue_free()
	active_card_preview = null
