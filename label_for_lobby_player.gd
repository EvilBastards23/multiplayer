extends Control

const CHECKBOX_READY = preload("res://UI_elemenets/checkbox-check-svgrepo-com.svg")
const CHECKBOX_NOT_READY = preload("res://UI_elemenets/checkbox-svgrepo-com(2).svg")
const default_name:String = "player"


func check_player_ready(is_ready:bool)->void:
	match is_ready:
		true:
			$Label/Button.icon = CHECKBOX_READY
			
		false:
			$Label/Button.icon = CHECKBOX_NOT_READY
			

func set_name_for_player(player_name:String)->void:
	if player_name.is_empty():
		$Label.text = default_name
	else:
		$Label.text = player_name
