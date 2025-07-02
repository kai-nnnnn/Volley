extends CharacterBody3D

var area_debug = false

@export var acceleration := 30.0
@export var max_speed := 6.0
@export var dive_speed := 12.0
@export var dive_decceleration := 45.0
@export var jump_speed := 10.0
@export var player_gravity := Vector3(0.0, -30.0, 0.0)
@export var spike_velocity := 15.0
@export var receive_velocity := 10.0
@export var front_set_velocity := 8.0
@export var dive_velocity := 10.0

@onready var mode = {"spike": [-0.2, spike_velocity], "receive": [3.5, receive_velocity], \
	"front_set": [3, front_set_velocity], "dive": [999, dive_velocity]}

@onready var do_dive = false
@onready var can_dive = true
@onready var dive_direction : Vector3
@onready var can_hit = true
@onready var hit_cooldown = 0.2
@onready var cam := $camera
@onready var ball_scene := preload("res://balls/ball.tscn")
@onready var in_spike_area := {}
@onready var in_receive_area := {}
@onready var in_front_set_area := {}
@onready var in_dive_area := {}


func _process(_delta: float) -> void:
	$camera_pivot.rotation.y = cam.rotation.y


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += player_gravity * delta
		move_and_slide()
		return
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and can_dive:
		velocity.y = jump_speed
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized()
	
	direction = direction.rotated(Vector3.UP, cam.global_rotation.y)
	
	if Input.is_action_just_pressed("dive") and can_dive:
		dive(direction)

	if do_dive:
		velocity = dive_direction * dive_speed
		velocity.y = 0
	elif not do_dive and not can_dive:
		velocity = velocity.move_toward(Vector3(0, 0, 0), delta * dive_decceleration)
	elif direction:
		direction *= max_speed
		velocity = velocity.move_toward(direction, delta * acceleration)
	else:
		velocity = velocity.move_toward(Vector3(0, 0, 0), delta * acceleration)
	
	move_and_slide()


func dive(_dive_dir: Vector3):
	do_dive = true
	can_dive = false
	dive_direction = _dive_dir

	var dive_duration = 0.1
	await get_tree().create_timer(dive_duration).timeout

	do_dive = false
	
	var dive_cooldown = 0.4
	await get_tree().create_timer(dive_cooldown).timeout

	can_dive = true


func spawn_ball():
	var ball = ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3(0, 5, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spwan_ball"):
		spawn_ball()
	
	if event.is_action_pressed("spike_or_receive"):
		if not is_on_floor():
			for b in in_spike_area:
				perform_hit(b, "spike")
		else:
			for b in in_receive_area:
				perform_hit(b, "receive")		
	elif event.is_action_pressed("front_set"):
		for b in in_front_set_area:
			perform_hit(b, "front_set")
	if not can_dive:
		for b in in_dive_area:
			perform_hit(b, "dive")


func _on_spike_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		if area_debug: print("spike in")
		in_spike_area[body] = 0
		

func _on_spike_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_spike_area.has(body):
		in_spike_area.erase(body)


func _on_receive_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		if area_debug: print("receive in")
		in_receive_area[body] = 0


func _on_receive_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_receive_area.has(body):
		in_receive_area.erase(body)


func _on_front_set_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		if area_debug: print("front set in")
		in_front_set_area[body] = 0


func _on_front_set_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_front_set_area.has(body):
		in_front_set_area.erase(body)

		
func _on_dive_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("balls"):
		if area_debug: print("dive in")
		in_dive_area[body] = 0


func _on_dive_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("balls") and in_dive_area.has(body):
		in_dive_area.erase(body)


func perform_hit(body:Node3D, mode_name:String) -> void:
	if not body.is_in_group("balls"):
		print("body is not ball")
		return
	
	if not body.has_hit:
		print("body doesn't have hits")
		return

	if mode_name not in mode:
		print("mode_name invalid")
		return
	
	if can_hit: 
		can_hit = false
	else:
		return

	body.hits += 1
	print(body.hits)

	var cam_forward = -cam.global_transform.basis.z.normalized()
	cam_forward.y = mode[mode_name][0]
	cam_forward = cam_forward.normalized()
	body.linear_velocity = cam_forward * mode[mode_name][1]

	await get_tree().create_timer(hit_cooldown).timeout
	can_hit = true
