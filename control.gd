extends Control

var server_list_row_scene:PackedScene = preload("res://UI_elemenets/server_list_row.tscn")
@onready var v_box_container: VBoxContainer = $Panel/server_list_panel/VBoxContainer/Control2/ScrollContainer/VBoxContainer
var count:int = 1
var parent:Node


func _ready() -> void:
	parent = $".."
	$Button.connect("pressed",_on_start_pressed)

func add_server_to_server_list(server_name:String,server_ip:String):
	
	var server_list_row = server_list_row_scene.instantiate()
	server_list_row.get_node("number").text = str(count)
	server_list_row.get_node("server_name").text = server_name
	server_list_row.get_node("queue").text = "1/4"
	server_list_row.ip_address = server_ip
	server_list_row.get_node("join_button").connect("pressed", func(): parent.join(server_list_row.ip_address))
	v_box_container.add_child(server_list_row)
	count +=1
	
	
	
	
var world_scene:PackedScene = preload("res://Core/Scene/world.tscn")

func _on_start_pressed() -> void:
	rpc("start_world")
	
@rpc("any_peer","call_local","reliable")
func start_world()->void:
	
	var world = world_scene.instantiate()
	get_parent().add_child(world)
	get_parent().emit_game_started()
	$".".hide()
	
func change_queue_text(queue_text:String)->void:
	pass
