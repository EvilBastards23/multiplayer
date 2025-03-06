extends Node

var soul_amount:int
var soul_owner:String = "1"
var item_name = "soul"
@onready var pick_up_area: Area3D = $pick_up_area

func _ready() -> void:
	pick_up_area.connect("body_entered",body_entered_in_area)

func body_entered_in_area(body)->void:
	if body.name == soul_owner and body.is_in_group("players"):
		body.soul_component.add_soul(soul_amount)
		queue_free()
		
	elif body.name != soul_owner and body.is_in_group("players"):
		body.inventory_component.add_inventory("soul")
		queue_free()
		
func set_soul(amount:int,owner:String)->void:
	soul_amount = amount
	soul_owner = owner
