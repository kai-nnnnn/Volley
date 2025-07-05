extends CharacterBody3D

enum bot_mode {
	SETTER,
	SPIKER
}

@onready var ball_scene := preload("res://balls/ball.tscn")

@onready var active_mode: bot_mode

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func set_bot(pos:Vector3, rot:Vector3, target_mode:int, bot_name:String):
	print(pos, rot)
	global_position = pos
	global_rotation = rot
	name = bot_name


func spawn_ball():
	var ball = ball_scene.instantiate()
	get_tree().current_scene.add_child(ball)
	ball.global_position = global_position + Vector3(0, 5, 0)


func setter_mode():
	while true:
		await get_tree().create_timer(4.0).timeout
		spawn_ball()
		
