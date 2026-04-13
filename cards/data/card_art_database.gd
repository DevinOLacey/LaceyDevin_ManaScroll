extends RefCounted
class_name CardArtDatabase

const PATH_VARIANT_ART := {
	"flame_bolt": "res://cards/art/Flame Bolt.png",
	"ember_shield": "res://cards/art/Ember Shield.png",
	"ice_bolt": "res://cards/art/Ice Bolt.png",
	"frost_armor": "res://cards/art/Frost Armor.png",
}


static func apply_variant_art(card_data: Dictionary, art_id: String) -> Dictionary:
	var updated_card_data := card_data.duplicate(true)
	var art_path := str(PATH_VARIANT_ART.get(art_id, ""))
	if not art_path.is_empty():
		updated_card_data["art"] = art_path
	return updated_card_data
