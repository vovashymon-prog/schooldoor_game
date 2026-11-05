extends CharacterBody2D

@export var speed := 25
@export var acceleration := 20
@export var damage := 25
@export var flanking_mult := 2.0
var attacking := false
var player_in := false
var inverted_flanking := false
var processing_inversion := false
var processing_state := false

@onready var health_component : HealthComponent = $HealthComponent
@onready var orbit_component : OrbitComponent = $OrbitComponent
@onready var player : Player = get_tree().get_first_node_in_group("player")

@onready var sprite = $Area2D/AnimatedSprite2D
@onready var audio = $Audio
var player_orbit
var bobber
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/FleshHit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var damage_tween : Tween

var blood_particles_low = preload("res://scenes/particles/basic_hit_blood.tscn")
var blood_particles_high = preload("res://scenes/particles/lethal_hit_blood_clown.tscn")

var input: Vector2

signal defeated

# The boss is still a work in progress, the mechanics that are already
# implemented are here to stay, but more will be added

func on_damaged(_amount: int):
	spawn_particles(blood_particles_low)
	take_damage_anim()
func on_died():
	spawn_particles(blood_particles_high)
	die()

func spawn_particles(scene: PackedScene) -> void:
	var blood = scene.instantiate() as CPUParticles2D
	get_parent().add_child(blood)
	blood.global_position = global_position

func take_damage(amount):
	if is_instance_valid(health_component):
		if !attacking || is_instance_valid(player) && player.is_dashing:
			health_component.take_damage(amount)
	# SOUND BELOW IS A TEMPORARY DECISION
	if is_instance_valid(player):
		if !attacking || player.is_dashing:
			player.audio_hits.stream = player.hit_sound
			player.audio_hits.play()

func take_damage_anim():
	if damage_tween && damage_tween.is_running():
		damage_tween.kill()
	
	damage_tween = create_tween()
	damage_tween.tween_property(sprite, "modulate", Color(7.759, 7.759, 7.759, 1.0), 0.16)
	damage_tween.tween_property(sprite, "modulate", Color("ffffffff"), 0.16)

func die():
	#TEMP PART START
	var main = get_tree().get_first_node_in_group("main")
	if main != null: main.enemies_killed += 1
	#TEMP PART END
	defeated.emit()
	queue_free()

func _ready():
	if is_instance_valid(health_component):
		health_component.damaged.connect(on_damaged)
		health_component.died.connect(on_died)
	if is_instance_valid(player): 
		player.dash_power = 1.15
		player.connect_enemy(self)
		orbit_component.set_target(player)

func _physics_process(delta: float) -> void:
	# WALKING
	if !is_instance_valid(player): return
	if !is_instance_valid(orbit_component):
		print("Error, please add orbit components to all enemies")
		return
	var direction = (player.global_position - global_position).normalized()
	if attacking:
		orbit_component.deactivate()
		velocity = velocity.move_toward(direction * speed, acceleration * delta * 10)
		move_and_slide()
	else:
		orbit_component.activate()
		var orbit_direction = (orbit_component.get_target_position() - global_position).normalized()
		if orbit_direction != null:
			velocity = velocity.move_toward(orbit_direction * speed * flanking_mult, acceleration * delta * 10)
			move_and_slide()

func process_inversion():
	processing_inversion = true
	await get_tree().create_timer(randf_range(2, 6)).timeout
	if not is_instance_valid(self): return
	if is_instance_valid(orbit_component):
		orbit_component.multiply_spinning_speed(-0.9, -1.15)
		orbit_component.multiply_orbiting_distance()
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
