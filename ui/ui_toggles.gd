extends Node

var can_toggle := false

func _ready() -> void:
	can_toggle = false
	_hide_bot()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func enable_bot_toggle(flag: bool) -> void:
	can_toggle = flag
	if not flag:
		_hide_bot()

func _unhandled_input(event: InputEvent) -> void:
	if not can_toggle:
		return
	if event.is_action_pressed("toggle_bot_ui"):
		_toggle_bot()

# --- 內部工具 ---
func _toggle_bot() -> void:
	var bot := _get_bot()
	if bot == null:
		return
	if bot.visible:
		_hide_bot()
	else:
		_show_bot()

func _show_bot() -> void:
	var bot = _get_bot()
	if bot == null:
		return
	bot.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
func _hide_bot() -> void:
	var bot = _get_bot()
	if bot == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
	bot.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _get_bot() -> CanvasItem:
	return get_tree().get_first_node_in_group("BotUI") as CanvasItem
