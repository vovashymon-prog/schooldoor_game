extends Area2D

@export var power = 50

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.hp += power
		body.update_hp_bar()
		body.audio_hits.stream = body.heal_sound
		body.audio_hits.play()
		queue_free()
