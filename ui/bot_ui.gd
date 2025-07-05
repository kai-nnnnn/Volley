extends Control

var bot_spawn_debug = true
@onready var practice_bot_scene = preload("res://bots/practice_bot.tscn")
@onready var bot_lists : Array

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_setter_bot_spawn_pressed() -> void:
	var player = get_node("/root/world/player")
	var cam = get_node("/root/world/player/camera_pivot")
	
	var pos = player.position
	var rot = cam.rotation
	
	var bot = practice_bot_scene.instantiate()
	get_tree().current_scene.add_child(bot)
	bot.set_bot(pos, rot, bot.bot_mode.SETTER, "id")
	bot_lists.append(bot)
	DebugPrint.dprint(bot_spawn_debug, ["setter bot spawned"])


func _on_spiker_bot_spawn_pressed() -> void:
	var player = get_node("/root/world/player")
	var cam = get_node("/root/world/player/camera_pivot")
	
	var pos = player.position
	pos.y += 0.2
	var rot = cam.rotation
	
	var bot = practice_bot_scene.instantiate()
	get_tree().current_scene.add_child(bot)
	bot.set_bot(pos, rot, bot.bot_mode.SPIKER, "id")
	bot_lists.append(bot)
	DebugPrint.dprint(bot_spawn_debug, ["spiker bot spawned"])


func _on_remove_all_bots_pressed() -> void:
	for bot in bot_lists:
		bot.queue_free()
	bot_lists.clear()
