extends Node2D

@export var enemy_per_room := [2, 2, 3, 4, 1]
@export var rooms = [
	preload("res://scenes/rooms/Room3.tscn"), 
	preload("res://scenes/rooms/Room1.tscn"), 
	preload("res://scenes/rooms/Room2.tscn"), 
	preload("res://scenes/rooms/Room4.tscn"), 
	preload("res://scenes/rooms/Room5.tscn"), 
	preload("res://scenes/rooms/boss_rroom.tscn")
]
var enemies_killed := 0
var current_room := 1
@onready var current_room_asset = $Room1
@onready var player = get_tree().get_first_node_in_group("player")
@onready var fade = $CanvasLayer/Fade

func _ready() -> void:
	MusicManager.play_room()

func fade_screen():
	var tween = create_tween()
	tween.tween_property(fade, "color", Color(0.0, 0.0, 0.0, 1.0), 0.1)
	await tween.finished
	change_scene()
	if is_inside_tree() and current_room < rooms.size() + 1:
		var tween_in = create_tween()
		tween_in.tween_property(fade, "color", Color("00000000"), 0.1)

func change_scene():
	if current_room >= rooms.size():
		get_tree().change_scene_to_file("res://scenes/ui/win_screen.tscn")
		MusicManager.play_menu()
		return 

	enemies_killed = 0
	current_room_asset.queue_free()
	current_room_asset = rooms[current_room].instantiate()
	current_room += 1
	add_child(current_room_asset)
	current_room_asset.global_position = Vector2.ZERO
	player.global_position = current_room_asset.get_child(0).global_position
	
	if current_room == rooms.size()-1: 
		$Transitions.position.x += 48

	if current_room == rooms.size():
		MusicManager.play_boss()
	else:
		MusicManager.play_room()

func _on_transition_body_entered(body: Node2D) -> void:
	if !body.is_in_group("player"): 
		return
		
	body.is_dashing = false
	body.can_dash = true
	
	var required_kills = enemy_per_room[clamp(current_room - 1, 0, enemy_per_room.size() - 1)]
	
	if enemies_killed >= required_kills:
		player.audio_clashes.stream = player.door_sound
		player.audio_clashes.play()
		fade_screen()
