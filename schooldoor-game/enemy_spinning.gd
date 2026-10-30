extends CharacterBody2D

@export var speed = 100
@export var accelration = 20.0
@export var max_hp := 100
var hp := 100
var inverted_spinning := false
var is_invul := false

@export var sword_item: Item
@onready var sword = $sword

var input: Vector2

func process_invul():
	is_invul = true
	await get_tree().create_timer(0.33).timeout
	is_invul = false

func take_damage(amount):
	if !is_invul:
		hp -= amount
		print(hp)
		process_invul()
		if hp <= 0:
			queue_free()
		else:
			pass

func _ready():
	if sword_item: sword.get_child(0).texture = sword_item.texture

func _process(delta):
	# WALKING
	
	# SWORD
	#var direction = global_position.direction_to(get_global_mouse_position())
	#var angle = direction.angle()
	if sword_item && !inverted_spinning: sword.rotation += -sword_item.speed * delta
	elif sword_item && inverted_spinning: sword.rotation += sword_item.speed * delta


func _on_sword_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(sword_item.power)
