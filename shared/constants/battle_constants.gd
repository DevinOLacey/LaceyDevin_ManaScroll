extends RefCounted

# Battle flow and scene navigation
const DEFEAT_SCENE_PATH := "res://ui/scenes/defeat_menu.tscn"
const STARTING_HEALTH := 20
const AI_ACTION_DELAY := 0.8
const PLAYER_DEATH_ANIMATION_LEAD_TIME := 0.0
const ENEMY_DEFEAT_MODAL_DELAY := 0.5
const DEFEAT_TRANSITION_FADE_DURATION := 0.35

# Path ids and unlock card visibility
const PATH_OF_FLAME := "path_of_flame"
const PATH_OF_ENERGY := "path_of_energy"
const PATH_OF_FROST := "path_of_frost"
const FLAME_DECK_VIEW_CARD_IDS := ["flame_bolt", "ember_shield"]
const ENERGY_DECK_VIEW_CARD_IDS := ["accelerate_mana_gates", "unstable_discharge"]
const FROST_DECK_VIEW_CARD_IDS := ["ice_bolt", "frost_armor"]
const LEVEL_UP_OPTIONS := [
	{
		"id": PATH_OF_FLAME,
		"title": "The Path of Flame",
		"subtitle": "Embrace the Fire and scorch your path forward.",
		"accent": Color(0.96, 0.47, 0.27, 1.0),
	},
	{
		"id": PATH_OF_ENERGY,
		"title": "The Path of Energy",
		"subtitle": "Channel the power of Lighting to charge your power to greater heights.",
		"accent": Color(0.38, 0.047, 1.0, 1.0),
	},
	{
		"id": PATH_OF_FROST,
		"title": "The Path of Frost",
		"subtitle": "Lean into the cold current and steady your power.",
		"accent": Color(0.318, 0.91, 1.0, 1.0),
	},
]

# Fire path tuning
const FIRE_FLAME_THRESHOLD := 2
const FIRE_EMBER_THRESHOLD := 5
const FIRE_BURN_DURATION := 3

# Energy path tuning
const ENERGY_CHARGE_THRESHOLD := 10
const ENERGY_SHOCK_THRESHOLD := 4
const ENERGY_ACCELERATE_MANA_GATES_CARD_ID := "accelerate_mana_gates"
const ENERGY_UNSTABLE_DISCHARGE_CARD_ID := "unstable_discharge"

# Frost path tuning
const FROST_FROST_THRESHOLD := 2
const FROST_CHILL_THRESHOLD := 3

# Spell preview overlay
const SPELL_PREVIEW_ENTRANCE_DURATION := 0.18
const SPELL_PREVIEW_HOLD_DURATION := 1.0
const SPELL_PREVIEW_EXIT_DURATION := 0.2
const SPELL_PREVIEW_PLAYER_TINT := Color(0.68, 0.9, 1.0, 1.0)
const SPELL_PREVIEW_OPPONENT_TINT := Color(1.0, 0.75, 0.75, 1.0)
const SPELL_PREVIEW_CARD_CENTER_POSITION := Vector2(180, 292)

# Enemy presentation
const ENEMY_DEFEAT_ANIMATION_DURATION := 0.4
const ENEMY_DEFEAT_DROP_DISTANCE := 26.0

# Input helpers
const INPUT_COLLISION_MASK_CARD := 1
const INPUT_COLLISION_MASK_CARD_DECK := 4
const DECK_VIEW_CARD_META := "deck_view_card"
