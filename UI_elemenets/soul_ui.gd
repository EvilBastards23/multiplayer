extends Control

var soul_component:Node

func _ready() -> void:
	soul_component = $"../../soul_component"
	soul_component.connect("change_label",chaging_label)


func chaging_label(amount:int):
	print("signal is emiting")
	$HBoxContainer/Label.text = str(amount)
