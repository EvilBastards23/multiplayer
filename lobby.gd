extends Control

func _ready() -> void:
	$password_dialog/Control/HBoxContainer/confirm.connect("pressed", _on_cancel_pressed)

func _on_host_pressed() -> void:
	get_parent().host()
	_start_game()  # Start game after hosting

func _on_join_pressed() -> void:
	get_parent().join("127.0.0.1", 2222)
	_start_game()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _on_button_pressed() -> void:
	$password_dialog.show()

func _on_cancel_pressed() -> void:
	$password_dialog.hide()

func _start_game() -> void:
	await get_tree().create_timer(1.0).timeout  # Delay to allow peers to connect
	get_tree().change_scene_to_file("res://World.tscn")  # Ensure this scene exists
