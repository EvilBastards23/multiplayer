extends Node3D
@onready var ready_button: Button = $Camera3D/CanvasLayer/Control/ready
var parent: Node
signal queue_changed
var player_names := {}  # Stores network_id -> player_name
@onready var monicans := {
	1: $monican1,
	2: $monican2,
	3: $monican3,
	4: $monican4
}

# Track whether disconnect dialog has been shown
var disconnect_dialog_shown = false
var world_scene:PackedScene = preload("res://Core/Scene/world.tscn")
# Game locking variables
var game_locked = false
var start_timer: Timer
@onready var status_label = $Camera3D/CanvasLayer/Control2/Label

func save_players_name(player_id: int, player_name: String):
	print("Saving player name:", player_name, "for ID:", player_id)
	player_names[player_id] = player_name
	
	if !multiplayer.is_server():
		# If this is a client, send name to the host
		notify_host_of_name.rpc_id(1, player_id, player_name)
	else:
		# Find player index and sync name
		var player_index = -1
		for idx in player_ids:
			if player_ids[idx] == player_id:
				player_index = idx
				break
		
		if player_index != -1:
			sync_player_name.rpc(player_index, player_name)

# Add this new RPC function to receive names from clients
@rpc("any_peer")
func notify_host_of_name(player_id: int, player_name: String):
	if multiplayer.is_server():
		# Host receives name from client, saves it
		player_names[player_id] = player_name
		
		# Find player index and sync name to all clients
		var player_index = -1
		for idx in player_ids:
			if player_ids[idx] == player_id:
				player_index = idx
				break
		
		if player_index != -1:
			sync_player_name.rpc(player_index, player_name)

var player_ids = {}  # Maps player index -> network ID
var ready_status := {}  # Tracks player readiness
var player_count: int = 0  # Start from 0, including the host

func _ready() -> void:
	parent = get_parent()
	multiplayer.multiplayer_peer.connect("peer_connected", on_peer_connected)
	multiplayer.multiplayer_peer.connect("peer_disconnected", on_peer_disconnected)
	ready_button.connect("pressed", _on_ready_button_pressed)
	
	
	# Initialize status label
	status_label.text = ""
	status_label.visible = false
	
	# Host initialization
	if multiplayer.is_server():
		var host_id = multiplayer.get_unique_id()
		player_count += 1
		player_ids[1] = host_id  # Host is always player 1
		ready_status[1] = false
		# Show the first monican for the host
		monicans[1].show()
		
		# Set the host's name if it exists
		if player_names.has(host_id):
			sync_player_name.rpc(1, player_names[host_id])

func _process(delta: float) -> void:
	# Check if the host has disconnected (only on clients)
	if multiplayer.multiplayer_peer and !multiplayer.is_server() and !multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		if not disconnect_dialog_shown:  # Only show dialog once
			_on_host_disconnected()
			disconnect_dialog_shown = true

func _on_host_disconnected() -> void:
	# The host has disconnected, so the game cannot continue
	print("Host disconnected, returning to main menu")
	
	# Create and configure the dialog - add to the main scene tree for better visibility
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "The host has disconnected."
	dialog.dialog_autowrap = true
	dialog.title = "Connection Lost"
	
	# Add to the main scene tree rather than as a child of this node
	get_tree().root.add_child(dialog)
	
	# Make sure it's visible and on top
	dialog.popup_centered()
	dialog.layer = 100  # High layer to ensure it's on top
	
	# Connect the dialog close signal properly
	dialog.connect("confirmed", Callable(self, "_on_dialog_confirmed").bind(dialog))

func _on_dialog_confirmed(dialog: AcceptDialog) -> void:
	# Properly handle cleanup and scene transition
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	
	# Clean up the dialog first
	dialog.queue_free()
	
	# Change the scene only after dialog is handled
	get_tree().change_scene_to_file("res://Core/Scene/Multiplayer_Scene/multiplayer_handler.tscn")

func on_peer_connected(id: int) -> void:
	if player_count >= 4:
		print("Lobby full!")
		return
	
	# Find first available index, prioritizing lower indexes
	var assigned_index = 0
	for i in range(1, 5):  # Check indexes 1-4
		if !player_ids.has(i):
			assigned_index = i
			break
	
	if assigned_index == 0:
		print("Error: Couldn't find available player index")
		return
		
	player_count += 1
	player_ids[assigned_index] = id
	ready_status[assigned_index] = false

	# Show the player's monican to everyone
	if monicans.has(assigned_index):
		monicans[assigned_index].show()
		sync_monican_show.rpc(assigned_index)

	# Check if we already have a name for this player
	if player_names.has(id):
		# We already have their name, sync it to everyone
		sync_player_name.rpc(assigned_index, player_names[id])
	
	# Only the host should sync the player list to the new player
	if multiplayer.is_server():
		# Send all current player data to the new player
		# We wait briefly to make sure the client has time to set up their name first
		await get_tree().create_timer(0.5).timeout
		sync_all_players.rpc_id(id, player_ids, ready_status, player_names)
		
		# Make sure the new player sees all existing players' monicans
		for player_index in player_ids:
			if player_index != assigned_index:  # Skip the newly joined player
				sync_monican_show.rpc_id(id, player_index)
				
				# Only sync name if it exists
				if player_names.has(player_ids[player_index]):
					sync_player_name.rpc_id(id, player_index, player_names[player_ids[player_index]])
					
		sync_queue_change.rpc(player_count)

# Handle peer disconnection
func on_peer_disconnected(id: int) -> void:
	if !multiplayer.is_server():
		# Only the server handles disconnections
		return
		
	print("Player disconnected: ", id)
	
	# Find which player index this ID corresponds to
	var disconnected_index = -1
	for idx in player_ids:
		if player_ids[idx] == id:
			disconnected_index = idx
			break
	
	if disconnected_index == -1:
		print("Could not find disconnected player in player_ids")
		return
	
	# Remove player data from tracking
	player_ids.erase(disconnected_index)
	ready_status.erase(disconnected_index)
	player_names.erase(id)
	
	# Hide their monican
	if monicans.has(disconnected_index):
		monicans[disconnected_index].hide()
	
	# Sync this disconnection to all remaining clients
	sync_player_disconnected.rpc(disconnected_index)
	
	# Update the player count
	player_count -= 1
	sync_queue_change.rpc(player_count)

@rpc("authority")
func sync_queue_change(number: int) -> void:
	var queue_string: String = str(number) + "/4"
	emit_signal("queue_changed", queue_string)
	
@rpc("any_peer", "call_local")
func sync_player_name(player_index, player_name):
	# Store the name in player_dddddnames dictionary for all clients
	if player_ids.has(player_index):
		var network_id = player_ids[player_index]
		player_names[network_id] = player_name
	
	if monicans.has(player_index):
		var name_label = monicans[player_index].get_node("SubViewport/Control")
		if player_name == null:
			name_label.set_name_for_player("")
		else:
			name_label.set_name_for_player(player_name)
	
@rpc("any_peer")
func sync_monican_show(player_index: int) -> void:
	if monicans.has(player_index):
		monicans[player_index].show()

@rpc("authority") 
func sync_player_disconnected(player_index: int) -> void:
	# Hide the disconnected player's monican
	if monicans.has(player_index):
		monicans[player_index].hide()
	
	# Remove their data
	if player_ids.has(player_index):
		var network_id = player_ids[player_index]
		player_names.erase(network_id)
		player_ids.erase(player_index)
		ready_status.erase(player_index)

@rpc("authority")
func sync_all_players(updated_player_ids: Dictionary, updated_ready_status: Dictionary, updated_player_names: Dictionary = {}) -> void:
	player_ids = updated_player_ids
	ready_status = updated_ready_status
	
	# Only update names that are not already set locally
	var local_id = multiplayer.get_unique_id()
	for network_id in updated_player_names:
		# Don't override own name if it exists
		if network_id == local_id && player_names.has(local_id):
			continue
		player_names[network_id] = updated_player_names[network_id]
	
	# Update UI for all players with their names
	for player_index in player_ids:
		var network_id = player_ids[player_index]
		if player_names.has(network_id) and monicans.has(player_index):
			var name_label = monicans[player_index].get_node("SubViewport/Control")
			name_label.set_name_for_player(player_names[network_id])
			
			# Also update the ready status display
			if ready_status.has(player_index):
				name_label.check_player_ready(ready_status[player_index])
			
	

func _on_ready_button_pressed() -> void:
	var local_id = multiplayer.get_unique_id()
	var player_index = player_ids.find_key(local_id)
	if player_index:
		ready_status[player_index] = !ready_status[player_index]
		
		sync_ready_state.rpc(player_index, ready_status[player_index])
		
		if ready_status[player_index]:
			$Camera3D/CanvasLayer/Control/ready.text = "Not Ready"
		else:
			$Camera3D/CanvasLayer/Control/ready.text = "Ready"
		
@rpc("any_peer", "call_local")
func sync_ready_state(player_index: int, is_ready: bool) -> void:
	if monicans.has(player_index):
		var checkbox: Control = monicans[player_index].get_node("SubViewport/Control")
		checkbox.check_player_ready(is_ready)
	
	ready_status[player_index] = is_ready
	
	# If we're the server, check if everyone is ready to start
	if multiplayer.is_server() and !game_locked:
		if check_all_ready():
			lock_game_and_start()

# Implementation for the exit button
func _on_exit_pressed() -> void:
	if multiplayer.multiplayer_peer:
		# Disconnect from the multiplayer session
		multiplayer.multiplayer_peer.close()
	
	# Remove the lobby from the scene tree
	queue_free()
	
	# Return to the main menu or whatever scene should be next
	get_tree().change_scene_to_file("res://Core/Scene/Multiplayer_Scene/multiplayer_handler.tscn")

# Function to check if all players are ready
func check_all_ready() -> bool:
	# If no players, return false
	if player_count == 0:
		return false
		
	# Check if we have at least 2 players and all are ready
	if player_count >= 2:
		for index in ready_status:
			if ready_status[index] == false:
				return false
		return true
	return false

# Function to lock the game and start countdown
func lock_game_and_start():
	if game_locked:
		return
		
	if check_all_ready():
		game_locked = true
		
		# Disable the ready button for everyone
		ready_button.disabled = true
		sync_lock_game.rpc(true)
		
		# Create and start a timer for countdown
		start_timer = Timer.new()
		start_timer.one_shot = true
		start_timer.wait_time = 3.0
		start_timer.connect("timeout", _on_start_timer_timeout)
		add_child(start_timer)
		start_timer.start()
		
		# Show countdown message
		sync_game_starting.rpc()

# Timer timeout function
func _on_start_timer_timeout():
	# Tell parent to start the game
	
	# If we're the server, sync this to all clients
	if multiplayer.is_server():
		sync_game_start.rpc()

# RPC to sync game lock state
@rpc("authority", "call_local")
func sync_lock_game(locked: bool):
	game_locked = locked
	ready_button.disabled = locked

# RPC to show "Game starting in 3..." message
@rpc("authority", "call_local")
func sync_game_starting():
	status_label.text = "Game about to begin..."
	status_label.visible = true

# RPC to start the game on all clients
@rpc("call_local","any_peer")
func sync_game_start():
	
	var world = world_scene.instantiate()
	get_parent().add_child(world)
	get_parent().emit_signal("game_started")
	queue_free()
