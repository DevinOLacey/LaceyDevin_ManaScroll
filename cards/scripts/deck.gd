extends Node2D

const DRAW_SPEED = 0.2
const CARD_SCENE_PATHS = {
	"mana_bolt": "res://cards/card_scenes/mana_bolt.tscn",
	"mana_shield": "res://cards/card_scenes/mana_shield.tscn",
}

var player_deck = [
	"mana_bolt", "mana_bolt", "mana_bolt", "mana_bolt", "mana_bolt",
	"mana_shield", "mana_shield", "mana_shield", "mana_shield", "mana_shield",
]
var player_hand_ref

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()
	player_deck.shuffle()
	player_hand_ref = $"../PlayerHand"


func draw_card():
	if player_hand_ref and player_hand_ref.is_hand_full():
		return

	if player_deck.is_empty():
		return

	var card_drawn = player_deck[0]
	player_deck.remove_at(0)
	
	if player_deck.size() == 0:
		$Area2D/CollisionShape2D.disabled = true
		$Sprite2D.visible = false
	
	var card_scene_path = CARD_SCENE_PATHS.get(card_drawn)
	if card_scene_path == null:
		push_error("Unknown card scene: %s" % card_drawn)
		return

	var card_scene = load(card_scene_path)
	var new_card = card_scene.instantiate()
	$"../CardManager".add_child(new_card)
	new_card.name = card_drawn
	player_hand_ref.add_card_to_hand(new_card, DRAW_SPEED)
