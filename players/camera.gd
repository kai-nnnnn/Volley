extends Camera3D

@export var spring_arm: Node3D
@export var lerp_power := 8.0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = lerp(position, spring_arm.position, delta*lerp_power)
