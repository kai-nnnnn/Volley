extends Control

func _ready() -> void:
	visible = true  # 遊戲啟動顯示主選單
	

func _on_host_pressed() -> void:
	_close_menu()
	UIToggles.enable_bot_toggle(false)

func _on_join_pressed() -> void:
	_close_menu()
	UIToggles.enable_bot_toggle(false)

func _on_practice_pressed() -> void:
	_close_menu()
	UIToggles.enable_bot_toggle(true)

func _close_menu() -> void:
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
