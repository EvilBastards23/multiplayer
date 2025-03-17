extends Control

const CHECKBOX_READY = preload("res://UI_elemenets/checkbox-check-svgrepo-com.svg")
const CHECKBOX_NOT_READY = preload("res://UI_elemenets/checkbox-svgrepo-com(2).svg")


func check_player_ready(is_ready:bool)->void:
	match is_ready:
		true:
			$Label/Button.icon = CHECKBOX_READY
		false:
			$Label/Button.icon = CHECKBOX_NOT_READY


func player_not_ready()->void:
	$Label/Button.icon = CHECKBOX_NOT_READY
