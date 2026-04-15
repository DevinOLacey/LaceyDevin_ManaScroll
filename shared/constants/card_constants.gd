extends RefCounted

# Card text rendering
const TITLE_FONT_SIZE_REGULAR := 16
const TITLE_FONT_SIZE_SCALE_4 := 24
const TITLE_FONT_SIZE_SCALE_2 := 32
const COST_FONT_SIZE_REGULAR := 16
const COST_FONT_SIZE_SCALE_4 := 24
const COST_FONT_SIZE_SCALE_2 := 32
const TYPE_FONT_SIZE_REGULAR := 8
const TYPE_FONT_SIZE_SCALE_4 := 16
const TYPE_FONT_SIZE_SCALE_2 := 24
const DESCRIPTION_FONT_SIZE_REGULAR := 8
const DESCRIPTION_FONT_SIZE_SCALE_4 := 16
const DESCRIPTION_FONT_SIZE_SCALE_2 := 24
const DRAW_CHANCE_FONT_SIZE_REGULAR := 4
const DRAW_CHANCE_FONT_SIZE_SCALE_4 := 16

# Card animation and polish
const MANIFEST_START_OFFSET := Vector2(0, 48)
const MANIFEST_START_SCALE := Vector2(0.35, 0.35)
const MANIFEST_MOTE_COUNT := 14
const MANIFEST_COLORS := [
	Color(0.52, 0.93, 1.0, 0.95),
	Color(0.7, 0.55, 1.0, 0.9),
	Color(0.95, 0.98, 1.0, 0.95),
]

# Card content helpers
const LABEL_Z_INDEX := 5
const MIN_AUTO_FIT_FONT_SIZE := 4
const LABEL_NAMES := ["Name", "Cost", "Type", "Description", "DrawChance"]
const VISIBLE_SPRITE_PATHS := ["Frame", "Art", "Sprite2D", "Sprite2D/Sprite2D"]

# Card manager and targeting
const MANAGER_COLLISION_MASK := 1
const MANAGER_COLLISION_MASK_TARGET := 8
const DEFAULT_DRAW_SPEED := 0.1
const RETURN_TO_HAND_SPEED := 0.1
const CARD_BOTTOM_OFFSET := 144.0
const DRAG_Z_INDEX := 20
const CARD_REMOVING_META := "card_removing"

# Hand layout and draw pacing
const MAX_HAND_SIZE := 7
const CARD_WIDTH := 200
const HAND_Y_POSITION := 890
const MANIFEST_DRAW_SPEED := 1.0
const STARTING_HAND_BASE_DELAY := 0.08
const STARTING_HAND_DELAY_VARIANCE := 0.07
const DRAW_STAGGER_DELAY := 0.08

# Hand selection overlay
const SELECTION_ROW_Y := 400.0
const SELECTION_LAYOUT_SPEED := 0.15
const SELECTION_BASE_SCALE := Vector2.ONE
const SELECTION_SELECTED_SCALE := Vector2(1.2, 1.2)
const SELECTION_DISABLED_MODULATE := Color(1, 1, 1, 0.35)
const SELECTION_ENABLED_MODULATE := Color(1, 1, 1, 1)
