extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0
@export var max_hp := 100
@export var dash_power := 1.0
@export var dash_cd := 0.75
var hp := 100
var is_invul := false
var can_dash := true
var is_dashing := false
var dash_dir

@export var sword_item: Item
@onready var sword = $sword
@onready var player_sprite = $Sprite2D
@onready var audio_steps = $Audio_Steps
@onready var audio_hits = $Audio_Hits
@onready var audio_clashes = $Audio_Clashes
@onready var drops = [$CanvasLayer/Drop1, $CanvasLayer/Drop2, $CanvasLayer/Drop3]
@onready var full_drop: Texture = preload("res://sprites/Blood_drop.png")
@onready var empty_drop: Texture = preload("res://sprites/Empty_drop.png")
var drop_count := 3
var door_sound = preload("res://audio/Sword/DoorOpen.wav")
var steps_sound = preload("res://audio/steps/Long steps.wav")
var dash_sound = preload("res://audio/Sword/Dash.wav")
var heal_sound = preload("res://audio/Sword/Healing.wav")
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/FleshHit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var clash_particles = preload("res://scenes/particles/sparks.tscn")
var blood_particles_low = preload("res://scenes/particles/basic_hit_blood.tscn")
var blood_particles_high = preload("res://scenes/particles/lethal_hit_blood_clown.tscn")

var pause_scene = preload("res://scenes/ui/pause_menu.tscn")

var input: Vector2

func _ready():
	hp = max_hp
	if sword_item: 
		sword.get_child(0).texture = sword_item.texture
		sword.get_child(1).scale.x *= sword_item.length / 16.0
		for ch in sword.get_children(): ch.position.x += (sword_item.length - 16.0) / 2
	update_hp_bar()

func process_invul(time = 0.33):
	is_invul = true
	await get_tree().create_timer(time).timeout
	is_invul = false

func update_hp_bar():
	$CanvasLayer/HPBar.value = hp

func flash_anim(col = Color(7.759, 7.759, 7.759, 1.0), time = 0.16):
	var tween = get_tree().create_tween()
	tween.tween_property(player_sprite, "modulate", col, time)
	tween.play()
	await tween.finished; tween.kill(); tween = create_tween()
	tween.tween_property(player_sprite, "modulate", Color("ffffffff"), time)
	tween.play()

func die():
	get_tree().change_scene_to_file("res://scenes/ui/death_screen.tscn")

func take_damage(amount):
	if !is_invul:
		hp -= amount
		update_hp_bar()
		flash_anim()
		print(hp)
		process_invul()
		if hp <= 0:
			hp = 0
			update_hp_bar()
			audio_hits.stream = critical_sound
			audio_hits.play()
			die()
		else:
			audio_hits.stream = hit_sound
			audio_hits.play()

func get_input():
	input.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	input.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	return input.normalized();

func face_input(p_input):
	match int(sign(p_input.x)):
		0: 
			match int(sign(p_input.y)):
				1: 
					player_sprite.texture = preload("res://sprites/Player/Player_Front.png")
					player_sprite.scale.x = 1
				-1: 
					player_sprite.texture = preload("res://sprites/Player/Player_Back.png")
					player_sprite.scale.x = 1
		1:
			match int(sign(p_input.y)):
				0: 
					player_sprite.texture = preload("res://sprites/Player/Player_Profile.png")
					player_sprite.scale.x = 1
				1: 
					player_sprite.texture = preload("res://sprites/Player/Player_Front.png")
					player_sprite.scale.x = 1
				-1: 
					player_sprite.texture = preload("res://sprites/Player/Player_Back.png")
					player_sprite.scale.x = 1
		-1:
			match int(sign(p_input.y)):
				0: 
					player_sprite.texture =preload("res://sprites/Player/Player_Profile.png")
					player_sprite.scale.x = -1
				1: 
					player_sprite.texture = preload("res://sprites/Player/Player_Front.png")
				-1: 
					player_sprite.texture = preload("res://sprites/Player/Player_Back.png")

func resume():
	get_tree().paused = false

func pause():
	get_tree().paused = true
	var pause_menu = pause_scene.instantiate()
	pause_menu.scale = Vector2(0.33, 0.33)
	add_child(pause_menu)

func dash():
	is_dashing = true
	drop_count = 0
	audio_steps.stream = dash_sound
	audio_steps.play()
	dash_dir = global_position.direction_to(get_global_mouse_position())
	process_invul(0.29 * dash_power)
	flash_anim(Color(1.263, 1.166, 0.288, 1.0), 0.12 * dash_power)
	await get_tree().create_timer(0.24 *dash_power).timeout
	is_dashing = false
	await get_tree().create_timer(dash_cd).timeout
	can_dash = true

func refresh_drops():
	match drop_count:
		0: for drop in drops: drop.texture = empty_drop
		1: drops[0].texture = full_drop; drops[1].texture = empty_drop; drops[2].texture = empty_drop
		2: drops[0].texture = full_drop; drops[1].texture = full_drop; drops[2].texture = empty_drop
		3: for drop in drops: drop.texture = full_drop
		_: for drop in drops: drop.texture = full_drop

func _process(delta):
	var player_input = get_input()
	face_input(player_input)
	refresh_drops()
	
	if Input.is_action_just_pressed("pause") && get_tree().paused:
		resume()
	elif Input.is_action_just_pressed("pause"):
		pause()
	# DASHING
	if is_dashing:
		velocity = lerp(velocity, dash_dir * speed * 5, accelration * delta)
		move_and_slide()
		return
	if Input.is_action_just_pressed("dash") && can_dash && drop_count >= 3:
		dash()
		can_dash = false
	# WALKING
	velocity = lerp(velocity, player_input * speed, accelration * delta)
	move_and_slide()
	if player_input != Vector2.ZERO && !audio_steps.playing:
		audio_steps.stream = steps_sound
		audio_steps.play()
	elif player_input == Vector2.ZERO && !is_dashing:
		audio_steps.stop()
	
	# SWORD
	var direction = global_position.direction_to(get_global_mouse_position())
	var angle = direction.angle()
	if sword_item: sword.rotation = rotate_toward(sword.rotation, angle, sword_item.speed * delta)


func _on_sword_area_entered(area: Area2D) -> void:
	if area.is_in_group("e_weapons"):
		var enemy = area.get_parent().get_parent()
		if enemy.is_invertable: enemy.inverted_spinning = not enemy.inverted_spinning
		#if enemy.max_swing != 0.0 && enemy.max_swing - abs(enemy.sword.rotation) <= PI / 20: enemy.stun_sword(0.34)
		audio_clashes.stream = clash_sound
		audio_clashes.play()
		var sparks = clash_particles.instantiate()
		get_parent().add_child(sparks)
		sparks.global_position = (sword.global_position + area.global_position) / 2
		sparks.emitting = true


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") && body.accelration != 20.11:
		body.take_damage(sword_item.power)
		drop_count += 1
	elif !body.is_in_group("enemies"): return
	elif body.accelration != 20.11: return
	elif body.is_in_group("enemies") && !body.attacking || body.is_in_group("enemies") && is_dashing:
		body.take_damage(sword_item.power)
		drop_count += 1
	elif body.is_in_group("enemies"):
		drop_count += 1


func _on_sword_body_exited(body: Node2D) -> void:
	if !body.is_in_group("enemies"): return
	elif body.accelration != 20.11: return
	elif body.is_in_group("enemies") && !body.attacking || body.is_in_group("enemies") && is_dashing:
		body.take_damage(sword_item.power)
		drop_count += 1
	elif body.is_in_group("enemies"):
		drop_count += 1
