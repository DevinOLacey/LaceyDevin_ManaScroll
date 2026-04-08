extends Control

const SETTINGS_STATE = preload("res://ui/scripts/settings_state.gd")
const GAME_SCENE_PATH := "res://scenes/main.tscn"
const SETTINGS_SCENE_PATH := "res://ui/scenes/settings_menu.tscn"

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton


func _ready() -> void:
	_apply_saved_settings()
	start_button.pressed.connect(_on_start_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	quit_button.visible = OS.has_feature("pc")


func _apply_saved_settings() -> void:
	SETTINGS_STATE.apply_settings(SETTINGS_STATE.load_settings())


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
