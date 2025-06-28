extends Node3D

@export var mouse_sensitivity := 0.001
@export_range(-90.0, 0.0, 0.1, "radians_as_degrees") var min_vert_angle := -PI/4
@export_range(0.0, 90.0, 0.1, "radians_as_degrees") var max_vert_angle := PI/4

@onready var spring_arm := $camera_spring_arm

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.y = wrapf(rotation.y, 0, TAU)
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clamp(rotation.x, min_vert_angle, max_vert_angle)
	
	if event.is_action_pressed("wheel_up"):
		spring_arm.spring_length -= 1
	if event.is_action_pressed("wheel_down"):
		spring_arm.spring_length += 1
	spring_arm.spring_length = clamp(spring_arm.spring_length, 2, 8)
	
	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	


func _physics_process(delta: float) -> void:
	pass
