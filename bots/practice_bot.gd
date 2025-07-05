extends CharacterBody3D

var debug = true

enum bot_mode {
	SETTER,
	SPIKER
}

@export var front_set_velocity := 8.0
@export var spike_velocity := 15.0
@export var jump_speed := 10.0
@export var bot_gravity := Vector3(0.0, -30.0, 0.0)
var g = abs(bot_gravity.y)
@onready var spike_height = $MeshInstance3D.get_aabb().size.y + $pivot/spike_area.position.y + $pivot/spike_area/CollisionShape3D.shape.size.y
var jump_max_height = 0.5 * (jump_speed ** 2) / g 


@onready var mode_num_to_word = {bot_mode.SETTER: "front_set", bot_mode.SPIKER: "spike"}
@onready var mode = {"spike": [-0.25, spike_velocity], "front_set": [3, front_set_velocity]}

@onready var ball_scene := preload("res://balls/ball.tscn")

@onready var active_mode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# DebugPrint.dprint(debug, [jump_max_height])
	pass


func _physics_process(delta: float) -> void:
	if active_mode == bot_mode.SETTER:
		return

	if not is_on_floor():
		velocity += bot_gravity * delta

	move_and_slide()


func ball_is_lower_than(body:Node3D, height:int):
	while body.position.y > height:
		await get_tree().process_frame


func set_bot(pos:Vector3, rot:Vector3, target_mode:int, bot_name:String):
	print(pos, rot)
	global_position = pos
	global_rotation = rot
	active_mode = target_mode
	name = bot_name
	start(mode_num_to_word[target_mode])

func spawn_ball() -> Node3D:
	var ball = ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3(0, 5, 0)
	return ball


func start(mode_name:String):
	while true:
		var ball = spawn_ball()

		match mode_name:
			"spike":
				await ball_is_lower_than(ball, jump_max_height + spike_height)
				velocity.y = jump_speed
				ball = await $pivot/spike_area.body_entered

			"front_set":
				ball = await $pivot/front_set_area.body_entered

		if not ball.is_in_group("balls"):
			DebugPrint.dprint(debug, ["body is not ball"])
			return

		var hit_angle = -$pivot.global_transform.basis.z.normalized()
		hit_angle.y = mode[mode_name][0]
		hit_angle = hit_angle.normalized()
		ball.linear_velocity = hit_angle * mode[mode_name][1]

		await ball.ball_hit_ground	
