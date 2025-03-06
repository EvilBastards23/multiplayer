extends Node

var soul_value:int = 200
var owner_name:String
signal change_label

func _ready() -> void:
	owner_name = get_parent().name
	

func add_soul(amount:int)->void:
	soul_value += amount
	emit_signal("change_label",soul_value)
	

func drop_soul()->void:
	
	var soul_scene = preload("res://Core/Scene/Game_Scene/soul.tscn")
	soul_scene.instantiate()
	soul_scene.set_soul(soul_value,owner_name)
	soul_value = 0
	
