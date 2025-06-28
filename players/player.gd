extends CharacterBody3D

@export var acceleration := 30.0
@export var max_speed := 5.0
@export var jump_velocity := 10.0
@export var player_gravity := Vector3(0.0, -30.0, 0.0)

@onready var cam := $camera

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += player_gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	direction = direction.rotated(Vector3.UP, cam.global_rotation.y)
	
	if direction:
		direction *= max_speed
		velocity.x = move_toward(velocity.x, direction.x, delta * acceleration)
		velocity.z = move_toward(velocity.z, direction.z, delta * acceleration)
	else:
		velocity.x = move_toward(velocity.x, 0, delta * acceleration)
		velocity.z = move_toward(velocity.z, 0, delta * acceleration)
	
	move_and_slide()
