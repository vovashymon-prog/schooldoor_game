extends Area2D

@export var power = 50

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") && body.has_method("heal"):
		body.heal(power)
		queue_free()
