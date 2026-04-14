extends Node2D

const DEFAULT_POSE := &"default"
const CHANNEL_POSE := &"channel"
const MANA_BOLT_POSE := &"manaBolt"
const MANA_SHIELD_POSE := &"manaShield"
const CAST_POSE_DURATION := 0.8

var spell_drag_active := false
var cast_pose_active := false
var cast_pose_name: StringName = DEFAULT_POSE
var cast_request_id := 0


func set_spell_drag_active(active: bool) -> void:
	spell_drag_active = active
	_refresh_pose()


func play_cast_animation(card_id: String, card_data: Dictionary) -> void:
	var next_pose := _get_cast_pose_name(card_id, card_data)
	cast_request_id += 1
	cast_pose_name = next_pose
	cast_pose_active = true
	_refresh_pose()
	_finish_cast_pose_later(cast_request_id)


func _finish_cast_pose_later(request_id: int) -> void:
	await get_tree().create_timer(CAST_POSE_DURATION).timeout
	if request_id != cast_request_id:
		return
	cast_pose_active = false
	_refresh_pose()


func _refresh_pose() -> void:
	var next_pose := DEFAULT_POSE
	if cast_pose_active:
		next_pose = cast_pose_name
	elif spell_drag_active:
		next_pose = CHANNEL_POSE

	_show_pose(next_pose)


func _show_pose(pose_name: StringName) -> void:
	var pose_sprites := {
		DEFAULT_POSE: get_node_or_null("default") as Sprite2D,
		CHANNEL_POSE: get_node_or_null("channel") as Sprite2D,
		MANA_BOLT_POSE: get_node_or_null("manaBolt") as Sprite2D,
		MANA_SHIELD_POSE: get_node_or_null("manaShield") as Sprite2D,
	}
	for named_pose in pose_sprites.keys():
		var pose_sprite: Sprite2D = pose_sprites[named_pose]
		if pose_sprite:
			pose_sprite.visible = named_pose == pose_name


func _get_cast_pose_name(card_id: String, card_data: Dictionary) -> StringName:
	if _is_bolt_spell(card_id, card_data):
		return MANA_BOLT_POSE
	if _is_shield_spell(card_id, card_data):
		return MANA_SHIELD_POSE
	return DEFAULT_POSE


func _is_bolt_spell(card_id: String, card_data: Dictionary) -> bool:
	var normalized_id := str(card_id).to_lower()
	var fusion_match_id := str(card_data.get("fusion_match_id", "")).to_lower()
	var card_name := str(card_data.get("name", "")).to_lower()
	return normalized_id.ends_with("bolt") or fusion_match_id.ends_with("bolt") or card_name.contains("bolt")


func _is_shield_spell(card_id: String, card_data: Dictionary) -> bool:
	var normalized_id := str(card_id).to_lower()
	var fusion_match_id := str(card_data.get("fusion_match_id", "")).to_lower()
	var card_name := str(card_data.get("name", "")).to_lower()
	return (
		normalized_id == "mana_shield"
		or fusion_match_id == "ember_shield"
		or fusion_match_id == "frost_armor"
		or card_name == "mana shield"
		or card_name == "ember shield"
		or card_name == "frost armor"
	)
