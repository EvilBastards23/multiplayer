extends Node

# Dictionary to store player instances, keyed by their unique ID
var players: Dictionary = {}

func _ready() -> void:
	print("Global singleton ready")
	

# Initialize players from parent node
@rpc("any_peer", "call_local")  # Allows any peer to call this function locally
func initialize_players() -> void:
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child.is_in_group("players"):  
				var player_id = child.get_instance_id()
				players[player_id] = child
				print("Player initialized: ", player_id)

# Remove a player instance from the dictionary
func remove_player(id: int) -> void:
	if players.has(id):
		players.erase(id)
		print("Player removed from Global: ", id)
		# Notify all peers about removed player
		rpc("sync_remove_player", id)
	else:
		push_warning("Player with ID %s not found!" % id)

# RPC to synchronize player removal across all peers
@rpc("any_peer", "call_local", "reliable")
func sync_remove_player(id: int) -> void:
	if players.has(id):
		players.erase(id)
		print("Player removal synced across network: ", id)

# Get a player instance by ID
func get_player(id: int) -> Node:
	return players.get(id, null)

# Get all players as a dictionary
func get_all_players() -> Dictionary:
	return players

# Spawn a specific player at a given area
func spawn_player(player_id: int, area: Area3D) -> void:
	if players.has(player_id):
		var player_instance = players[player_id]
		# Tell all peers to spawn this player
		rpc("sync_spawn_player", player_id, area.get_path())
		# Also spawn locally
		player_instance.spawn(area)
	else:
		push_warning("Player ID %s not found for spawning!" % player_id)

# RPC to synchronize player spawning across all peers
@rpc("any_peer", "call_local", "reliable")
func sync_spawn_player(player_id: int, area_path: NodePath) -> void:
	var area = get_node_or_null(area_path)
	if !area:
		push_warning("Spawn area not found!")
		return
	if players.has(player_id):
		var player_instance = players[player_id]
		player_instance.spawn(area)
		print("Player spawn synced across network: ", player_id)
	else:
		push_warning("Player ID %s not found during sync spawn!" % player_id)

# Respawn all dead players
func respawn_dead_players(area: Area3D) -> void:
	if !area:
		push_warning("Respawn area not provided!")
		return
	# Tell all peers to respawn dead players
	rpc("sync_respawn_dead_players", area.get_path())
	# Also handle locally
	_respawn_dead_players_local(area)

# Local function to handle respawning dead players
func _respawn_dead_players_local(area: Area3D) -> void:
	for player_id in players:
		var player_instance = players[player_id]
		if player_instance.is_dead:
			player_instance.spawn(area)
			print("Respawned player: ", player_id)

# RPC to synchronize respawning dead players across all peers
@rpc("any_peer", "call_local", "reliable")
func sync_respawn_dead_players(area_path: NodePath) -> void:
	var area = get_node_or_null(area_path)
	if !area:
		push_warning("Respawn area not found during sync!")
		return
	_respawn_dead_players_local(area)
	print("Dead players respawn synced across network")
