# world.gd
extends Node3D



func _ready():
	pass
func get_spawn_point()->Vector3:
	return Vector3(0,0.852,18.223)
	
func get_camera1()->Camera3D:
	return $Camera3D
	
func get_camera2()->Camera3D:
	return $Camera3D2
