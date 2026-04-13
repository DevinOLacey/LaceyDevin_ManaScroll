extends RefCounted
class_name BattleEnemySceneResolver

const FALLBACK_SCENE = preload("res://scenes/enemy.tscn")


static func get_enemy_scene(enemy_data: Dictionary) -> PackedScene:
	var scene_path := str(enemy_data.get("scene_path", ""))
	if scene_path.is_empty():
		return FALLBACK_SCENE

	var resolved_scene := load(scene_path) as PackedScene
	if resolved_scene != null:
		return resolved_scene
	return FALLBACK_SCENE
