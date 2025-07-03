extends Node

var global_debug = true;

func dprint(is_debug: bool, msg_arr: Array) -> void:
	if not global_debug or not is_debug:
		return 

	for msg in msg_arr:
		msg = str(msg)
	
	print("".join(msg_arr))
