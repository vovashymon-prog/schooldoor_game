class_name Enemy
extends CharacterBody2D

@export var speed := 40
@export var acceleration := 2000.0
@export var flanking_mult := 2.0
@export var max_swing := 0.0
@export var clash_cd := 0.1
var current_sword_speed : float
var inverted_spinning := false
var is_sword_stunned := false
var turned_recently := false
@export var is_invertable := true
@export var sword_pushable := false

@onready var health_component : HealthComponent = $HealthComponent
@onready var orbit_component : OrbitComponent = $OrbitComponent
@onready var clash_timer : Timer = $ClashCD
@onready var player : Player = get_tree().get_first_node_in_group("player")
@export var target : Node2D

@export var sword_item: Item
@onready var sprite = $Sprite2D
@onready var axis = $axis
#@onready var sword = $axis
@onready var audio = $Audio
var player_orbit
var bobber
var clash_sound = preload("res://audio/Sword/ThoSwordsHit_1.wav")
var hit_sound = preload("res://audio/Sword/FleshHit.wav")
var critical_sound = preload("res://audio/Sword/Critical hit.wav")

var damage_tween : Tween
var recovery_tween : Tween

var blood_particles_low = preload("res://scenes/particles/basic_hit_blood.tscn")
var blood_particles_high = preload("res://scenes/particles/lethal_hit_blood_clown.tscn")

signal defeated

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

func take_damage(amount) -> bool:
	if !is_instance_valid(health_component): return false
	
	var damaged = health_component.take_damage(amount)
	# SOUND BELOW IS A TEMPORARY DECISION
	if is_instance_valid(player) && damaged:
		player.audio_hits.stream = player.hit_sound
		player.audio_hits.play()
	return damaged

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
	if is_instance_valid(orbit_component):
		#The direction is randomized with default -1 mult
		if randf() > 0.5:
			orbit_component.multiply_spinning_speed()
	if is_instance_valid(sword_item): 
		current_sword_speed = sword_item.base_speed
		axis.get_child(0).texture = sword_item.texture
		axis.get_child(1).scale.x *= sword_item.length / 16.0
		axis.get_child(2).scale.x *= sword_item.length / 16.0
		for ch in axis.get_children(): ch.position.x += (sword_item.length - 16.0) / 2
	
	if is_instance_valid(player):
		if target == null:
			target = player
		player.connect_enemy(self)
		if max_swing != 0.0:
			axis.look_at(target.global_position)
	if target:
		orbit_component.set_target(target)

func stun_sword(time = 0.33):
	is_sword_stunned = true
	await get_tree().create_timer(time).timeout
	if not is_instance_valid(self): return
	is_sword_stunned = false

func handle_clash(hit_side: int): #1 = right side, -1 = left_side
	if !clash_timer.is_stopped() || !is_instance_valid(sword_item): return
	
	clash_timer.start(clash_cd)
	
	if sword_pushable:
		if hit_side == 1 && current_sword_speed > 0 || hit_side == -1 && current_sword_speed < 0:
			current_sword_speed *= -4
		elif hit_side == 1 && current_sword_speed < 0 || hit_side == -1 && current_sword_speed > 0:
			current_sword_speed *= 4
		recover_sword_speed()
	if is_invertable:
		if hit_side == 1 && inverted_spinning || hit_side == -1 && !inverted_spinning:
			inverted_spinning = not inverted_spinning

func recover_sword_speed():
	if recovery_tween && recovery_tween.is_running():
		recovery_tween.kill()
	
	recovery_tween = create_tween()
	recovery_tween.tween_property(self, "current_sword_speed", sword_item.base_speed, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	# WALKING
	if !is_instance_valid(target): return
	if !is_instance_valid(orbit_component):
		print("Error, please add orbit components to all enemies")
		return
	var direction = (target.global_position - global_position).normalized()
	var player_dist = global_position.distance_to(target.global_position)
	if player_dist - 10.0 > orbit_component.orbiting_distance:
		orbit_component.deactivate()
		velocity = velocity.move_toward(direction * speed, acceleration * delta * 10)
	else:
		orbit_component.activate()
		direction = (orbit_component.get_target_position() - global_position).normalized()
		velocity = velocity.move_toward(direction * speed * flanking_mult, acceleration * delta * 10)
	
	move_and_slide()
	face_direction(direction)

func process_turn():
	turned_recently = true
	await get_tree().create_timer(0.1).timeout
	if !is_instance_valid(self): return
	turned_recently = false

func face_direction(direction):
	if turned_recently: return
	process_turn()
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
	if !is_instance_valid(player) || is_sword_stunned: return
	if max_swing == 0:
		if !inverted_spinning: axis.rotation += current_sword_speed * delta
		elif inverted_spinning: axis.rotation -= current_sword_speed * delta
	else:
		var playerDir = (player.global_position - global_position)
		var playerAngle = playerDir.angle()
		var old_axis_rot = axis.rotation
		axis.rotation = rotate_toward(axis.rotation, playerAngle, current_sword_speed * delta)
		var axis_delta = axis.rotation - old_axis_rot
		axis.rotation -= axis_delta
		if abs(axis.rotation) >= max_swing + PI / 18: 
			inverted_spinning = not inverted_spinning
			axis.rotation = (max_swing - 0.01) * sign(axis.rotation)
		if !inverted_spinning: axis.rotation -= current_sword_speed * delta
		else: axis.rotation += current_sword_speed * delta

func _on_sword_body_entered(body: Node2D) -> void:
	if !is_instance_valid(sword_item): return
	if body.is_in_group("player"):
		body.take_damage(sword_item.power)


func _on_sword_right_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_weapons"):
		handle_clash(1)


func _on_sword_left_area_entered(area: Area2D) -> void:
	if area.is_in_group("p_weapons"):
		handle_clash(-1)
