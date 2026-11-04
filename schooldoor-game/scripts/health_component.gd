class_name HealthComponent
extends Node2D

@export var max_hp := 100
var hp := 100
var is_invul := false
@onready var invul_timer = $Timer

signal health_changed(new_hp: int, max_hp: int)
signal died
signal damaged(amount: int)

func _ready():
	hp = max_hp
	health_changed.emit(hp, max_hp)

func take_damage(amount, duration := 0.33):
	if !is_invul:
		hp -= amount
		process_invul(duration)
		if hp <= 0:
			hp = 0
			died.emit()
		else:
			damaged.emit(amount)
		health_changed.emit(hp, max_hp)

func process_invul(duration := 0.33):
	is_invul = true
	invul_timer.start(duration)

func heal(amount):
	hp += amount
	if hp > max_hp: hp = max_hp
	health_changed.emit(hp, max_hp)

func _on_invul_timer_timeout() -> void:
	is_invul = false
