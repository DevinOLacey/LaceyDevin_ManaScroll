extends RefCounted
class_name CardDatabase

const CARD_DEFINITIONS := {
	"mana_bolt": {
		"name": "Mana Bolt",
		"art": "res://cards/art/Mana Bolt.png",
		"cost": 0,
		"type": "[b]Spell[/b]",
		"damage": 3,
		"effect": null,
		"description": "Shoot a projectile of concentrated mana dealing [i][b]3[/b] damage[/i]",
	},
	"mana_shield": {
		"name": "Mana Shield",
		"art": "res://cards/art/Mana Shield.png",
		"cost": 0,
		"type": "[b]Spell[/b]",
		"block": 2,
		"effect": null,
		"description": "Emit a shield of pure mana [i]blocking [b]2[/b][/i] damage",
	},
	"fuse_mana": {
		"name": "Fuse Mana",
		"art": "res://cards/art/Fuse Mana.png",
		"cost": 1,
		"type": "[b]Enchant[/b]",
		"effect": "combine",
		"description": "Fuse 2 spells together",
	}
}

const CARD_DRAW_WEIGHTS := {
	"mana_bolt": 0.43,
	"mana_shield": 0.43,
	"fuse_mana": 0.15
}


static func get_card_definitions() -> Dictionary:
	return CARD_DEFINITIONS.duplicate(true)


static func get_card_draw_weights() -> Dictionary:
	return CARD_DRAW_WEIGHTS.duplicate()
