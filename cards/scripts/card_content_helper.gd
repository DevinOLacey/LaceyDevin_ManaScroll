extends RefCounted

const LABEL_Z_INDEX = 5
const MIN_AUTO_FIT_FONT_SIZE = 4

const LABEL_NAMES = ["Name", "Cost", "Type", "Description", "DrawChance"]
const VISIBLE_SPRITE_PATHS = ["Frame", "Art", "Sprite2D", "Sprite2D/Sprite2D"]


static func apply_card_data(card: Node2D, card_id: String, card_data: Dictionary) -> void:
	card.set_meta("card_id", card_id)
	card.set_meta("card_data", card_data.duplicate(true))

	var name_text: String = str(card_data.get("name", card_id))
	var cost_text: String = str(card_data.get("cost", ""))
	var type_text: String = str(card_data.get("type", ""))
	var description_text: String = str(card_data.get("description", ""))
	var art_source = card_data.get("art", null)

	set_label_text(card, "Name", "[b]%s[/b]" % name_text)
	set_label_text(card, "Cost", "[b]%s[/b]" % cost_text)
	set_label_text(card, "Type", type_text)
	set_label_text(card, "Description", description_text)
	set_label_text(card, "DrawChance", "")
	set_art_texture(card, resolve_texture(art_source))


static func set_visuals_visible(card: Node2D, visible_state: bool) -> void:
	for sprite_path in VISIBLE_SPRITE_PATHS:
		var sprite: Sprite2D = card.get_node_or_null(sprite_path)
		if sprite:
			sprite.visible = visible_state

	for label_name in LABEL_NAMES:
		var label: RichTextLabel = card.get_node_or_null(label_name)
		if label:
			label.visible = visible_state


static func apply_text_font_sizes(card: Node2D, description_size_preset: int, font_sizes: Dictionary) -> void:
	apply_label_font_size(card.get_node_or_null("Name"), get_preset_font_size(description_size_preset, int(font_sizes.get("title_regular", 16)), int(font_sizes.get("title_scale_2", 32)), int(font_sizes.get("title_scale_4", 24))))
	apply_label_font_size(card.get_node_or_null("Cost"), get_preset_font_size(description_size_preset, int(font_sizes.get("cost_regular", 16)), int(font_sizes.get("cost_scale_2", 32)), int(font_sizes.get("cost_scale_4", 24))))
	apply_label_font_size(card.get_node_or_null("Type"), get_preset_font_size(description_size_preset, int(font_sizes.get("type_regular", 8)), int(font_sizes.get("type_scale_2", 24)), int(font_sizes.get("type_scale_4", 16))))
	apply_label_font_size(card.get_node_or_null("Description"), get_preset_font_size(description_size_preset, int(font_sizes.get("description_regular", 8)), int(font_sizes.get("description_scale_2", 24)), int(font_sizes.get("description_scale_4", 16))))


static func apply_label_z_index(card: Node2D) -> void:
	for label_name in LABEL_NAMES:
		var label: RichTextLabel = card.get_node_or_null(label_name)
		if label:
			label.z_index = LABEL_Z_INDEX


static func copy_display_from(target_card: Node2D, source_card: Node2D) -> void:
	_copy_sprite_branch(target_card, source_card)

	for label_name in LABEL_NAMES:
		var target_label: RichTextLabel = target_card.get_node_or_null(label_name)
		var source_label: RichTextLabel = source_card.get_node_or_null(label_name)
		if target_label and source_label:
			var label_text := get_label_source_text(source_label)
			set_label_bbcode(target_label, label_text)


static func auto_fit_all_labels(card: Node2D) -> void:
	var name_label: RichTextLabel = card.get_node_or_null("Name")
	if name_label:
		fit_label_to_height(name_label)

	var draw_chance_label: RichTextLabel = card.get_node_or_null("DrawChance")
	if draw_chance_label:
		fit_label_to_height(draw_chance_label)

	fit_label_group_to_height([
		card.get_node_or_null("Cost"),
		card.get_node_or_null("Type"),
		card.get_node_or_null("Description"),
	])


static func set_label_text(card: Node2D, label_name: String, text_value: String) -> void:
	var label: RichTextLabel = card.get_node_or_null(label_name)
	if label:
		set_label_bbcode(label, text_value)


static func set_label_bbcode(label: RichTextLabel, text_value: String) -> void:
	if label == null:
		return

	label.set_meta("bbcode_source", text_value)
	label.bbcode_enabled = true
	label.clear()
	if not text_value.is_empty():
		label.append_text(text_value)
		fit_label_to_height(label)


static func get_label_source_text(label: RichTextLabel) -> String:
	if label == null:
		return ""
	if label.has_meta("bbcode_source"):
		return str(label.get_meta("bbcode_source"))
	return label.text


static func fit_label_to_height(label: RichTextLabel) -> void:
	if label == null:
		return

	var starting_font_size_value = label.get("theme_override_font_sizes/normal_font_size")
	if starting_font_size_value == null:
		return

	var starting_font_size: int = starting_font_size_value
	if starting_font_size <= 0:
		return

	for font_size in range(starting_font_size, MIN_AUTO_FIT_FONT_SIZE - 1, -1):
		apply_label_font_size(label, font_size)
		label.queue_redraw()
		if label.get_content_height() <= label.size.y:
			return


static func fit_label_group_to_height(labels: Array) -> void:
	var valid_labels: Array[RichTextLabel] = []
	var starting_font_size := 0
	for label_variant in labels:
		var label := label_variant as RichTextLabel
		if label == null:
			continue
		var font_size_value = label.get("theme_override_font_sizes/normal_font_size")
		if font_size_value == null:
			continue
		valid_labels.append(label)
		starting_font_size = max(starting_font_size, int(font_size_value))

	if valid_labels.is_empty() or starting_font_size <= 0:
		return

	for font_size in range(starting_font_size, MIN_AUTO_FIT_FONT_SIZE - 1, -1):
		for label in valid_labels:
			apply_label_font_size(label, font_size)
			label.queue_redraw()

		var all_fit := true
		for label in valid_labels:
			if label.get_content_height() > label.size.y:
				all_fit = false
				break

		if all_fit:
			return


static func apply_label_font_size(label: RichTextLabel, font_size: int) -> void:
	if label == null:
		return

	for font_key in ["normal_font_size", "bold_font_size", "bold_italics_font_size", "italics_font_size", "mono_font_size"]:
		label.set("theme_override_font_sizes/%s" % font_key, font_size)


static func get_preset_font_size(description_size_preset: int, regular_size: int, scale_2_size: int, scale_4_size: int) -> int:
	if description_size_preset == 1:
		return scale_2_size
	if description_size_preset == 2:
		return scale_4_size
	return regular_size


static func set_art_texture(card: Node2D, texture: Texture2D) -> void:
	var art_sprite: Sprite2D = card.get_node_or_null("Art")
	if art_sprite == null:
		art_sprite = card.get_node_or_null("Sprite2D/Sprite2D")
	if art_sprite:
		art_sprite.texture = texture


static func resolve_texture(art_source) -> Texture2D:
	if art_source is Texture2D:
		return art_source

	if art_source is String and not String(art_source).is_empty():
		return load(String(art_source)) as Texture2D

	return null


static func _copy_sprite_branch(target_root: Node, source_root: Node) -> void:
	_copy_named_sprite(target_root, source_root, "Frame")
	_copy_named_sprite(target_root, source_root, "Art")
	_copy_named_sprite(target_root, source_root, "Sprite2D")

	var target_sprite: Sprite2D = target_root.get_node_or_null("Sprite2D")
	var source_sprite: Sprite2D = source_root.get_node_or_null("Sprite2D")
	if target_sprite and source_sprite:
		for source_child: Node in source_sprite.get_children():
			if source_child is Sprite2D:
				var target_child: Sprite2D = _find_sprite_child_by_name(target_sprite, String(source_child.name))
				if target_child:
					target_child.texture = source_child.texture
					_copy_nested_sprite_children(target_child, source_child)


static func _copy_named_sprite(target_root: Node, source_root: Node, sprite_name: String) -> void:
	var target_sprite: Sprite2D = target_root.get_node_or_null(sprite_name)
	var source_sprite: Sprite2D = source_root.get_node_or_null(sprite_name)
	if target_sprite and source_sprite:
		target_sprite.texture = source_sprite.texture


static func _copy_nested_sprite_children(target_parent: Node, source_parent: Node) -> void:
	for source_child: Node in source_parent.get_children():
		if source_child is Sprite2D:
			var target_child: Sprite2D = _find_sprite_child_by_name(target_parent, String(source_child.name))
			if target_child:
				target_child.texture = source_child.texture
				_copy_nested_sprite_children(target_child, source_child)


static func _find_sprite_child_by_name(parent_node: Node, child_name: String) -> Sprite2D:
	for child: Node in parent_node.get_children():
		if child is Sprite2D and String(child.name) == child_name:
			return child
	return null
