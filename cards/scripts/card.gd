extends Node2D

signal hovered
signal hovered_off

@export var registers_hover_signals := true

var hand_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if registers_hover_signals:
		get_parent().connect_card_signals(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)


func copy_display_from(source_card: Node2D) -> void:
	var sprite := get_node_or_null("Sprite2D")
	var source_sprite := source_card.get_node_or_null("Sprite2D")
	if sprite and source_sprite:
		sprite.texture = source_sprite.texture

	for label_name in ["Name", "Cost", "Type", "Description"]:
		var target_label := get_node_or_null(label_name)
		var source_label := source_card.get_node_or_null(label_name)
		if target_label and source_label:
			target_label.text = source_label.text


func set_visuals_visible(is_visible: bool) -> void:
	var sprite := get_node_or_null("Sprite2D")
	if sprite:
		sprite.visible = is_visible

	for label_name in ["Name", "Cost", "Type", "Description"]:
		var label := get_node_or_null(label_name)
		if label:
			label.visible = is_visible
