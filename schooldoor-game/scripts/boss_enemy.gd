extends CharacterBody2D

@export var speed = 0.6
@export var accelration = 20.11
@export var damage = 25
@export var circling_speed = PI / 6
@export var circling_distance = 100
@export var flanking_mult = 2.0
@export var max_hp := 500
var hp := 500
var attacking := false
var player_in := false
var inverted_flanking := false
var processing_inversion := false
var processing_state := false
var is_invul := false

@onready var sprite = $Area2D/AnimatedSprite2D
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
	if player != null: player.dash_power = 1.15

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

func _physics_process(delta: float) -> void:
	# WALKING
	var direction = player.global_position - global_position
	if attacking:
		velocity = lerp(velocity, direction * speed, accelration * delta)
		move_and_slide()
		clear_orbit()
	else:
		create_orbit()
		player_orbit.rotation += circling_speed * delta
		direction = bobber.global_position - global_position
		velocity = lerp(velocity, direction * speed * flanking_mult, clamp((accelration * delta * 10), 0.0, 1.0))
		move_and_slide()

func process_inversion():
	processing_inversion = true
	await get_tree().create_timer(randf_range(2, 6)).timeout
	circling_speed *= randf_range(-1.1, -0.9)
	circling_distance *= randf_range(0.8, 1.2)
	clear_orbit()
	create_orbit()
	processing_inversion = false

func process_state():
	processing_state = true
	await get_tree().create_timer(randf_range(5, 15)).timeout
	if !attacking:
		sprite.play("Spin_Start")
		var old_speed = speed
		speed = 0
		await sprite.animation_finished
		speed = old_speed
		attacking = true
		sprite.play("Spin")
	else:
		attacking = false
		sprite.play("Spin_End")
		var old_speed = speed
		speed = 0
		await sprite.animation_finished
		speed = old_speed
		sprite.play("Idle")
	processing_state = false

func _process(_delta):
	if !processing_inversion && !attacking: process_inversion()
	if !processing_state: process_state()
	if player_in: player.take_damage(damage)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && attacking:
		player_in = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player") && attacking:
		player_in = false
