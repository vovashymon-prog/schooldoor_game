extends CharacterBody2D

@export var speed = 0.5
@export var accelration = 20.0
@export var circling_speed = PI / 6
@export var circling_distance = 30
@export var flanking_mult = 3.0
@export var max_swing = 0.0
@export var max_hp := 100
var hp := 100
var inverted_spinning := false
var is_invul := false
var is_sword_stunned := false
@export var is_invertable := true

@export var sword_item: Item
@onready var sprite = $Sprite2D
@onready var axis = $axis
@onready var sword = $axis/sword
@onready var audio = $Audio
var player_orbit
var bobber
@onready var player = get_tree().get_first_node_in_group("player")
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/FleshHit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var blood_particles_low = preload("res://scenes/particles/basic_hit_blood.tscn")
var blood_particles_high = preload("res://scenes/particles/lethal_hit_blood_clown.tscn")

var input: Vector2

func process_invul():
	is_invul = true
	await get_tree().create_timer(0.33).timeout
	is_invul = false

func take_damage_anim():
	var tween = get_tree().create_tween()
	tween.tween_property(sprite, "modulate", Color(7.759, 7.759, 7.759, 1.0), 0.16)
	tween.play()
	await tween.finished; tween.kill(); tween = create_tween()
	tween.tween_property(sprite, "modulate", Color("ffffffff"), 0.16)
	tween.play()

func take_damage(amount):
	if !is_invul:
		hp -= amount
		take_damage_anim()
		print(hp)
		process_invul()
		if hp <= 0:
			hp = 0
			if player != null: 
				player.audio_hits.stream = critical_sound
				player.audio_hits.play()
				player.drop_count += 1
			var blood = blood_particles_high.instantiate()
			get_parent().add_child(blood)
			blood.global_position = global_position
			blood.emitting = true
			var main = get_tree().get_first_node_in_group("main")
			if main != null: main.enemies_killed += 1
			queue_free()
		else:
			if player != null: 
				player.audio_hits.stream = hit_sound
				player.audio_hits.play()
			var blood = blood_particles_low.instantiate()
			get_parent().add_child(blood)
			blood.global_position = global_position
			blood.emitting = true

func _ready():
	hp = max_hp
	if sword_item: sword.get_child(0).texture = sword_item.texture
	if max_swing != 0.0:
		var playerDir = (player.global_position - global_position)
		sword.look_at(playerDir)

func create_orbit():
	if player_orbit != null && bobber != null: return
	player_orbit = Node2D.new()
	bobber = Node2D.new()
	player_orbit.add_child(bobber)
	player.add_child(player_orbit)
	player_orbit.position = Vector2.ZERO
	bobber.position = Vector2(circling_distance - 5.5, 0)

func clear_orbit():
	if player_orbit != null: player_orbit.queue_free()
	player_orbit = null
	if bobber != null: bobber.queue_free()
	bobber = null

func stun_sword(time = 0.33):
	is_sword_stunned = true
	await get_tree().create_timer(time).timeout
	is_sword_stunned = false

func _physics_process(delta: float) -> void:
	# WALKING
	var direction = player.global_position - global_position
	if direction.length() > circling_distance:
		velocity = lerp(velocity, direction * speed, accelration * delta)
		move_and_slide()
		clear_orbit()
	else:
		create_orbit()
		player_orbit.rotation += circling_speed * delta
		direction = bobber.global_position - global_position
		velocity = lerp(velocity, direction * speed * flanking_mult, clamp((accelration * delta * 10), 0.0, 1.0))
		move_and_slide()
	face_direction(direction)

func face_direction(direction):
	match int(sign(direction.x)):
		1:
			sprite.scale.x = 1
		-1:
			sprite.scale.x = -1
	if abs(direction.x) > abs(direction.y):
		if !is_invertable: sprite.texture = preload("res://sprites/Clown/Clown_Side.png")
		else: sprite.texture = preload("res://sprites/Clown/Clown_Side2.png")
	elif direction.y >= 0:
		if !is_invertable: sprite.texture = preload("res://sprites/Clown/Clown_Front.png")
		else: sprite.texture = preload("res://sprites/Clown/Clown_front_2.png")
	else:
		if !is_invertable: sprite.texture = preload("res://sprites/Clown/Clown_Back.png")
		else: sprite.texture = preload("res://sprites/Clown/Clown_Back2.png")


func _process(delta):
	# SWORD
	if is_sword_stunned: return
	if max_swing == 0:
		if sword_item && !inverted_spinning: sword.rotation += -sword_item.speed * delta
		elif sword_item && inverted_spinning: sword.rotation += sword_item.speed * delta
	else:
		var playerDir = (player.global_position - global_position)
		var playerAngle = playerDir.angle()
		var old_axis_rot = axis.rotation
		axis.rotation = rotate_toward(axis.rotation, playerAngle, sword_item.speed)
		var axis_delta = axis.rotation - old_axis_rot
		sword.rotation -= axis_delta
		if abs(sword.rotation) >= max_swing + PI / 18: 
			inverted_spinning = not inverted_spinning
			sword.rotation = (max_swing - 0.01) * sign(sword.rotation)
		if sword_item && !inverted_spinning: sword.rotation += -sword_item.speed * delta
		elif sword_item && inverted_spinning: sword.rotation += sword_item.speed * delta

func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(sword_item.power)
