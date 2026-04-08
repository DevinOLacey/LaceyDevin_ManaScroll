extends Node2D

var enemy_id := ""
var enemy_data: Dictionary = {}


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
