extends Node2D

signal defeat_animation_finished

const ACTION_POSE_DURATION := 0.8
const DEATH_POSE_HOLD_DURATION := 0.8
const DEFAULT_POSE := &"default"
const ATTACKING_POSE := &"attacking"
const DEFENDING_POSE := &"defending"
const DEATH_POSE := &"death"
const BattleConstants = preload("res://shared/constants/battle_constants.gd")

var enemy_id := ""
var enemy_data: Dictionary = {}
var defeat_animation_played := false
var pose_reset_request_id := 0
var current_pose: StringName = DEFAULT_POSE


func apply_enemy_data(next_enemy_id: String, next_enemy_data: Dictionary) -> void:
	enemy_id = next_enemy_id
	enemy_data = next_enemy_data.duplicate(true)
	set_meta("enemy_id", enemy_id)
	set_meta("enemy_data", enemy_data.duplicate(true))

	var art_path := str(enemy_data.get("art", ""))
	var sprites := _get_pose_sprites()

	if sprites.size() == 1 and not art_path.is_empty():
		var texture := load(art_path) as Texture2D
		if texture:
			sprites[0].texture = texture

	for sprite in sprites:
		sprite.modulate = enemy_data.get("tint", Color(1, 1, 1, 1))
	scale = enemy_data.get("scale", Vector2(2.0, 2.0))
	defeat_animation_played = false
	_show_pose(DEFAULT_POSE)


func get_enemy_name() -> String:
	return str(enemy_data.get("name", "Enemy"))


func play_attack_pose() -> void:
	_play_temporary_pose(ATTACKING_POSE)


func play_defend_pose() -> void:
	_play_temporary_pose(DEFENDING_POSE)


func play_defeat_animation() -> void:
	if defeat_animation_played:
		return

	defeat_animation_played = true
	var sprite := _get_visual_sprite()
	if sprite == null:
		defeat_animation_finished.emit()
		return

	_show_pose(DEATH_POSE)
	await get_tree().create_timer(DEATH_POSE_HOLD_DURATION).timeout
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, BattleConstants.ENEMY_DEFEAT_DROP_DISTANCE), BattleConstants.ENEMY_DEFEAT_ANIMATION_DURATION)
	tween.tween_property(self, "scale", scale * Vector2(1.08, 0.92), BattleConstants.ENEMY_DEFEAT_ANIMATION_DURATION)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.55, 0.55, 0.0), BattleConstants.ENEMY_DEFEAT_ANIMATION_DURATION)
	await tween.finished
	defeat_animation_finished.emit()


func _play_temporary_pose(pose_name: StringName) -> void:
	if defeat_animation_played:
		return
	if not _has_pose(pose_name):
		_show_pose(DEFAULT_POSE)
		return

	pose_reset_request_id += 1
	var request_id := pose_reset_request_id
	_show_pose(pose_name)
	_reset_pose_later(request_id)


func _reset_pose_later(request_id: int) -> void:
	await get_tree().create_timer(ACTION_POSE_DURATION).timeout
	if request_id != pose_reset_request_id or defeat_animation_played:
		return
	_show_pose(DEFAULT_POSE)


func _show_pose(pose_name: StringName) -> void:
	current_pose = pose_name
	var pose_sprites := {
		DEFAULT_POSE: get_node_or_null("default") as Sprite2D,
		ATTACKING_POSE: get_node_or_null("attacking") as Sprite2D,
		DEFENDING_POSE: get_node_or_null("defending") as Sprite2D,
		DEATH_POSE: get_node_or_null("death") as Sprite2D,
	}
	var has_named_pose := false
	for named_pose in pose_sprites.keys():
		var pose_sprite: Sprite2D = pose_sprites[named_pose]
		if pose_sprite != null:
			has_named_pose = true
			pose_sprite.visible = named_pose == pose_name

	if has_named_pose:
		if pose_name != DEATH_POSE and pose_sprites[pose_name] == null and pose_sprites[DEFAULT_POSE] != null:
			pose_sprites[DEFAULT_POSE].visible = true
		return

	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.visible = true


func _has_pose(pose_name: StringName) -> bool:
	return get_node_or_null(String(pose_name)) is Sprite2D


func _get_visual_sprite() -> Sprite2D:
	var active_pose := get_node_or_null(String(current_pose)) as Sprite2D
	if active_pose:
		return active_pose
	var default_pose := get_node_or_null("default") as Sprite2D
	if default_pose:
		return default_pose
	return get_node_or_null("Sprite2D") as Sprite2D


func _get_pose_sprites() -> Array[Sprite2D]:
	var sprites: Array[Sprite2D] = []
	for pose_name in [DEFAULT_POSE, ATTACKING_POSE, DEFENDING_POSE, DEATH_POSE]:
		var pose_sprite := get_node_or_null(String(pose_name)) as Sprite2D
		if pose_sprite:
			sprites.append(pose_sprite)
	if sprites.is_empty():
		var sprite := get_node_or_null("Sprite2D") as Sprite2D
		if sprite:
			sprites.append(sprite)
	return sprites
