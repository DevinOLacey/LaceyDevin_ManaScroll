extends RefCounted

const AudioConstants = preload("res://shared/constants/audio_constants.gd")
const AudioBusService = preload("res://shared/services/audio_bus_service.gd")
const BACKGROUND_MUSIC_AUTOLOAD_PATH := "/root/Backgroundmusic"


static func play_player_spell(audio_player: AudioStreamPlayer, card_data: Dictionary) -> void:
	_play_stream(audio_player, str(card_data.get("cast_sfx", "")), AudioConstants.PLAYER_CARDS_BUS_NAME)


static func play_enemy_spell(audio_player: AudioStreamPlayer, card_data: Dictionary) -> void:
	_play_stream(audio_player, str(card_data.get("cast_sfx", "")), AudioConstants.ENEMY_CARDS_BUS_NAME)


static func play_battle_music(audio_player: AudioStreamPlayer) -> void:
	if audio_player == null:
		return
	AudioBusService.ensure_audio_buses()
	stop_background_music()
	audio_player.bus = AudioConstants.MUSIC_BUS_NAME
	audio_player.stream_paused = false
	audio_player.stop()
	audio_player.play()


static func stop_battle_music(audio_player: AudioStreamPlayer) -> void:
	if audio_player and audio_player.playing:
		audio_player.stop()


static func resume_background_music() -> void:
	var background_player := _get_background_music_player()
	if background_player == null:
		return
	background_player.stream_paused = false
	background_player.play()


static func _play_stream(audio_player: AudioStreamPlayer, stream_path: String, bus_name: String) -> void:
	if audio_player == null or stream_path.is_empty():
		return
	AudioBusService.ensure_audio_buses()
	audio_player.bus = bus_name
	var next_stream := load(stream_path) as AudioStream
	if next_stream == null:
		return
	audio_player.stream = next_stream
	audio_player.play()

static func stop_background_music() -> void:
	var background_player := _get_background_music_player()
	if background_player == null:
		return
	background_player.stream_paused = false
	background_player.stop()


static func _get_background_music_player() -> AudioStreamPlayer2D:
	var background_music: Node = Engine.get_main_loop().root.get_node_or_null(BACKGROUND_MUSIC_AUTOLOAD_PATH)
	if background_music == null:
		return null
	var root_player := background_music as AudioStreamPlayer2D
	if root_player:
		return root_player
	return background_music.get_node_or_null("AudioStreamPlayer2D") as AudioStreamPlayer2D
