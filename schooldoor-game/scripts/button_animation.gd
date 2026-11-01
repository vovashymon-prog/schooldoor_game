extends Button

@onready var original_scale: Vector2 = scale

func _ready() -> void:
	pivot_offset = size / 2

func _on_mouse_entered() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.15)
	tween.tween_property(self, "modulate", Color(1.3, 1.0, 1.0), 0.15)

func _on_mouse_exited() -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", original_scale, 0.15)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.15)
