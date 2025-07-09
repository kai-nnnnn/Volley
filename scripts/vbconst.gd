extends Node

class_name VBConst

const acceleration := 30.0
const max_speed := 6.0
const dive_speed := 12.0
const dive_decceleration := 45.0
const jump_speed := 10.0
const gravity := Vector3(0.0, -30.0, 0.0)
const spike_velocity := 14.0
const receive_velocity := 10.0
const front_set_velocity := 8.5
const dive_velocity := 10.0

const mode = {
	"spike": [-0.4, spike_velocity], 
	"receive": [3.5, receive_velocity],
	"front_set": [2.8, front_set_velocity], 
	"dive": [999, dive_velocity]
}
	
const hit_cooldown = 0.3
