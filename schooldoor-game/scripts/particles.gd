extends CPUParticles2D

func _ready() -> void:
	emitting = false
	one_shot = true
	local_coords = false
	finished.connect(queue_free)
	
	await get_tree().process_frame
	restart()
