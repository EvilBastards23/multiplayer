extends Control



func _ready() -> void:
	$play.connect("pressed",on_play_button_pressed)
	$exit.connect("pressed",on_exit_button)

func on_play_button_pressed()->void:
	get_tree().change_scene_to_file("res://lobby.tscn")

func on_exit_button()->void:
	queue_free()
