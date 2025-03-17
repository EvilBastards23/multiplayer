extends Node

# Declare variables for peer, player, and map scenes
var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
@onready var control: Control = $Control
const LOBBY = preload("res://lobby_3d.tscn")
var ip_address: String
signal game_started

# Add variables for server discovery
var udp_peer = PacketPeerUDP.new()
var broadcast_timer: Timer
var discover_port: int = 2223  # Different from game port
var server_list = {}  # Dictionary to store discovered servers
var server_timeout = 5.0  # How long before we consider a server offline

func _ready() -> void:
	# Connect buttons in the lobby to their respective functions (host/join)
	$Control/Panel/host_button.connect("pressed", on_host)
	#$CanvasLayer/Lobby/menu_lobby.get_node("join").connect("pressed", on_join)
	
	# Set up server discovery
	setup_server_discovery()
	
	# Create and configure a timer for broadcasting server presence
	broadcast_timer = Timer.new()
	broadcast_timer.wait_time = 1.0  # Broadcast every second
	broadcast_timer.autostart = false
	broadcast_timer.one_shot = false
	broadcast_timer.timeout.connect(broadcast_server_presence)
	add_child(broadcast_timer)
	
	

func setup_server_discovery() -> void:
	# Set up UDP for server discovery
	udp_peer.close()
	
	# Bind to the discovery port to listen for broadcasts
	var err = udp_peer.bind(discover_port, "*")
	if err != OK:
		push_error("Failed to bind UDP to discovery port: " + str(err))
		return
	
	# Start monitoring the network for server broadcasts
	set_process(true)

func _process(_delta: float) -> void:
	# Check for incoming UDP packets (server broadcasts)
	if udp_peer.get_available_packet_count() > 0:
		var server_ip = udp_peer.get_packet_ip()
		var server_data = udp_peer.get_packet().get_string_from_utf8()
		
		# Parse server data (format: "server_name|player_count")
		var data_parts = server_data.split("|")
		if data_parts.size() >= 2:
			var server_name = data_parts[0]
			
			# Update or add to server list
			if not server_list.has(server_ip) or server_list[server_ip]["last_seen"] < Time.get_ticks_msec() / 1000.0 - server_timeout:
				# New server or server reappeared after timeout
				server_list[server_ip] = {
					"name": server_name,
					"last_seen": Time.get_ticks_msec() / 1000.0
				}
				
				# Use the existing control.add_server_to_server_list function
				control.add_server_to_server_list(server_name, server_ip)
			else:
				# Just update the last seen time
				server_list[server_ip]["last_seen"] = Time.get_ticks_msec() / 1000.0
	
	# Clean up servers that haven't broadcast in a while
	clean_server_list()

func clean_server_list() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var servers_to_remove = []
	
	for ip in server_list:
		if current_time - server_list[ip]["last_seen"] > server_timeout:
			servers_to_remove.append(ip)
	
	for ip in servers_to_remove:
		# Here you would want to remove the server from your UI
		# Since we don't have a direct "remove_server" function, you might need to create one
		# or rebuild the entire list
		server_list.erase(ip)
		
		# If you have a remove_server_from_list function in control, you could call it here
		# control.remove_server_from_list(ip)

func broadcast_server_presence() -> void:
	# Broadcast server info to the local network
	var server_name = control.get_node("Panel/server_host_panel").get_value_from_line_edit()
	var player_count = "1"  # Update this with actual player count
	
	var message = server_name + "|" + player_count
	udp_peer.set_broadcast_enabled(true)
	udp_peer.set_dest_address("255.255.255.255", discover_port)
	udp_peer.put_packet(message.to_utf8_buffer())

# Function to start a server (host)
func host(port: int = 2222, max_players: int = 4) -> void:
	# Create a server peer that listens on the specified port
	var err = peer.create_server(port, max_players)
	
	if err != OK:
		push_error("Cannot create server")
		return
	
	# Set the multiplayer peer to the created server
	multiplayer.multiplayer_peer = peer
	_on_connected_to_peer(multiplayer.get_unique_id())
	print("server hosted")
	
	# Start broadcasting server presence
	broadcast_timer.start()
	

# Function to join a server as a client
func join(ip: String,port: int = 2222) -> void:
	# Stop server discovery when joining
	if broadcast_timer.is_inside_tree() and broadcast_timer.time_left > 0:
		broadcast_timer.stop()
	
	# Try to create a client connection to the server at the provided IP and port
	var err = peer.create_client(ip, port)
	print(ip,"ipsss")
	if err != OK:
		push_error("Cannot connect to server")
		return
	else:
		print("connected_to_server")
	
	# Set the multiplayer peer to the created client
	multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer.peer_connected.connect(_on_connected_to_peer)

# Function to handle when a peer disconnects
#func *on*peer_disconnected(id: int) -> void:
	#del_player(id)

# Function to add a player to the game when a new peer connects
func emit_game_started() -> void:
	emit_signal("game_started")

# Function to remove a player from the game
func del_player(id: int) -> void:
	# RPC call to ensure player removal happens across all peers
	rpc("_del_player", id)

#@rpc("any_peer", "call_local")
#func *del*player(id: int):
	## Get the player node by their ID
	#var player = get_node_or_null(str(id))
	#if player:
		## Free the player's node from the scene
		#player.queue_free()

# Function for handling the 'join' button press
func on_join() -> void:
	pass
	# Call the join function with a default IP (localhost)
	join("127.0.0.1")

# Function for handling the 'host' button press
func on_host() -> void:
	# Call the host function to start the server
	if !control.get_node("Panel/server_host_panel").get_value_from_line_edit().is_empty():
		host()
		
	else:
		print("cannot")

func get_local_ipv4() -> String:
	for ip in IP.get_local_addresses():
		if ip.is_valid_ip_address() and not ip.contains(":"):  # Excludes IPv6
			if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
				return ip  # Returns the first private IPv4 address found
	return "127.0.0.1"  # Fallback if no suitable address is found

# Cleanup function
func _exit_tree():
	if udp_peer:
		udp_peer.close()
	if broadcast_timer and broadcast_timer.is_inside_tree():
		broadcast_timer.stop()
		
func _on_connected_to_peer(_id):
	var lobby = LOBBY.instantiate()
	$Control.hide()
	add_child(lobby)

func _on_queue_changed(queue_string:String)->void:
	$Control.change_queue_text(queue_string,)
