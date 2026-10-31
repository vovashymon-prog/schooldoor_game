extends Node2D

@export var enemy_per_room := [2, 2, 3, 4]
@export var rooms = [preload("res://scenes/rooms/Room3.tscn"), preload("res://scenes/rooms/Room1.tscn"), preload("res://scenes/rooms/Room2.tscn"), preload("res://scenes/rooms/Room4.tscn"), preload("res://scenes/rooms/boss_rroom.tscn")]
var enemies_killed := 0
var current_room := 1
@onready var current_room_asset = $Room1
@onready var player = get_tree().get_first_node_in_group("player")
@onready var fade = $CanvasLayer/Fade

func fade_screen():
	var tween = get_tree().create_tween()
	tween.tween_property(fade, "color", Color(0.0, 0.0, 0.0, 1.0), 0.1)
	tween.play()
	await get_tree().create_timer(0.3).timeout; tween.kill();
	change_scene()
	await get_tree().create_timer(0.2).timeout
	tween = create_tween()
	tween.tween_property(fade, "color", Color("00000000"), 0.1)
	tween.play()

func change_scene():
	enemies_killed = 0
	current_room_asset.queue_free()
	current_room_asset = rooms[current_room].instantiate()
	current_room += 1
	add_child(current_room_asset)
	current_room_asset.global_position = Vector2.ZERO
	player.global_position = current_room_asset.get_child(0).global_position

func _on_transition_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"): return
	body.is_dashing = false
	body.can_dash = true
	if enemies_killed >= enemy_per_room[current_room-1]:
		player.audio_clashes.stream = player.door_sound
		player.audio_clashes.play()
		fade_screen()
