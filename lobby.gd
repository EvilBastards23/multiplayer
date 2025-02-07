extends Control


func _ready()->void:
	$password_dialog/Control/HBoxContainer/confirm.connect("pressed",_on_cancel_pressed)

func _on_host_pressed() -> void:
	pass


func _on_join_pressed() -> void:
	pass # Replace with function body.


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")


func _on_button_pressed() -> void:
	$password_dialog.show()



func _on_cancel_pressed() -> void:
	$password_dialog.hide()
