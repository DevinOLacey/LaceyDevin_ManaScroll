extends Control

const BattleAudioService = preload("res://battle/scripts/battle_audio_service.gd")
const SETTINGS_STATE = preload("res://ui/scripts/settings_state.gd")
const UIConstants = preload("res://shared/constants/ui_constants.gd")

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
	BattleAudioService.stop_background_music()
	get_tree().change_scene_to_file(UIConstants.BATTLE_SCENE_PATH)


func _on_settings_button_pressed() -> void:
	get_tree().change_scene_to_file(UIConstants.SETTINGS_SCENE_PATH)


func _on_quit_button_pressed() -> void:
	get_tree().quit()
