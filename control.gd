extends Control

var server_list_row_scene:PackedScene = preload("res://UI_elemenets/server_list_row.tscn")
@onready var v_box_container: VBoxContainer = $Panel/server_list_panel/VBoxContainer/Control2/ScrollContainer/VBoxContainer
var count:int = 1
var parent:Node
var server_rows = {}



func _ready() -> void:
	parent = $".."
	$Button.connect("pressed",_on_start_pressed)
	$Panel/server_list_panel/Panel/refresh.connect("pressed",parent.on_refresh_button)

func add_server_to_server_list(server_name: String, server_ip: String):
	# Skip if this server is already in our list
	if server_rows.has(server_ip):
		return
		
	var server_list_row = server_list_row_scene.instantiate()
	server_list_row.get_node("number").text = str(count)
	server_list_row.get_node("server_name").text = server_name
	server_list_row.get_node("queue").text = "1/4"  # Default value, will be updated
	server_list_row.ip_address = server_ip
	server_list_row.get_node("join_button").connect("pressed", func(): get_parent().join(server_list_row.ip_address))
	v_box_container.add_child(server_list_row)
	
	# Store reference to the row for later updates
	server_rows[server_ip] = server_list_row
	
	count += 1

# Called to update an existing server in the list
func update_server_in_list(server_ip: String, server_name: String, player_count: String):
	if server_rows.has(server_ip) and is_instance_valid(server_rows[server_ip]):
		# Update the server name and player count
		server_rows[server_ip].get_node("server_name").text = server_name
		server_rows[server_ip].get_node("queue").text = player_count + "/4"  # Assuming max is 4
		
		# No need to update the IP or join button

# Called to remove a server that has timed out
func remove_server_from_list(server_ip: String):
	if server_rows.has(server_ip) and is_instance_valid(server_rows[server_ip]):
		# Free the row instance
		server_rows[server_ip].queue_free()
		
		# Remove from our tracking dictionary
		server_rows.erase(server_ip)
		
		# Note: We don't decrement the count to avoid confusion
		# with server numbers changing during runtime

# Called to clear all servers from the list
func clear_server_list():
	# Remove all server row instances
	for server_ip in server_rows:
		if is_instance_valid(server_rows[server_ip]):
			server_rows[server_ip].queue_free()
			
	# Clear our tracking dictionary
	server_rows.clear()
	
	# Reset the counter
	count = 1
	
var world_scene:PackedScene = preload("res://Core/Scene/world.tscn")

func _on_start_pressed() -> void:
	rpc("start_world")
	
@rpc("any_peer","call_local","reliable")
func start_world()->void:
	
	var world = world_scene.instantiate()
	get_parent().add_child(world)
	get_parent().emit_signal("game_started")
	$".".hide()
	
func change_queue_text(queue_text:String)->void:
	pass
