extends Control

const SETTINGS_STATE = preload("res://ui/scripts/settings_state.gd")
const MAIN_MENU_SCENE_PATH := "res://ui/scenes/main_menu.tscn"

@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var volume_slider: HSlider = %VolumeSlider
@onready var volume_value_label: Label = %VolumeValueLabel
@onready var back_button: Button = %BackButton

var current_settings := {}


func _ready() -> void:
	current_settings = SETTINGS_STATE.load_settings()
	_sync_controls()
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	back_button.pressed.connect(_on_back_button_pressed)


func _sync_controls() -> void:
	fullscreen_toggle.button_pressed = bool(current_settings.get("fullscreen", false))
	volume_slider.value = float(current_settings.get("master_volume", 0.8))
	_update_volume_label(volume_slider.value)


func _update_volume_label(value: float) -> void:
	volume_value_label.text = "%d%%" % int(round(value * 100.0))


func _save_and_apply() -> void:
	SETTINGS_STATE.save_settings(current_settings)
	SETTINGS_STATE.apply_settings(current_settings)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	current_settings["fullscreen"] = toggled_on
	_save_and_apply()


func _on_volume_slider_value_changed(value: float) -> void:
	current_settings["master_volume"] = value
	_update_volume_label(value)
	_save_and_apply()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
