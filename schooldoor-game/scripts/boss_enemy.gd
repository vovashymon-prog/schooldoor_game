extends CharacterBody2D

@export var speed = 0.28
@export var accelration = 20
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

var damage_tween : Tween

var blood_particles_low = preload("res://scenes/particles/basic_hit_blood.tscn")
var blood_particles_high = preload("res://scenes/particles/lethal_hit_blood_clown.tscn")

var input: Vector2

func process_invul(duration := 0.33):
	is_invul = true
	await get_tree().create_timer(duration).timeout
	if not is_instance_valid(self): return
	is_invul = false

func take_damage_anim():
	if damage_tween && damage_tween.is_running():
		damage_tween.kill()
	
	damage_tween = create_tween()
	damage_tween.tween_property(sprite, "modulate", Color(7.759, 7.759, 7.759, 1.0), 0.16)
	damage_tween.tween_property(sprite, "modulate", Color("ffffffff"), 0.16)

func spawn_particles(scene: PackedScene) -> void:
	var blood = scene.instantiate() as CPUParticles2D
	
	blood.one_shot = true
	blood.emitting = false
	blood.local_coords = false
	
	get_parent().add_child(blood)
	blood.global_position = global_position
	
	blood.finished.connect(blood.queue_free)
	
	await get_tree().process_frame
	blood.restart()

func die():
	if is_instance_valid(player): 
		player.dash_power = 1.0
		player.audio_hits.stream = critical_sound
		player.audio_hits.play()
		player.drop_count += 1
		spawn_particles(blood_particles_high)
		var main = get_tree().get_first_node_in_group("main")
		if main != null: main.enemies_killed += 1
		clear_orbit()
		queue_free()

func take_damage(amount, duration = 0.33):
	if !is_invul:
		hp -= amount
		take_damage_anim()
		print(hp)
		process_invul(duration)
		if hp <= 0:
			hp = 0
			die()
		else:
			if is_instance_valid(player): 
				player.audio_hits.stream = hit_sound
				player.audio_hits.play()
			spawn_particles(blood_particles_low)

func _ready():
	hp = max_hp
	if is_instance_valid(player): player.dash_power = 1.15

func create_orbit():
	if player_orbit != null && bobber != null: return
	player_orbit = Node2D.new()
	bobber = Node2D.new()
	player_orbit.add_child(bobber)
	if is_instance_valid(player): player.add_child(player_orbit)
	player_orbit.position = Vector2.ZERO
	bobber.position = Vector2(circling_distance - 5.5, 0)

func clear_orbit():
	if player_orbit != null: player_orbit.queue_free()
	player_orbit = null
	bobber = null

func _physics_process(delta: float) -> void:
	# WALKING
	if !is_instance_valid(player): return
	var direction = player.global_position - global_position
	if attacking:
		velocity = lerp(velocity, direction * speed, clamp((accelration * delta * 10), 0.0, 1.0))
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
	if not is_instance_valid(self): return
	circling_speed *= randf_range(-1.1, -0.9)
	circling_distance *= randf_range(0.8, 1.2)
	clear_orbit()
	create_orbit()
	processing_inversion = false

func process_state():
	processing_state = true
	await get_tree().create_timer(randf_range(5, 15)).timeout
	if not is_instance_valid(self): return
	if !attacking:
		sprite.play("Spin_Start")
		var old_speed = speed
		speed = 0
		await sprite.animation_finished
		if not is_instance_valid(self): return
		speed = old_speed
		attacking = true
		sprite.play("Spin")
	else:
		attacking = false
		sprite.play("Spin_End")
		var old_speed = speed
		speed = 0
		await sprite.animation_finished
		if not is_instance_valid(self): return
		speed = old_speed
		sprite.play("Idle")
	processing_state = false

func _process(_delta):
	if !processing_inversion && !attacking: process_inversion()
	if !processing_state: process_state()
	if player_in && is_instance_valid(player) && attacking: player.take_damage(damage)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in = false
