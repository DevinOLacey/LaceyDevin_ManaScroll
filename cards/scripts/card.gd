extends Node2D

signal hovered
signal hovered_off

const CardContentHelper = preload("res://cards/scripts/card_content_helper.gd")

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
const MANIFEST_START_OFFSET = Vector2(0, 48)
const MANIFEST_START_SCALE = Vector2(0.35, 0.35)
const MANIFEST_MOTE_COUNT = 14
const MANIFEST_COLORS = [
	Color(0.52, 0.93, 1.0, 0.95),
	Color(0.7, 0.55, 1.0, 0.9),
	Color(0.95, 0.98, 1.0, 0.95),
]

var hand_position
var motion_tween: Tween
var settle_tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CardContentHelper.apply_text_font_sizes(self, description_size_preset, {
		"title_regular": TITLE_FONT_SIZE_REGULAR,
		"title_scale_2": TITLE_FONT_SIZE_SCALE_2,
		"title_scale_4": TITLE_FONT_SIZE_SCALE_4,
		"cost_regular": COST_FONT_SIZE_REGULAR,
		"cost_scale_2": COST_FONT_SIZE_SCALE_2,
		"cost_scale_4": COST_FONT_SIZE_SCALE_4,
		"type_regular": TYPE_FONT_SIZE_REGULAR,
		"type_scale_2": TYPE_FONT_SIZE_SCALE_2,
		"type_scale_4": TYPE_FONT_SIZE_SCALE_4,
		"description_regular": DESCRIPTION_FONT_SIZE_REGULAR,
		"description_scale_2": DESCRIPTION_FONT_SIZE_SCALE_2,
		"description_scale_4": DESCRIPTION_FONT_SIZE_SCALE_4,
	})
	CardContentHelper.apply_label_z_index(self)
	if registers_hover_signals and get_parent().has_method("connect_card_signals"):
		get_parent().connect_card_signals(self)
	call_deferred("_auto_fit_all_labels")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)


func copy_display_from(source_card: Node2D) -> void:
	CardContentHelper.copy_display_from(self, source_card)


func apply_card_data(card_id: String, card_data: Dictionary) -> void:
	CardContentHelper.apply_card_data(self, card_id, card_data)
	call_deferred("_auto_fit_all_labels")


func set_visuals_visible(visible_state: bool) -> void:
	CardContentHelper.set_visuals_visible(self, visible_state)


func manifest_to_position(target_position: Vector2, duration: float) -> void:
	var safe_duration: float = maxf(duration, 0.01)
	stop_motion_tweens()
	var collision: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")
	if collision:
		collision.disabled = true

	position = target_position + MANIFEST_START_OFFSET
	scale = MANIFEST_START_SCALE
	rotation_degrees = randf_range(-8.0, 8.0)
	modulate = Color(1, 1, 1, 0)
	z_index = max(z_index, 3)

	_spawn_manifest_motes(safe_duration)

	motion_tween = create_tween()
	motion_tween.set_parallel(true)
	motion_tween.tween_property(self, "position", target_position, safe_duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "scale", Vector2(1.06, 1.06), safe_duration * 0.72).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "modulate:a", 1.0, safe_duration * 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	motion_tween.tween_property(self, "rotation_degrees", 0.0, safe_duration * 0.9).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	settle_tween = create_tween()
	settle_tween.tween_interval(safe_duration * 0.72)
	settle_tween.tween_property(self, "scale", Vector2.ONE, safe_duration * 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	settle_tween.tween_callback(func():
		if collision:
			collision.disabled = false
		z_index = 1
		motion_tween = null
		settle_tween = null
	)


func stop_motion_tweens(reset_transform: bool = false) -> void:
	if motion_tween and is_instance_valid(motion_tween):
		motion_tween.kill()
	motion_tween = null

	if settle_tween and is_instance_valid(settle_tween):
		settle_tween.kill()
	settle_tween = null

	var collision: CollisionShape2D = get_node_or_null("Area2D/CollisionShape2D")
	var is_removing: bool = has_meta("card_removing") and bool(get_meta("card_removing"))
	if collision and not is_removing:
		collision.disabled = false

	if reset_transform:
		scale = Vector2.ONE
		rotation_degrees = 0.0
		modulate = Color(1, 1, 1, 1)
		z_index = 1


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


func _auto_fit_all_labels() -> void:
	CardContentHelper.auto_fit_all_labels(self)
