extends Control

@export var level_component:Node

func _ready() -> void:
	level_component.connect("change_label",change_label)
	add_button_hide()

func change_label(label_name:String,value:int):
	match label_name:
		"vitality":
			$Panel/VBoxContainer/HBoxContainer/Vitualliy_label.text = str(value)
			if level_component.attribute_points == 0:
				add_button_hide()
			else:
				add_button_show()
				
		"endurance":
			$Panel/VBoxContainer/HBoxContainer3/Endurance_label.text = str(value)
			if level_component.attribute_points == 0:
				add_button_hide()
			else:
				add_button_show()
		"agility":
			$Panel/VBoxContainer/HBoxContainer4/Agility_label.text = str(value)
			if level_component.attribute_points == 0:
				add_button_hide()
			else:
				add_button_show()
		"arcane_power":
			$Panel/VBoxContainer/HBoxContainer2/Arcane_power_label.text = str(value)
			if level_component.attribute_points == 0:
				add_button_hide()
			else:
				add_button_show()
		"level":
			$Panel/VBoxContainer/HBoxContainer5/level_label.text = str(value)
			add_button_show()
		"atrribute_point":
			$Panel/VBoxContainer/HBoxContainer6/attribute_point.text = str(value)

func add_button_hide():
	$Panel/VBoxContainer/HBoxContainer3/add_button.hide()
	$Panel/VBoxContainer/HBoxContainer/add_button.hide()
	$Panel/VBoxContainer/HBoxContainer2/add_button.hide()
	$Panel/VBoxContainer/HBoxContainer4/add_button.hide()
	
func add_button_show():
	$Panel/VBoxContainer/HBoxContainer3/add_button.show()
	$Panel/VBoxContainer/HBoxContainer/add_button.show()
	$Panel/VBoxContainer/HBoxContainer2/add_button.show()
	$Panel/VBoxContainer/HBoxContainer4/add_button.show()

func _on_agility_pressed() -> void:
	level_component.increase_agility()

func _on_arcane_power_pressed() -> void:
	level_component.increase_arcane_power()

func _on_endurance_pressed() -> void:
	level_component.increase_endurance()

func _on_vituality_pressed() -> void:
	level_component.increase_vitality()
