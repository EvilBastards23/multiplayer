extends Node

var soul_value:int = 0
var owner_name:String
signal change_label

func _ready() -> void:
	owner_name = get_parent().name
	

func add_soul(amount:int)->void:
	soul_value += amount
	emit_signal("change_label",soul_value)
	

func drop_soul()->void:
	if soul_value >0:
		var soul_scene = preload("res://Core/Scene/Game_Scene/soul.tscn")
		var dropped_item = soul_scene.instantiate()
		dropped_item.set_soul(soul_value,owner_name)
		var drop_offset = get_parent().global_transform.basis.z.normalized() * 2
		dropped_item.global_transform =  get_parent().global_transform.translated(drop_offset + Vector3(0, 1, 0))
			
		get_tree().get_root().add_child(dropped_item)
		dropped_item.add_to_group("dropped_items")
		
		soul_value = 0
		emit_signal("change_label",soul_value)
		
	
