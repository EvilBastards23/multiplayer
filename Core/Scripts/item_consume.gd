extends Node3D



@export var item_name:String
@export var effect_name:String
@export var effect_value:int
@export var effect_duration:float
@onready var area_3d: Area3D = $Area3D

func _ready() -> void:
	area_3d.connect("body_entered", add_to_inventory)


func consume(target:CharacterBody3D)->void:
	
	match effect_name:
		
		"heal":
			
			target.health_component.restore_health(effect_value)
			target.healt_bar.update_hp_bar()
			
		"speed":
			target.buff_component.apply_buff(effect_name,effect_value,effect_duration)
			
	queue_free()
			

func add_to_inventory(target:CharacterBody3D)->void:
	if not target.inventory_component.is_full:
		target.inventory_component.add_inventory(item_name)
		queue_free()
