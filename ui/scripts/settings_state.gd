extends RefCounted

const UIConstants = preload("res://shared/constants/ui_constants.gd")

static func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var error := config.load(UIConstants.SETTINGS_PATH)
	if error != OK:
		return _default_settings()

	var settings := _default_settings()
	settings["master_volume"] = float(config.get_value(UIConstants.AUDIO_SECTION, "master_volume", settings["master_volume"]))
	settings["fullscreen"] = bool(config.get_value(UIConstants.VIDEO_SECTION, "fullscreen", settings["fullscreen"]))
	return settings


static func save_settings(settings: Dictionary) -> void:
	var merged_settings := _default_settings()
	for key in settings.keys():
		merged_settings[key] = settings[key]

	var config := ConfigFile.new()
	config.set_value(UIConstants.AUDIO_SECTION, "master_volume", float(merged_settings["master_volume"]))
	config.set_value(UIConstants.VIDEO_SECTION, "fullscreen", bool(merged_settings["fullscreen"]))
	config.save(UIConstants.SETTINGS_PATH)


static func apply_settings(settings: Dictionary) -> void:
	var master_bus_index := AudioServer.get_bus_index(UIConstants.MASTER_BUS_NAME)
	if master_bus_index != -1:
		var volume := clampf(float(settings.get("master_volume", 0.8)), 0.0, 1.0)
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(maxf(volume, 0.0001)))
		AudioServer.set_bus_mute(master_bus_index, volume <= 0.001)

	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN
		if bool(settings.get("fullscreen", false))
		else DisplayServer.WINDOW_MODE_WINDOWED
	)


static func _default_settings() -> Dictionary:
	return {
		"master_volume": 0.8,
		"fullscreen": false,
	}
