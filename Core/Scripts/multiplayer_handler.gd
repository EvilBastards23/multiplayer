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
var is_server = false  # Flag to track if this instance is a server

func _ready() -> void:
	# Connect buttons in the lobby to their respective functions (host/join)
	$Control/Panel/host_button.connect("pressed", on_host)
	
	# Get local IP address
	ip_address = get_local_ipv4()
	print("Local IP: ", ip_address)
	
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
	# Close any existing UDP connection
	udp_peer.close()
	
	# Bind to the discovery port to listen for broadcasts
	var err = udp_peer.bind(discover_port, "*")
	if err != OK:
		push_error("Failed to bind UDP to discovery port: " + str(err))
		return
		
	print("UDP bound to discovery port: ", discover_port)
	
	# Start monitoring the network for server broadcasts
	set_process(true)
	
	# Clear any existing servers from the list
	server_list.clear()
	# Clear server list in the UI
	if control.has_method("clear_server_list"):
		control.clear_server_list()

func _process(_delta: float) -> void:
	# Only process UDP packets if the UDP peer is bound
	if udp_peer.is_bound():
		# Check for incoming UDP packets (server broadcasts)
		while udp_peer.get_available_packet_count() > 0:
			var server_ip = udp_peer.get_packet_ip()
			var packet_data = udp_peer.get_packet()
			var server_data = packet_data.get_string_from_utf8()
			
			# Parse server data (format: "server_name|player_count")
			var data_parts = server_data.split("|")
			if data_parts.size() >= 2:
				var server_name = data_parts[0]
				var player_count = data_parts[1]
				print("Received broadcast from server: ", server_name, " at IP: ", server_ip, " with ", player_count, " players")
				
				# Update or add to server list
				var current_time = Time.get_ticks_msec() / 1000.0
				
				if server_list.has(server_ip):
					# Update existing server entry
					server_list[server_ip]["last_seen"] = current_time
					server_list[server_ip]["name"] = server_name
					server_list[server_ip]["player_count"] = player_count
					
					# Update UI
					if control.has_method("update_server_in_list"):
						control.update_server_in_list(server_ip, server_name, player_count)
					print("Updated server: ", server_name, " (", server_ip, ") with ", player_count, " players")
				else:
					# Add new server entry
					server_list[server_ip] = {
						"name": server_name,
						"player_count": player_count,
						"last_seen": current_time
					}
					
					# Add server to UI list
					control.add_server_to_server_list(server_name, server_ip)
					print("Added server to list: ", server_name, " (", server_ip, ") with ", player_count, " players")
		
		# Clean up servers that haven't broadcast in a while
		clean_server_list()

func clean_server_list() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	var servers_to_remove = []
	
	for ip in server_list:
		if current_time - server_list[ip]["last_seen"] > server_timeout:
			servers_to_remove.append(ip)
	
	for ip in servers_to_remove:
		print("Server timed out: ", server_list[ip]["name"], " (", ip, ")")
		server_list.erase(ip)
		
		# Remove server from UI list
		if control.has_method("remove_server_from_list"):
			control.remove_server_from_list(ip)

func broadcast_server_presence() -> void:
	# Skip broadcasting if we're not a server
	if !is_server:
		return
		
	# Get server name from UI
	var server_name = control.get_node("Panel/server_host_panel").get_value_from_line_edit()
	if server_name.is_empty():
		server_name = "Unnamed Server"
		
	# Get current player count (including host)
	var player_count = str(multiplayer.get_peers().size() + 1)
	
	# Create broadcast message
	var message = server_name + "|" + player_count
	
	# Enable broadcasting and send packet
	udp_peer.set_broadcast_enabled(true)
	udp_peer.set_dest_address("255.255.255.255", discover_port)
	
	var packet = message.to_utf8_buffer()
	var err = udp_peer.put_packet(packet)
	
	if err != OK:
		push_error("Failed to broadcast server presence: " + str(err))
	else:
		print("Broadcasting server: ", server_name, " with ", player_count, " players")

# Function to start a server (host)
func host(port: int = 2222, max_players: int = 4) -> void:
	# Create a server peer that listens on the specified port
	var err = peer.create_server(port, max_players)
	
	if err != OK:
		push_error("Cannot create server: " + str(err))
		return
	
	# Set the multiplayer peer to the created server
	multiplayer.multiplayer_peer = peer
	
	# Mark this instance as a server
	is_server = true
	
	print("Server hosted on port: ", port, " with max players: ", max_players)
	
	# Handle local player connection (host)
	_on_connected_to_peer(multiplayer.get_unique_id())
	
	# Start broadcasting server presence
	broadcast_timer.start()

# Function to join a server as a client
func join(ip: String, port: int = 2222) -> void:
	# Mark this instance as not being a server
	is_server = false
	
	# Stop any ongoing broadcasts
	if broadcast_timer.is_inside_tree() and broadcast_timer.time_left > 0:
		broadcast_timer.stop()
	
	print("Attempting to join server at: ", ip, ":", port)
	
	# Try to create a client connection to the server at the provided IP and port
	var err = peer.create_client(ip, port)
	
	if err != OK:
		push_error("Cannot connect to server: " + str(err))
		return
	
	# Set the multiplayer peer to the created client
	multiplayer.multiplayer_peer = peer
	multiplayer.multiplayer_peer.peer_connected.connect(_on_connected_to_peer)

func on_host() -> void:
	# Get server name from UI
	var server_name = control.get_node("Panel/server_host_panel").get_value_from_line_edit()
	
	# Call the host function to start the server if we have a name
	if !server_name.is_empty():
		host()
	else:
		print("Cannot host: Server name is empty")

func get_local_ipv4() -> String:
	for ip in IP.get_local_addresses():
		if ip.is_valid_ip_address() and not ip.contains(":"):  # Excludes IPv6
			if ip.begins_with("192.") or ip.begins_with("10.") or ip.begins_with("172."):
				return ip  # Returns the first private IPv4 address found
	return "127.0.0.1"  # Fallback if no suitable address is found

# Cleanup function
func _exit_tree():
	# Make sure to close the UDP peer when exiting
	if udp_peer and udp_peer.is_bound():
		udp_peer.close()
		
	# Make sure to stop the broadcast timer when exiting
	if broadcast_timer and broadcast_timer.is_inside_tree():
		broadcast_timer.stop()
		
func _on_connected_to_peer(id):
	var lobby = LOBBY.instantiate()
	add_child(lobby)
	$Control.hide()
	
	# Get player name from input field
	var player_name = $Control/Panel/server_list_panel2/VBoxContainer/LineEdit.text
	
	# Wait a brief moment to ensure the lobby is fully set up
	await get_tree().create_timer(0.1).timeout
	
	# Now save the player name
	lobby.save_players_name(multiplayer.get_unique_id(), player_name)

func _on_queue_changed(queue_string: String) -> void:
	if control:
		control.change_queue_text(queue_string)
