extends Node

# Declare variables for peer, player, and map scenes
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

signal game_started

func _ready() -> void:
	# Connect buttons in the lobby to their respective functions (host/join)
	$CanvasLayer/Lobby/menu_lobby.get_node("Host").connect("pressed", on_host)
	$CanvasLayer/Lobby/menu_lobby.get_node("join").connect("pressed", on_join)
	
# Function to start a server (host)
func host(port: int = 2222, max_players: int = 4) -> void:
	# Create a server peer that listens on the specified port
	var err = peer.create_server(port, max_players)
	
	if err != OK:
		push_error("Cannot create server")
		return
	
	# Set the multiplayer peer to the created server
	multiplayer.multiplayer_peer = peer
	$CanvasLayer/Lobby/menu_lobby/start.show()
	
	# Host also needs to add their own player

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
func emit_game_started()->void:
	emit_signal("game_started")



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

		
		# Free the player's node from the scene
		player.queue_free()

# Function for handling the 'join' button press
func on_join() -> void:
	# Call the join function with a default IP (localhost)
	join("127.0.0.1")
	
	# Hide the lobby UI once the player joins
	#$CanvasLayer/Lobby.hide()

# Function for handling the 'host' button press
func on_host() -> void:
	# Call the host function to start the server
	host()
	
	# Hide the lobby UI once the player hosts
	#$CanvasLayer/Lobby.hide()


#func _on_button_pressed() -> void:
	#print(global.get_all_players(),"this is dictionarry")
	#global.rpc("initialize_players")
	#global.respawn_dead_players($Area3D)
	
	

	
		
