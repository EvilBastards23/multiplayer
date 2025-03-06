extends Node

# Declare variables for peer, player, and map scenes
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var player_scene: PackedScene = preload("res://Core/Scene/Game_Scene/player.tscn")
var map_scene: PackedScene = preload("res://Core/Scene/Game_Scene/map.tscn")

# Reference to camera nodes for the players
@onready var camera1: Camera3D = $camera1
@onready var camera2: Camera3D = $camera2

# Signal to notify when a player is added, for coordinating player-camera setup
signal player_added(id: int)

func _ready() -> void:
	# Connect buttons in the lobby to their respective functions (host/join)
	$CanvasLayer/Lobby.get_node("Host").connect("pressed", on_host)
	$CanvasLayer/Lobby.get_node("join").connect("pressed", on_join)
	
	# Ensure that both cameras are available in the scene, if not, show an error
	if !camera1 or !camera2:
		push_error("Cameras not found in scene!")
	
	# Connect the player_added signal to the local handler function
	player_added.connect(_on_player_added)

# Function to start a server (host)
func host(port: int = 2222, max_players: int = 3) -> void:
	# Create a server peer that listens on the specified port
	var err = peer.create_server(port, max_players)
	if err != OK:
		push_error("Cannot create server")
		return
	
	# Set the multiplayer peer to the created server
	multiplayer.multiplayer_peer = peer
	
	# Connect signals for when peers connect or disconnect
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	# Host also needs to add their own player
	call_deferred("add_player", multiplayer.get_unique_id())

# Function to join a server as a client
func join(ip: String, port: int = 2222) -> void:
	# Try to create a client connection to the server at the provided IP and port
	var err = peer.create_client(ip, port)
	if err != OK:
		push_error("Cannot connect to server")
		return
	
	# Set the multiplayer peer to the created client
	multiplayer.multiplayer_peer = peer

# Function to handle when a peer disconnects
func _on_peer_disconnected(id: int) -> void:
	del_player(id)

# Function to add a player to the game when a new peer connects
func add_player(id: int) -> void:
	# Ensure we are executing this on the main thread
	if !is_inside_tree():
		call_deferred("add_player", id)
		return
		
	# Instantiate a new player from the player scene
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Add the player to the scene as a child
	add_child(player)
	
	# Emit the player_added signal to trigger camera setup
	player_added.emit(id)
	
	print("Player added with ID: ", id)

# Function that will be called when the player_added signal is emitted
func _on_player_added(id: int) -> void:
	# Find the player node by their ID
	var player = get_node_or_null(str(id))
	if !player:
		push_error("Player node not found after adding!")
		return
	
	# Add camera setup logic here if needed

# Get the first camera reference
func get_camera1() -> Camera3D:
	return camera1
	
# Get the second camera reference
func get_camera2() -> Camera3D:
	return camera2

# Function to remove a player from the game
func del_player(id: int) -> void:
	# RPC call to ensure player removal happens across all peers
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id: int):
	# Get the player node by their ID
	var player = get_node_or_null(str(id))
	if player:
		# If the player is the target of either camera, clear the target
		if camera1.target == player:
			camera1.target = null
		if camera2.target == player:
			camera2.target = null
		
		# Free the player's node from the scene
		player.queue_free()

# Function for handling the 'join' button press
func on_join() -> void:
	# Call the join function with a default IP (localhost)
	join("127.0.0.1")
	
	# Hide the lobby UI once the player joins
	$CanvasLayer/Lobby.hide()

# Function for handling the 'host' button press
func on_host() -> void:
	# Call the host function to start the server
	host()
	
	# Hide the lobby UI once the player hosts
	$CanvasLayer/Lobby.hide()
