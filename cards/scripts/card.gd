extends Node2D

signal hovered
signal hovered_off

@export var registers_hover_signals := true
@export_enum("Regular", "Scale2", "Scale4") var description_size_preset := 0

# CARD STYLE
const TITLE_FONT_SIZE_REGULAR = 16
const TITLE_FONT_SIZE_SCALE_4 = 24
const TITLE_FONT_SIZE_SCALE_2 = 32
const COST_FONT_SIZE_REGULAR = 16
const COST_FONT_SIZE_SCALE_4 = 24
const COST_FONT_SIZE_SCALE_2 = 32
const TYPE_FONT_SIZE_REGULAR = 8
const TYPE_FONT_SIZE_SCALE_4 = 16
const TYPE_FONT_SIZE_SCALE_2 = 24
const DESCRIPTION_FONT_SIZE_REGULAR = 8
const DESCRIPTION_FONT_SIZE_SCALE_4 = 16
const DESCRIPTION_FONT_SIZE_SCALE_2 = 24
const DRAW_CHANCE_FONT_SIZE_REGULAR = 4
const DRAW_CHANCE_FONT_SIZE_SCALE_4 = 16
#const DRAW_CHANCE_FONT_SIZE_SCALE_2 = DRAW_CHANCE_FONT_SIZE_REGULAR
const LABEL_Z_INDEX = 5


const MANIFEST_START_OFFSET = Vector2(0, 48)
const MANIFEST_START_SCALE = Vector2(0.35, 0.35)
const MANIFEST_MOTE_COUNT = 14
const MANIFEST_COLORS = [
	Color(0.52, 0.93, 1.0, 0.95),
	Color(0.7, 0.55, 1.0, 0.9),
	Color(0.95, 0.98, 1.0, 0.95),
]

var hand_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_apply_text_font_sizes()
	_apply_label_z_index()
	if registers_hover_signals and get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)


func copy_display_from(source_card: Node2D) -> void:
	_copy_sprite_branch(self, source_card)

	for label_name in ["Name", "Cost", "Type", "Description", "DrawChance"]:
		var target_label: RichTextLabel = get_node_or_null(label_name)
		var source_label: RichTextLabel = source_card.get_node_or_null(label_name)
		if target_label and source_label:
			var label_text := _get_label_source_text(source_label)
			_set_label_bbcode(target_label, label_text)


func apply_card_data(card_id: String, card_data: Dictionary) -> void:
	set_meta("card_id", card_id)
	set_meta("card_data", card_data.duplicate(true))

	var name_text: String = str(card_data.get("name", card_id))
	var cost_text: String = str(card_data.get("cost", ""))
	var type_text: String = str(card_data.get("type", ""))
	var description_text: String = str(card_data.get("description", ""))
	var art_source = card_data.get("art", null)

	_set_label_text("Name", "[b]%s[/b]" % name_text)
	_set_label_text("Cost", "[b]%s[/b]" % cost_text)
	_set_label_text("Type", type_text)
	_set_label_text("Description", description_text)
	_set_label_text("DrawChance", "")
	_set_art_texture(_resolve_texture(art_source))


func set_visuals_visible(visible_state: bool) -> void:
	for sprite_path in ["Frame", "Art", "Sprite2D", "Sprite2D/Sprite2D"]:
		var sprite: Sprite2D = get_node_or_null(sprite_path)
		if sprite:
			sprite.visible = visible_state

	for label_name in ["Name", "Cost", "Type", "Description", "DrawChance"]:
		var label: RichTextLabel = get_node_or_null(label_name)
		if label:
			label.visible = visible_state


func manifest_to_position(target_position: Vector2, duration: float) -> void:
	var safe_duration: float = maxf(duration, 0.01)
	var collision: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true

	position = target_position + MANIFEST_START_OFFSET
	scale = MANIFEST_START_SCALE
	rotation_degrees = randf_range(-8.0, 8.0)
	modulate = Color(1, 1, 1, 0)
	z_index = max(z_index, 3)

	_spawn_manifest_motes(safe_duration)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position", target_position, safe_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), safe_duration * 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, safe_duration * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "rotation_degrees", 0.0, safe_duration * 0.9).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	var settle_tween: Tween = create_tween()
	settle_tween.tween_interval(safe_duration * 0.72)
	settle_tween.tween_property(self, "scale", Vector2.ONE, safe_duration * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	settle_tween.tween_callback(func():
		if collision:
			collision.disabled = false
		z_index = 1
	)


func _spawn_manifest_motes(duration: float) -> void:
	for i in range(MANIFEST_MOTE_COUNT):
		var mote: ColorRect = ColorRect.new()
		var mote_size: float = randf_range(5.0, 12.0)
		mote.size = Vector2(mote_size, mote_size)
		mote.color = MANIFEST_COLORS[randi() % MANIFEST_COLORS.size()]
		mote.position = _random_manifest_point() - (mote.size / 2.0)
		mote.pivot_offset = mote.size / 2.0
		mote.rotation = randf_range(-PI, PI)
		mote.scale = Vector2.ONE * randf_range(0.8, 1.3)
		mote.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(mote)

		var travel_delay: float = randf_range(0.0, duration * 0.28)
		var target_offset: Vector2 = Vector2(randf_range(-10.0, 10.0), randf_range(-22.0, 14.0)) - (mote.size / 2.0)
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(mote, "position", target_offset, duration * 0.42).set_delay(travel_delay).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		tween.tween_property(mote, "scale", Vector2.ZERO, duration * 0.42).set_delay(travel_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_property(mote, "modulate:a", 0.0, duration * 0.42).set_delay(travel_delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tween.tween_callback(mote.queue_free).set_delay(travel_delay + duration * 0.42)


func _random_manifest_point() -> Vector2:
	var angle: float = randf_range(0.0, TAU)
	var radius_x: float = randf_range(90.0, 132.0)
	var radius_y: float = randf_range(120.0, 170.0)
	return Vector2(cos(angle) * radius_x, sin(angle) * radius_y)


func _apply_text_font_sizes() -> void:
	_apply_label_font_size(get_node_or_null("Name"), _get_preset_font_size(TITLE_FONT_SIZE_REGULAR, TITLE_FONT_SIZE_SCALE_2, TITLE_FONT_SIZE_SCALE_4))
	_apply_label_font_size(get_node_or_null("Cost"), _get_preset_font_size(COST_FONT_SIZE_REGULAR, COST_FONT_SIZE_SCALE_2, COST_FONT_SIZE_SCALE_4))
	_apply_label_font_size(get_node_or_null("Type"), _get_preset_font_size(TYPE_FONT_SIZE_REGULAR, TYPE_FONT_SIZE_SCALE_2, TYPE_FONT_SIZE_SCALE_4))
	_apply_label_font_size(get_node_or_null("Description"), _get_preset_font_size(DESCRIPTION_FONT_SIZE_REGULAR, DESCRIPTION_FONT_SIZE_SCALE_2, DESCRIPTION_FONT_SIZE_SCALE_4))
	#_apply_label_font_size(get_node_or_null("DrawChance"), _get_preset_font_size(DRAW_CHANCE_FONT_SIZE_REGULAR, DRAW_CHANCE_FONT_SIZE_SCALE_2, DRAW_CHANCE_FONT_SIZE_SCALE_4))


func _get_preset_font_size(regular_size: int, scale_2_size: int, scale_4_size: int) -> int:
	if description_size_preset == 1:
		return scale_2_size
	if description_size_preset == 2:
		return scale_4_size
	return regular_size


func _apply_label_font_size(label: RichTextLabel, font_size: int) -> void:
	if label == null:
		return

	for font_key in [
		"normal_font_size",
		"bold_font_size",
		"bold_italics_font_size",
		"italics_font_size",
		"mono_font_size",
	]:
		label.set("theme_override_font_sizes/%s" % font_key, font_size)


func _apply_label_z_index() -> void:
	for label_name in ["Name", "Cost", "Type", "Description", "DrawChance"]:
		var label: RichTextLabel = get_node_or_null(label_name)
		if label:
			label.z_index = LABEL_Z_INDEX


func _set_label_text(label_name: String, text_value: String) -> void:
	var label: RichTextLabel = get_node_or_null(label_name)
	if label:
		_set_label_bbcode(label, text_value)


func _set_label_bbcode(label: RichTextLabel, text_value: String) -> void:
	if label == null:
		return

	label.set_meta("bbcode_source", text_value)
	label.bbcode_enabled = true
	label.clear()
	if not text_value.is_empty():
		label.append_text(text_value)


func _get_label_source_text(label: RichTextLabel) -> String:
	if label == null:
		return ""
	if label.has_meta("bbcode_source"):
		return str(label.get_meta("bbcode_source"))
	return label.text


func _set_art_texture(texture: Texture2D) -> void:
	var art_sprite: Sprite2D = get_node_or_null("Art")
	if art_sprite == null:
		art_sprite = get_node_or_null("Sprite2D/Sprite2D")
	if art_sprite:
		art_sprite.texture = texture


func _resolve_texture(art_source) -> Texture2D:
	if art_source is Texture2D:
		return art_source

	if art_source is String and not String(art_source).is_empty():
		return load(String(art_source)) as Texture2D

	return null


func _copy_sprite_branch(target_root: Node, source_root: Node) -> void:
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


func _copy_named_sprite(target_root: Node, source_root: Node, sprite_name: String) -> void:
	var target_sprite: Sprite2D = target_root.get_node_or_null(sprite_name)
	var source_sprite: Sprite2D = source_root.get_node_or_null(sprite_name)
	if target_sprite and source_sprite:
		target_sprite.texture = source_sprite.texture


func _copy_nested_sprite_children(target_parent: Node, source_parent: Node) -> void:
	for source_child: Node in source_parent.get_children():
		if source_child is Sprite2D:
			var target_child: Sprite2D = _find_sprite_child_by_name(target_parent, String(source_child.name))
			if target_child:
				target_child.texture = source_child.texture
				_copy_nested_sprite_children(target_child, source_child)


func _find_sprite_child_by_name(parent_node: Node, child_name: String) -> Sprite2D:
	for child: Node in parent_node.get_children():
		if child is Sprite2D and String(child.name) == child_name:
			return child
	return null
