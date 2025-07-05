extends CanvasLayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child_ui in get_children():
		child_ui.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_bot_ui"):
		if $bot_ui.visible:
			$bot_ui.visible = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			$bot_ui.visible = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
