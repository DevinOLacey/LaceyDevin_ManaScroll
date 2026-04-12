extends RefCounted
class_name CardDatabase

const CARD_DEFINITIONS := {
	"mana_bolt": {
		"name": "Mana Bolt",
		"art": "res://cards/art/Mana Bolt.png",
		"cost": 0,
		"category": "spell",
		"target_group": "enemy",
		"type": "[b]Spell[/b]",
		"damage": 3,
		"effect": null,
		"description": "Shoot a projectile of concentrated mana dealing [i][b]3[/b] damage[/i]",
	},
	"mana_shield": {
		"name": "Mana Shield",
		"art": "res://cards/art/Mana Shield.png",
		"cost": 0,
		"category": "spell",
		"target_group": "ally",
		"type": "[b]Spell[/b]",
		"block": 2,
		"effect": null,
		"description": "Emit a shield of pure mana [i]blocking [b]2[/b][/i] damage",
	},
	"fuse_mana": {
		"name": "Fuse Mana",
		"art": "res://cards/art/Fuse Mana.png",
		"cost": 1,
		"category": "enchantment",
		"target_group": "self",
		"type": "[b]Enchant[/b]",
		"effect": "combine",
		"description": "Fuse the mana of 2 of the same spell together",
	},
	"accelerate_mana_gates": {
		"name": "Accelerate Mana Gates",
		"art": "res://cards/art/Fuse Mana.png",
		"cost": 3,
		"category": "spell",
		"target_group": "self",
		"type": "[b]Spell[/b]",
		"effect": "accelerate_mana_gates",
		"description": "Overclock your mana gates and gain [i][b]1[/b] extra spell action[/i] for the rest of combat",
	},
	"unstable_discharge": {
		"name": "Unstable Discharge",
		"art": "res://cards/art/Mana Bolt.png",
		"cost": 2,
		"category": "spell",
		"target_group": "self",
		"type": "[b]Spell[/b]",
		"effect": "unstable_discharge",
		"description": "Charge the battlefield. Your Mana Bolts deal [i][b]+1[/b][/i] damage and Mana Shields give [i][b]+1[/b][/i] block for the rest of combat",
	},
	"splinter_bolt": {
		"name": "Splinter Bolt",
		"art": "res://cards/art/Splinter Bolt.png",
		"cost": 0,
		"category": "spell",
		"target_group": "enemy",
		"type": "[b]Spell[/b]",
		"damage": 2,
		"effect": null,
		"description": "Launch a sharpened splinter dealing [i][b]2[/b] damage[/i]",
	},
	"wooden_ward": {
		"name": "Wooden Ward",
		"art": "res://cards/art/Wooden Ward.png",
		"cost": 0,
		"category": "spell",
		"target_group": "ally",
		"type": "[b]Spell[/b]",
		"block": 1,
		"effect": null,
		"description": "Raise a simple bark ward [i]blocking [b]1[/b][/i] damage",
	},
	"bramble_snap": {
		"name": "Bramble Snap",
		"art": "res://cards/art/Splinter Bolt.png",
		"cost": 0,
		"category": "spell",
		"target_group": "enemy",
		"type": "[b]Spell[/b]",
		"damage": 2,
		"effect": null,
		"description": "Whip thorned brambles across the target for [i][b]2[/b] damage[/i]",
	},
	"thick_bark": {
		"name": "Thick Bark",
		"art": "res://cards/art/Wooden Ward.png",
		"cost": 0,
		"category": "spell",
		"target_group": "ally",
		"type": "[b]Spell[/b]",
		"block": 2,
		"effect": null,
		"description": "Layer rough bark over the caster [i]blocking [b]2[/b][/i] damage",
	},
	"sap_mend": {
		"name": "Sap Mend",
		"art": "res://cards/art/Wooden Ward.png",
		"cost": 1,
		"category": "spell",
		"target_group": "self",
		"type": "[b]Spell[/b]",
		"heal": 4,
		"effect": null,
		"description": "Seal the cracks with glowing sap and [i]heal [b]4[/b][/i] health",
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
