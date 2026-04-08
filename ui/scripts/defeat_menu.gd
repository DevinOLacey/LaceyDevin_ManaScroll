extends Control

const BATTLE_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_MENU_SCENE_PATH := "res://ui/scenes/main_menu.tscn"

@export var intro_delay := 0.12
@export var fade_duration := 0.35

@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton
@onready var panel: Control = %Panel


func _ready() -> void:
	modulate = Color(1, 1, 1, 0)
	panel.modulate = Color(1, 1, 1, 0)
	restart_button.disabled = true
	exit_button.disabled = true
	restart_button.pressed.connect(_on_restart_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)
	call_deferred("_play_intro")


func _play_intro() -> void:
	if intro_delay > 0.0:
		await get_tree().create_timer(intro_delay).timeout

	var tween := create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1), fade_duration)
	tween.parallel().tween_property(panel, "modulate", Color(1, 1, 1, 1), fade_duration)
	await tween.finished
	restart_button.disabled = false
	exit_button.disabled = false


func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _on_exit_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
