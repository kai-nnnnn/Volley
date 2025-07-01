extends CharacterBody3D

@export var acceleration := 30.0
@export var max_speed := 5.0
@export var jump_velocity := 10.0
@export var player_gravity := Vector3(0.0, -30.0, 0.0)
@export var spike_velocity := 15.0
@export var receive_velocity := 3.0
@export var front_set_velocity := 2.5

var mode = {"spike": [-0.2, spike_velocity], "receive": [3.5, receive_velocity], \
	"front_set": [3.5, front_set_velocity]}

@onready var cam := $camera
@onready var ball_scene := preload("res://scenes/ball.tscn")
@onready var in_spike_area := {}
@onready var in_receive_area := {}
@onready var in_front_set_area := {}


func _process(_delta: float) -> void:
	$camera_pivot.rotation.y = cam.rotation.y


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


func _on_spike_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		print("spike in")
		in_spike_area[body] = 0
		

func _on_spike_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_spike_area.has(body):
		in_spike_area.erase(body)


func _on_receive_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		print("receive in")
		in_receive_area[body] = 0


func _on_receive_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_receive_area.has(body):
		in_receive_area.erase(body)


func _on_front_set_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		print("front set in")
		in_front_set_area[body] = 0



func _on_front_set_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_front_set_area.has(body):
		in_front_set_area.erase(body)

		
func perform_hit(body:Node3D, mode_name:String) -> void:
	if not body.is_in_group("balls"):
		print("body is not ball")
		return

	if mode_name not in mode:
		print("mode_name invalid")
		return

	var cam_forward = -cam.global_transform.basis.z.normalized()
	cam_forward.y = mode[mode_name][0]
	cam_forward.normalized()
	body.linear_velocity = cam_forward * mode[mode_name][1]

