extends RefCounted

const AudioConstants = preload("res://shared/constants/audio_constants.gd")
const AudioBusService = preload("res://shared/services/audio_bus_service.gd")
const UIConstants = preload("res://shared/constants/ui_constants.gd")

static func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(UIConstants.SETTINGS_PATH)
	if error != OK:
		return _default_settings()

	var settings := _default_settings()
	settings[AudioConstants.MASTER_VOLUME_KEY] = float(config.get_value(UIConstants.AUDIO_SECTION, AudioConstants.MASTER_VOLUME_KEY, settings[AudioConstants.MASTER_VOLUME_KEY]))
	settings[AudioConstants.PLAYER_CARDS_VOLUME_KEY] = float(config.get_value(UIConstants.AUDIO_SECTION, AudioConstants.PLAYER_CARDS_VOLUME_KEY, settings[AudioConstants.PLAYER_CARDS_VOLUME_KEY]))
	settings[AudioConstants.ENEMY_CARDS_VOLUME_KEY] = float(config.get_value(UIConstants.AUDIO_SECTION, AudioConstants.ENEMY_CARDS_VOLUME_KEY, settings[AudioConstants.ENEMY_CARDS_VOLUME_KEY]))
	settings[AudioConstants.MUSIC_VOLUME_KEY] = float(config.get_value(UIConstants.AUDIO_SECTION, AudioConstants.MUSIC_VOLUME_KEY, settings[AudioConstants.MUSIC_VOLUME_KEY]))
	settings["fullscreen"] = bool(config.get_value(UIConstants.VIDEO_SECTION, "fullscreen", settings["fullscreen"]))
	return settings


static func save_settings(settings: Dictionary) -> void:
	var merged_settings := _default_settings()
	for key in settings.keys():
		merged_settings[key] = settings[key]

	var config := ConfigFile.new()
	config.set_value(UIConstants.AUDIO_SECTION, AudioConstants.MASTER_VOLUME_KEY, float(merged_settings[AudioConstants.MASTER_VOLUME_KEY]))
	config.set_value(UIConstants.AUDIO_SECTION, AudioConstants.PLAYER_CARDS_VOLUME_KEY, float(merged_settings[AudioConstants.PLAYER_CARDS_VOLUME_KEY]))
	config.set_value(UIConstants.AUDIO_SECTION, AudioConstants.ENEMY_CARDS_VOLUME_KEY, float(merged_settings[AudioConstants.ENEMY_CARDS_VOLUME_KEY]))
	config.set_value(UIConstants.AUDIO_SECTION, AudioConstants.MUSIC_VOLUME_KEY, float(merged_settings[AudioConstants.MUSIC_VOLUME_KEY]))
	config.set_value(UIConstants.VIDEO_SECTION, "fullscreen", bool(merged_settings["fullscreen"]))
	config.save(UIConstants.SETTINGS_PATH)


static func apply_settings(settings: Dictionary) -> void:
	AudioBusService.apply_audio_settings(settings)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if bool(settings.get("fullscreen", false))
		else DisplayServer.WINDOW_MODE_WINDOWED
	)


static func _default_settings() -> Dictionary:
	var defaults := AudioBusService.default_audio_settings()
	defaults["fullscreen"] = false
	return defaults
