extends RigidBody3D

signal ball_hit_ground

@onready var has_hit_ground = false
@onready var hitters = {}
@onready var hits = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 5	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	if has_hit_ground:
		return 

	for node in get_colliding_bodies():
		if node.is_in_group("floor"):
			if global_position.y > 0.5:
				return
			has_hit_ground = true
			emit_signal("ball_hit_ground")
			if global_position.z > 0:
				print("positive")
			else:
				print("negative")


func reg_hitter(hitter: int) -> void:
	hitters[hitter] = true
	await get_tree().create_timer(VBConst.hit_cooldown).timeout
	hitters.erase(hitter)
