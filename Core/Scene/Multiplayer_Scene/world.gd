extends Node3D

@onready var camera_1: Camera3D = $camera1
@onready var camera_2: Camera3D = $camera2


@onready var loot_generator: Node = $loot_generator


var player_scene: PackedScene = preload("res://Core/Scene/Game_Scene/player.tscn")
var map_scene: PackedScene = preload("res://Core/Scene/Game_Scene/map.tscn")

signal handle_mob_death

func _ready() -> void:
	get_parent().connect("game_started", on_game_started)
	handle_mob_death.connect(handling_mob_death)

@rpc("any_peer")
func add_player(id: int) -> void:
	# Ensure we are executing this on the main thread
	if !is_inside_tree():
		call_deferred("add_player", id)
		return

	# Don't duplicate players
	if has_node(str(id)):
		print("Player already exists with ID: ", id)
		return

	# Instantiate a new player from the player scene
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Add the player to the scene as a child
	add_child(player)
	
	print("Player added with ID: ", id)


func get_camera1() -> Camera3D:
	return camera_1
	
# Get the second camera reference
func get_camera2() -> Camera3D:
	return camera_2
	

	
func on_game_started() -> void:
	print("game_starting")
	
	# If we're the server, add all connected players including ourselves
	if multiplayer.is_server():
		# Add server player
		add_player(multiplayer.get_unique_id())
		
		# For each connected peer, add their player too
		for peer_id in multiplayer.get_peers():
			add_player(peer_id)
	else:
		# If we're a client, tell the server to add us
		add_player.rpc_id(1, multiplayer.get_unique_id())
	
func handling_mob_death(position:Vector3):
	loot_generator.spawn_loot.rpc(position)
