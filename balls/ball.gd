extends RigidBody3D

@onready var has_hit_ground = false
@onready var has_hit = true
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
			has_hit_ground = true
			if global_position.z > 0:
				print("positive")
			else:
				print("negative")
