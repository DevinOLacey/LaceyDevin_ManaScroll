extends Control

const AudioConstants = preload("res://shared/constants/audio_constants.gd")
const SETTINGS_STATE = preload("res://ui/scripts/settings_state.gd")
const UIConstants = preload("res://shared/constants/ui_constants.gd")

@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var master_volume_slider: HSlider = %MasterVolumeSlider
@onready var master_volume_value_label: Label = %MasterVolumeValueLabel
@onready var player_cards_volume_slider: HSlider = %PlayerCardsVolumeSlider
@onready var player_cards_volume_value_label: Label = %PlayerCardsVolumeValueLabel
@onready var enemy_cards_volume_slider: HSlider = %EnemyCardsVolumeSlider
@onready var enemy_cards_volume_value_label: Label = %EnemyCardsVolumeValueLabel
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var music_volume_value_label: Label = %MusicVolumeValueLabel
@onready var back_button: Button = %BackButton

var current_settings := {}


func _ready() -> void:
	current_settings = SETTINGS_STATE.load_settings()
	_sync_controls()
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	_bind_volume_slider(master_volume_slider, Callable(self, "_on_master_volume_changed"))
	_bind_volume_slider(player_cards_volume_slider, Callable(self, "_on_player_cards_volume_changed"))
	_bind_volume_slider(enemy_cards_volume_slider, Callable(self, "_on_enemy_cards_volume_changed"))
	_bind_volume_slider(music_volume_slider, Callable(self, "_on_music_volume_changed"))
	back_button.pressed.connect(_on_back_button_pressed)


func _sync_controls() -> void:
	fullscreen_toggle.button_pressed = bool(current_settings.get("fullscreen", false))
	_sync_volume_control(
		master_volume_slider,
		master_volume_value_label,
		float(current_settings.get(AudioConstants.MASTER_VOLUME_KEY, AudioConstants.DEFAULT_MASTER_VOLUME))
	)
	_sync_volume_control(
		player_cards_volume_slider,
		player_cards_volume_value_label,
		float(current_settings.get(AudioConstants.PLAYER_CARDS_VOLUME_KEY, AudioConstants.DEFAULT_PLAYER_CARDS_VOLUME))
	)
	_sync_volume_control(
		enemy_cards_volume_slider,
		enemy_cards_volume_value_label,
		float(current_settings.get(AudioConstants.ENEMY_CARDS_VOLUME_KEY, AudioConstants.DEFAULT_ENEMY_CARDS_VOLUME))
	)
	_sync_volume_control(
		music_volume_slider,
		music_volume_value_label,
		float(current_settings.get(AudioConstants.MUSIC_VOLUME_KEY, AudioConstants.DEFAULT_MUSIC_VOLUME))
	)


func _bind_volume_slider(slider: HSlider, changed_callback: Callable) -> void:
	slider.value_changed.connect(changed_callback)


func _sync_volume_control(slider: HSlider, value_label: Label, value: float) -> void:
	slider.value = value
	_update_volume_label(value_label, value)


func _update_volume_label(value_label: Label, value: float) -> void:
	value_label.text = "%d%%" % int(round(value * 100.0))


func _save_and_apply() -> void:
	SETTINGS_STATE.save_settings(current_settings)
	SETTINGS_STATE.apply_settings(current_settings)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	current_settings["fullscreen"] = toggled_on
	_save_and_apply()


func _on_master_volume_changed(value: float) -> void:
	current_settings[AudioConstants.MASTER_VOLUME_KEY] = value
	_update_volume_label(master_volume_value_label, value)
	_save_and_apply()


func _on_player_cards_volume_changed(value: float) -> void:
	current_settings[AudioConstants.PLAYER_CARDS_VOLUME_KEY] = value
	_update_volume_label(player_cards_volume_value_label, value)
	_save_and_apply()


func _on_enemy_cards_volume_changed(value: float) -> void:
	current_settings[AudioConstants.ENEMY_CARDS_VOLUME_KEY] = value
	_update_volume_label(enemy_cards_volume_value_label, value)
	_save_and_apply()


func _on_music_volume_changed(value: float) -> void:
	current_settings[AudioConstants.MUSIC_VOLUME_KEY] = value
	_update_volume_label(music_volume_value_label, value)
	_save_and_apply()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(UIConstants.MAIN_MENU_SCENE_PATH)
