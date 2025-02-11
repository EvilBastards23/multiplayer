extends Node

var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var player_scene: PackedScene = preload("res://player.tscn")
var map_scene: PackedScene = preload("res://map.tscn")

# Reference to cameras
@onready var camera1: Camera3D = $camera1
@onready var camera2: Camera3D = $camera2

# Signal to coordinate player-camera setup
signal player_added(id: int)

func _ready() -> void:
	
	$CanvasLayer/Lobby.get_node("Host").connect("pressed",on_host)
	$CanvasLayer/Lobby.get_node("join").connect("pressed",on_join)
	
	# Ensure cameras are ready
	if !camera1 or !camera2:
		push_error("Cameras not found in scene!")
	
	# Connect to our own player_added signal
	player_added.connect(_on_player_added)

func host(port: int = 2222, max_players: int = 3) -> void:
	var err = peer.create_server(port, max_players)
	if err != OK:
		push_error("Cannot create server")
		return
	
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(del_player)
	
	# Host needs their own player
	call_deferred("add_player", multiplayer.get_unique_id())

func join(ip: String, port: int = 2222) -> void:
	var err = peer.create_client(ip, port)
	
	if err != OK:
		push_error("Cannot connect to server")
		return
	
	multiplayer.multiplayer_peer = peer

func _on_peer_disconnected(id: int) -> void:
	del_player(id)

func add_player(id: int) -> void:
	# Ensure we're on the main thread
	if !is_inside_tree():
		call_deferred("add_player", id)
		return
		
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Add player to scene
	add_child(player)
	
	# Emit signal that player was added - this will trigger camera setup
	player_added.emit(id)
	
	print("Player added with ID: ", id)

func _on_player_added(id: int) -> void:
	# Get the player node
	var player = get_node_or_null(str(id))
	if !player:
		push_error("Player node not found after adding!")
		return
	
	

func get_camera1() -> Camera3D:
	return camera1
	
func get_camera2() -> Camera3D:
	return camera2

func del_player(id: int) -> void:
	rpc("_del_player", id)

@rpc("any_peer", "call_local")
func _del_player(id: int):
	var player = get_node_or_null(str(id))
	if player:
		# Clear camera target if it's this player
		if camera1.target == player:
			camera1.target = null
		if camera2.target == player:
			camera2.target = null
		player.queue_free()
		
func on_join()->void:
	join("127.0.0.1")
	$CanvasLayer.hide()
	
func on_host()->void:
	host()
	$CanvasLayer.hide()
