extends RefCounted
class_name EnemyDatabase

const ENEMY_DEFINITIONS := {
	"training_dummy": {
		"name": "Training Dummy",
		"art": "res://battle/art/actors/training_dummy.png",
		"scene_path": "res://scenes/enemies/training_dummy_enemy.tscn",
		"max_health": 3,
		"starting_mana": 0,
		"mana_regen": 0,
		"scale": Vector2(2.0, 2.0),
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"defensive_spell_id": "wooden_ward",
		"deck_weights": {
			"splinter_bolt": 0.78,
			"wooden_ward": 0.22,
		},
	},
	"bramble_husk": {
		"name": "Bramble Husk",
		"art": "res://battle/art/actors/bramble_husk.png",
		"scene_path": "res://scenes/enemies/bramble_husk_enemy.tscn",
		"max_health": 22,
		"starting_mana": 0.0,
		"mana_regen": 0.5,
		"scale": Vector2(2.1, 2.1),
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"defensive_spell_id": "thick_bark",
		"deck_weights": {
			"bramble_snap": 0.45,
			"thick_bark": 0.45,
			"sap_mend": 0.10,
		},
	},
	"ember_dummy": {
		"name": "Ember Dummy",
		"art": "res://battle/art/actors/training_dummy.png",
		"scene_path": "res://scenes/enemies/ember_dummy_enemy.tscn",
		"max_health": 16,
		"starting_mana": 1,
		"mana_regen": 2,
		"scale": Vector2(1.9, 1.9),
		"tint": Color(1.0, 0.72, 0.66, 1.0),
		"deck_weights": {
			"mana_bolt": 0.8,
			"mana_shield": 0.2,
		},
	},
}

const STAGE_ENEMIES := {
	1: "training_dummy",
	2: "bramble_husk",
	3: "ember_dummy",
}


static func get_enemy_definition(enemy_id: String) -> Dictionary:
	return ENEMY_DEFINITIONS.get(enemy_id, {}).duplicate(true)


static func get_enemy_for_stage(stage_number: int) -> Dictionary:
	var enemy_id := str(STAGE_ENEMIES.get(stage_number, "training_dummy"))
	var enemy_data := get_enemy_definition(enemy_id)
	enemy_data["id"] = enemy_id
	return enemy_data
