extends RefCounted

const AudioConstants = preload("res://shared/constants/audio_constants.gd")


static func default_audio_settings() -> Dictionary:
	return {
		AudioConstants.MASTER_VOLUME_KEY: AudioConstants.DEFAULT_MASTER_VOLUME,
		AudioConstants.PLAYER_CARDS_VOLUME_KEY: AudioConstants.DEFAULT_PLAYER_CARDS_VOLUME,
		AudioConstants.ENEMY_CARDS_VOLUME_KEY: AudioConstants.DEFAULT_ENEMY_CARDS_VOLUME,
		AudioConstants.MUSIC_VOLUME_KEY: AudioConstants.DEFAULT_MUSIC_VOLUME,
	}


static func apply_audio_settings(settings: Dictionary) -> void:
	ensure_audio_buses()
	_apply_bus_volume(
		AudioConstants.MASTER_BUS_NAME,
		float(settings.get(AudioConstants.MASTER_VOLUME_KEY, AudioConstants.DEFAULT_MASTER_VOLUME))
	)
	_apply_bus_volume(
		AudioConstants.PLAYER_CARDS_BUS_NAME,
		float(settings.get(AudioConstants.PLAYER_CARDS_VOLUME_KEY, AudioConstants.DEFAULT_PLAYER_CARDS_VOLUME))
	)
	_apply_bus_volume(
		AudioConstants.ENEMY_CARDS_BUS_NAME,
		float(settings.get(AudioConstants.ENEMY_CARDS_VOLUME_KEY, AudioConstants.DEFAULT_ENEMY_CARDS_VOLUME))
	)
	_apply_bus_volume(
		AudioConstants.MUSIC_BUS_NAME,
		float(settings.get(AudioConstants.MUSIC_VOLUME_KEY, AudioConstants.DEFAULT_MUSIC_VOLUME))
	)


static func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		return
	var normalized_volume := clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(normalized_volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, normalized_volume <= 0.001)


static func ensure_audio_buses() -> void:
	_ensure_bus(AudioConstants.PLAYER_CARDS_BUS_NAME, AudioConstants.MASTER_BUS_NAME)
	_ensure_bus(AudioConstants.ENEMY_CARDS_BUS_NAME, AudioConstants.MASTER_BUS_NAME)
	_ensure_bus(AudioConstants.MUSIC_BUS_NAME, AudioConstants.MASTER_BUS_NAME)


static func _ensure_bus(bus_name: String, send_bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus(AudioServer.bus_count)
	var bus_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, send_bus_name)
