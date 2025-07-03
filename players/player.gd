extends CharacterBody3D

var area_debug = false
var debug = true

enum player_state {
	IDLE,
	RUNNING,
	JUMPING,
	SPIKING,
	RECEIVING,
	FRONT_SETTING,
	DIVING,
}

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

@onready var state := player_state.IDLE
@onready var mode = {"spike": [-0.2, spike_velocity], "receive": [3.5, receive_velocity], \
	"front_set": [3, front_set_velocity], "dive": [999, dive_velocity]}
@onready var mode_name_to_state = {
	"spike": player_state.SPIKING,
	"receive": player_state.RECEIVING,
	"front_set": player_state.FRONT_SETTING,
	"dive": player_state.DIVING
}

@onready var doing_dive = false
@onready var dive_direction : Vector3
@onready var can_hit = true
@onready var hit_cooldown = 0.1
@onready var cam := $camera
@onready var ball_scene := preload("res://balls/ball.tscn")
@onready var in_spike_area := {}
@onready var in_receive_area := {}
@onready var in_front_set_area := {}
@onready var in_dive_area := {}


func set_state(new_state: player_state) -> void:
	if state != new_state:
		state = new_state
		if debug: print(new_state)


func is_state(s: player_state) -> bool:
	return state == s


func _process(_delta: float) -> void:
	$camera_pivot.rotation.y = cam.rotation.y


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if is_state(player_state.IDLE):
			set_state(player_state.JUMPING)
		velocity += player_gravity * delta
		move_and_slide()
		return
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized().rotated(Vector3.UP, cam.global_rotation.y)

	match state:
		player_state.IDLE, player_state.RUNNING:
			if Input.is_action_just_pressed("jump"):
				velocity.y = jump_speed
				set_state(player_state.JUMPING)
			elif Input.is_action_just_pressed("dive"):
				dive(direction)
				set_state(player_state.DIVING)
			elif direction:
				set_state(player_state.RUNNING)
				velocity = velocity.move_toward(direction * max_speed, delta * acceleration)
			else:
				set_state(player_state.IDLE)
				velocity = velocity.move_toward(Vector3.ZERO, delta * acceleration)
		
		player_state.DIVING:
			if doing_dive:
				velocity = dive_direction * dive_speed
				velocity.y = 0
			else:
				velocity = velocity.move_toward(Vector3.ZERO, delta * acceleration)
		
		player_state.JUMPING:
			if is_on_floor():
				if velocity.length():
					set_state(player_state.RUNNING)
				else:
					set_state(player_state.IDLE)
		
		_:
			if direction:
				velocity = velocity.move_toward(direction * max_speed, delta * acceleration)
			else:
				velocity = velocity.move_toward(Vector3.ZERO, delta * acceleration)
	
	move_and_slide()


func dive(_dive_dir: Vector3):
	doing_dive = true
	dive_direction = _dive_dir

	var dive_duration = 0.1
	await get_tree().create_timer(dive_duration).timeout
	doing_dive = false
	
	var dive_cooldown = 0.4
	await get_tree().create_timer(dive_cooldown).timeout

	set_state(player_state.IDLE)


func spawn_ball():
	var ball = ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3(0, 5, 0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spwan_ball"):
		spawn_ball()
	
	match state:
		player_state.IDLE, player_state.RUNNING:
			if event.is_action_pressed("spike_or_receive"):
				perform_hit(in_receive_area, "receive")
			elif event.is_action_pressed("front_set"):
				perform_hit(in_front_set_area, "front_set")
		
		player_state.JUMPING:
			if event.is_action_pressed("spike_or_receive"):
				perform_hit(in_spike_area, "spike")

		player_state.DIVING:
			if in_dive_area:
				perform_hit(in_dive_area, "dive", false)


func perform_hit(bodies: Dictionary, mode_name: String, set_idle=true) -> void:
	if mode_name not in mode:
		print("mode_name invalid")
		return

	set_state(mode_name_to_state[mode_name])

	var id = get_instance_id()
	var cam_forward = -cam.global_transform.basis.z.normalized()
	cam_forward.y = mode[mode_name][0]
	cam_forward = cam_forward.normalized()

	for b in bodies.keys():
		if not b.is_in_group("balls"):
			print(b, " is not ball")
			return
		
		if id in b.hitters:
			print("in hit cooldown")
			continue
		else:
			b.reg_hitter(id)
		b.linear_velocity = cam_forward * mode[mode_name][1]
	
	if set_idle:
		can_hit = false
		await get_tree().create_timer(hit_cooldown).timeout
		print("NAH")
		can_hit = true
		set_state(player_state.IDLE)
			

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
