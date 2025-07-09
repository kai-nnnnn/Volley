extends CharacterBody3D

var area_debug = false
var debug = false

enum player_state {
	IDLE,
	RUNNING,
	JUMPING,
	SPIKING,
	RECEIVING,
	FRONT_SETTING,
	DIVING,
	BLOCKING
}

enum hand {
	LEFT,
	RIGHT
}

@export var dominant_hand = hand.RIGHT

@export var crush_delta := -0.15

@onready var id = get_instance_id()
@onready var state := player_state.IDLE
@onready var mode_name_to_state = {
	"spike": player_state.SPIKING,
	"receive": player_state.RECEIVING,
	"front_set": player_state.FRONT_SETTING,
	"dive": player_state.DIVING,
	"block": player_state.BLOCKING
}
@onready var changable_state = [player_state.IDLE, player_state.RUNNING, player_state.JUMPING]

@onready var doing_dive = false
@onready var dive_direction : Vector3

@onready var cam := $camera
@onready var ball_scene := preload("res://balls/ball.tscn")
@onready var in_spike_area := {}
@onready var in_receive_area := {}
@onready var in_front_set_area := {}
@onready var in_dive_area := {}
@onready var in_block_area := {}


func reset_state() -> void:
	if not is_on_floor():
		state = player_state.JUMPING
	elif velocity:
		state = player_state.RUNNING
	else:
		state = player_state.IDLE


func set_state(new_state: player_state, cooldown=0.0) -> void:
	if state != new_state and state in changable_state:
		state = new_state
		DebugPrint.dprint(debug, ["state: ", new_state, " cooldown: ", cooldown])
		if cooldown:
			await get_tree().create_timer(cooldown).timeout
			reset_state()


func is_state(s: player_state) -> bool:
	return state == s


func _ready() -> void:
	match dominant_hand:
		hand.LEFT:
			$camera_pivot/spike_area.position.x = -0.5
		
		hand.RIGHT:
			$camera_pivot/spike_area.position.x = 0.5


func _process(_delta: float) -> void:
	if is_on_floor():
		$camera_pivot.rotation.y = cam.rotation.y
	
	match state:
		player_state.SPIKING:
			perform_hit(in_spike_area, "spike")
		player_state.RECEIVING:
			perform_hit(in_receive_area, "receive")
		player_state.FRONT_SETTING:
			perform_hit(in_front_set_area, "front_set")
		player_state.DIVING:
			perform_hit(in_dive_area, "dive", false)
		player_state.BLOCKING:
			perform_block(in_block_area)
			


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if is_state(player_state.IDLE):
			set_state(player_state.JUMPING)
		velocity += VBConst.gravity * delta
		move_and_slide()
		return
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0, input_dir.y).normalized().rotated(Vector3.UP, cam.global_rotation.y)

	match state:
		player_state.IDLE, player_state.RUNNING:
			if Input.is_action_just_pressed("jump"):
				velocity.y = VBConst.jump_speed
				set_state(player_state.JUMPING)
			elif Input.is_action_just_pressed("dive"):
				dive(direction)
				set_state(player_state.DIVING)
			elif direction:
				set_state(player_state.RUNNING)
				velocity = velocity.move_toward(direction * VBConst.max_speed, delta * VBConst.acceleration)
			else:
				set_state(player_state.IDLE)
				velocity = velocity.move_toward(Vector3.ZERO, delta * VBConst.acceleration)
		
		player_state.DIVING:
			if doing_dive:
				velocity = dive_direction * VBConst.dive_speed
				velocity.y = 0
			else:
				velocity = velocity.move_toward(Vector3.ZERO, delta * VBConst.acceleration)
		
		player_state.JUMPING:
			if is_on_floor():
				if velocity:
					set_state(player_state.RUNNING)
				else:
					set_state(player_state.IDLE)
		
		_:
			if direction:
				velocity = velocity.move_toward(direction * VBConst.max_speed, delta * VBConst.acceleration)
			else:
				velocity = velocity.move_toward(Vector3.ZERO, delta * VBConst.acceleration)
	
	move_and_slide()


func dive(_dive_dir: Vector3) -> void:
	doing_dive = true
	dive_direction = _dive_dir

	var dive_duration = 0.1
	await get_tree().create_timer(dive_duration).timeout
	doing_dive = false
	
	var dive_cooldown = 0.4
	await get_tree().create_timer(dive_cooldown).timeout

	# state goes from dive -> normal
	reset_state()


func block() -> void:
	$camera_pivot/block_area.monitoring = true
	while not is_on_floor():
		await get_tree().process_frame
	$camera_pivot/block_area.monitoring = false
	# state goes from block -> normal
	reset_state()


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
				set_state(player_state.RECEIVING, VBConst.hit_cooldown)
			elif event.is_action_pressed("front_set"):
				set_state(player_state.FRONT_SETTING, VBConst.hit_cooldown)	
		player_state.JUMPING:
			if event.is_action_pressed("spike_or_receive"):
				set_state(player_state.SPIKING, VBConst.hit_cooldown)
			elif event.is_action_pressed("block"):
				set_state(player_state.BLOCKING)
				block()
			
			# i will keep jump set off because it's very powerful
			# elif event.is_action_pressed("front_set"):
				# set_state(player_state.FRONT_SETTING, hit_cooldown)


func perform_hit(bodies: Dictionary, mode_name: String, set_idle=true) -> void:
	if mode_name not in VBConst.mode:
		DebugPrint.dprint(debug, ["mode_name invalid"])
		return

	if not bodies:
		# DebugPrint.dpring(debug, ["no balls"])
		return

	# set_state(mode_name_to_state[mode_name])

	var hit_angle = -$camera_pivot.global_transform.basis.z.normalized()
	hit_angle.y = VBConst.mode[mode_name][0]
	match state:
		player_state.SPIKING:
			if Input.is_action_pressed("move_forward"):
				hit_angle.y += crush_delta
			elif Input.is_action_pressed("move_back"):
				hit_angle.y -= crush_delta
		
		_:
			pass

	hit_angle = hit_angle.normalized()

	for b in bodies.keys():
		if not b.is_in_group("balls"):
			DebugPrint.dprint(debug, [b, " is not ball"])
			return
		
		if id in b.hitters:
			DebugPrint.dprint(debug, ["in hit cooldown"])
			continue
		else:
			b.reg_hitter(id)
		b.linear_velocity = hit_angle * VBConst.mode[mode_name][1]
	
	if set_idle:
		await get_tree().create_timer(VBConst.hit_cooldown).timeout
		set_state(player_state.IDLE)


func perform_block(bodies: Dictionary) -> void:
	if not bodies:
		return

	const bounce_factor = 0.5
	var hit_angle = -$camera_pivot.global_transform.basis.z.normalized()
	hit_angle.y += 0.1 + randf() * 0.1
	hit_angle = hit_angle.normalized()

	for b in bodies.keys():
		if not b.is_in_group("balls"):
			DebugPrint.dprint(debug, [b, " is not ball"])
			return
		
		if id in b.hitters:
			DebugPrint.dprint(debug, ["in hit cooldown"])
			continue
		else:
			b.reg_hitter(id)
		
		var bpos = b.global_position; var ppos = global_position
		bpos.y = 0; ppos.y = 0
		var horizontal_distance = bpos.distance_to(ppos)
		var fail_chance = clamp(horizontal_distance / VBConst.max_block_range, 0.0, 1.0)
		fail_chance = pow(fail_chance, 1.7)

		DebugPrint.dprint(true, ["Block dist: ", horizontal_distance, " Fail chance: ", fail_chance])
		if randf() < fail_chance:
			var slow_factor = clamp(fail_chance, 0.3, 1.0)
			b.linear_velocity *= slow_factor
			b.linear_velocity.y += (1 - slow_factor) * 3
			DebugPrint.dprint(debug, ["FAILED BLOCK"])
		else:
			DebugPrint.dprint(debug, ["SUCCESS BLOCK"])
			b.linear_velocity = b.linear_velocity.bounce(hit_angle) * bounce_factor

func _on_spike_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		DebugPrint.dprint(area_debug, ["ball enter spike area"])
		in_spike_area[body] = 0
		

func _on_spike_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_spike_area.has(body):
		in_spike_area.erase(body)


func _on_receive_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		DebugPrint.dprint(area_debug, ["ball enter receive area"])
		in_receive_area[body] = 0


func _on_receive_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_receive_area.has(body):
		in_receive_area.erase(body)


func _on_front_set_area_body_entered(body:Node3D) -> void:
	if body.is_in_group("balls"):
		DebugPrint.dprint(area_debug, ["ball enter front set area"])
		in_front_set_area[body] = 0


func _on_front_set_area_body_exited(body:Node3D) -> void:
	if body.is_in_group("balls") and in_front_set_area.has(body):
		in_front_set_area.erase(body)

		
func _on_dive_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("balls"):
		DebugPrint.dprint(area_debug, ["ball enter dive area"])
		in_dive_area[body] = 0


func _on_dive_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("balls") and in_dive_area.has(body):
		in_dive_area.erase(body)


func _on_block_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("balls"):
		DebugPrint.dprint(area_debug, ["ball enter block area"])
		in_block_area[body] = 0


func _on_block_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("balls") and in_block_area.has(body):
		in_block_area.erase(body)
