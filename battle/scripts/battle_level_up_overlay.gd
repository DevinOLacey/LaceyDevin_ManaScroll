extends CanvasLayer

signal option_selected(option_id: String)

@onready var options_row: HBoxContainer = $Root/Center/Modal/ModalMargin/ModalVBox/OptionsRow


func _ready() -> void:
	visible = false


func configure_options(options: Array[Dictionary]) -> void:
	for child in options_row.get_children():
		child.queue_free()

	for option in options:
		options_row.add_child(_build_option_card(option))


func show_overlay() -> void:
	visible = true


func hide_overlay() -> void:
	visible = false


func _build_option_card(option: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(260, 280)
	card.add_theme_stylebox_override("panel", _build_card_style(option.get("accent", Color(1, 1, 1, 1))))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	card.add_child(margin)

	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)

	var title := Label.new()
	title.text = str(option.get("title", "Upgrade"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.95, 0.9, 1.0))
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = str(option.get("subtitle", "Choose your next path."))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.84, 0.9, 0.98, 0.96))
	content.add_child(subtitle)

	var choose_button := Button.new()
	choose_button.custom_minimum_size = Vector2(0, 56)
	choose_button.text = "Choose Path"
	choose_button.add_theme_font_size_override("font_size", 20)
	choose_button.add_theme_stylebox_override("normal", _build_button_style(option.get("accent", Color(1, 1, 1, 1)), 0.20))
	choose_button.add_theme_stylebox_override("hover", _build_button_style(option.get("accent", Color(1, 1, 1, 1)), 0.30))
	choose_button.add_theme_stylebox_override("pressed", _build_button_style(option.get("accent", Color(1, 1, 1, 1)), 0.38))
	choose_button.pressed.connect(_on_option_button_pressed.bind(str(option.get("id", ""))))
	content.add_child(choose_button)

	return card


func _build_card_style(accent: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = accent
	style.corner_radius_top_left = 24
	style.corner_radius_top_right = 24
	style.corner_radius_bottom_right = 24
	style.corner_radius_bottom_left = 24
	style.content_margin_left = 8.0
	style.content_margin_top = 8.0
	style.content_margin_right = 8.0
	style.content_margin_bottom = 8.0
	return style


func _build_button_style(accent: Color, alpha: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(accent.r, accent.g, accent.b, alpha)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = accent
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_right = 16
	style.corner_radius_bottom_left = 16
	style.content_margin_left = 16.0
	style.content_margin_top = 12.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 12.0
	return style


func _on_option_button_pressed(option_id: String) -> void:
	option_selected.emit(option_id)
