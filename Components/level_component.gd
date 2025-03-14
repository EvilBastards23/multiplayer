extends Node

var current_level:int = 1
var cost_increase_to_per_level:int = 20
var current_cost:int = 100
var parent

@export var health_component:Node

signal change_label

var vitality:int = 1
var endurance:int = 1
@export var shoot_component:Node
var arcane_power:int = 1 
var agility:int =1
var attribute_point:int = 0
func _ready() -> void:
	parent = get_parent()
	calculate_deriaved_stats()

var attribute_points:int = 0
func increase_current_cost():
	current_cost += cost_increase_to_per_level * current_level

func get_cost()->int:
	return current_cost

func upgrade()->void:
	current_level += 1
	attribute_points += 1
	emit_signal("change_label","level",current_level)
	emit_signal("change_label","attribute",attribute_points)
	increase_current_cost()
	print(attribute_point)

func increase_vitality()->void:
	if attribute_points > 0:
		vitality +=1
		attribute_points -= 1
		emit_signal("change_label","vitality",vitality)
		emit_signal("change_label","attribute",attribute_points)
		calculate_deriaved_stats()
	else:
		return

func increase_endurance()->void:
	if attribute_points > 0:
		endurance +=1
		attribute_points -=1
		calculate_deriaved_stats()
		emit_signal("change_label","endurance",endurance)
		emit_signal("change_label","attribute",attribute_points)
	else:
		return

func increase_agility()->void:
	if attribute_points > 0:
		agility +=1
		attribute_points -=1
		calculate_deriaved_stats()
		emit_signal("change_label","agility",agility)
		emit_signal("change_label","attribute",attribute_points)
	else:
		return

func increase_arcane_power()->void:
	if attribute_points > 0:
		arcane_power +=1
		attribute_points -=1
		calculate_deriaved_stats()
		emit_signal("change_label","arcane_power",arcane_power)
		emit_signal("change_label","attribute",attribute_points)
	else:
		return

func calculate_deriaved_stats():
	parent.SPEED += 0.05 * agility
	shoot_component.damage += 0.05 * arcane_power
	health_component.max_hp += 0.05 * vitality
	
	
	
