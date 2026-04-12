extends Node2D

signal defeat_animation_finished

const DEFEAT_ANIMATION_DURATION := 0.4
const DEFEAT_DROP_DISTANCE := 26.0

var enemy_id := ""
var enemy_data: Dictionary = {}
var defeat_animation_played := false


func apply_enemy_data(next_enemy_id: String, next_enemy_data: Dictionary) -> void:
	enemy_id = next_enemy_id
	enemy_data = next_enemy_data.duplicate(true)
	set_meta("enemy_id", enemy_id)
	set_meta("enemy_data", enemy_data.duplicate(true))

	var sprite: Sprite2D = $Sprite2D
	var art_path := str(enemy_data.get("art", ""))

	if not art_path.is_empty():
		var texture := load(art_path) as Texture2D
		if texture:
			sprite.texture = texture

	sprite.modulate = enemy_data.get("tint", Color(1, 1, 1, 1))
	scale = enemy_data.get("scale", Vector2(2.0, 2.0))


func get_enemy_name() -> String:
	return str(enemy_data.get("name", "Enemy"))


func play_defeat_animation() -> void:
	if defeat_animation_played:
		return

	defeat_animation_played = true
	var sprite: Sprite2D = $Sprite2D
	if sprite == null:
		defeat_animation_finished.emit()
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", position + Vector2(0, DEFEAT_DROP_DISTANCE), DEFEAT_ANIMATION_DURATION)
	tween.tween_property(self, "scale", scale * Vector2(1.08, 0.92), DEFEAT_ANIMATION_DURATION)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.55, 0.55, 0.0), DEFEAT_ANIMATION_DURATION)
	await tween.finished
	defeat_animation_finished.emit()
