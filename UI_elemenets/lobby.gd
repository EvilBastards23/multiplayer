extends Control


var world_scene:PackedScene = preload("res://Core/Scene/world.tscn")


func _ready() -> void:
	pass

func _on_start_pressed() -> void:
	rpc("start_world")
	
@rpc("any_peer","call_local","reliable")
func start_world()->void:
	
	var world = world_scene.instantiate()
	get_parent().get_parent().add_child(world)
	get_parent().get_parent().emit_game_started()
	$".".hide()
