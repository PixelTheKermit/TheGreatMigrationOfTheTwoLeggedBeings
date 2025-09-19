extends Camera2D


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
	
	var inputCam = Input.get_vector("left", "right", "up", "down")
	position += inputCam * 512 * delta
