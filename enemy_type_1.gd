extends CharacterBody3D

@export var speed : float = 5.0
@export var chase_range : float = 50.0
@export var gravity : float = -9.8  # Gravity strength, negative for downward direction

var target_player : Node3D = null
var navigation_agent : NavigationAgent3D
var is_player_1_connected : bool = false
var is_player_2_connected : bool = false

var players : Dictionary = {}  # Holds player instances by network ID

 # Keep track of the velocity

func _ready():
	navigation_agent = $NavigationAgent3D
	update_target()

# This method should be called whenever a player joins the game
# Assuming you have networked players with distinct IDs
func assign_player_to_enemy(player_node : Node3D):
	var network_id = player_node.get_network_unique_id()
	players[network_id] = player_node

	if players.size() == 1:
		# If only one player, assign that player as the target
		target_player = players[network_id]
	elif players.size() == 2:
		# If two players, choose the closest one as the target
		update_target()

# Function to handle player connection state changes
# This method is called by the server when a player connects or disconnects
func _on_player_connection_changed(player_id : int, connected : bool):
	if connected:
		var new_player = get_node("/root/Player" + str(player_id))  # Assuming players are named Player1, Player2, etc.
		assign_player_to_enemy(new_player)
	else:
		if players.has(player_id):
			players.erase(player_id)

	# Reassess target after connection state change
	update_target()

func _process(delta):
	if target_player != null:
		# Move the enemy towards the target player using navigation
		navigation_agent.set_target_position(target_player.position)
		if navigation_agent.has_path():
			move_and_slide()
		else:
			# If no path, move directly towards the target
			look_at(target_player.position, Vector3.UP)
			var direction = (target_player.position - global_transform.origin).normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

	# Apply gravity if no floor is detected
	if !is_on_floor():
		velocity.y += gravity * get_process_delta_time()

	# Move the enemy and apply gravity
	
	
	# Update target if necessary
	update_target()

func update_target():
	if players.size() == 0:
		target_player = null
		return
	
	# Find the closest player
	var closest_player = null
	var closest_distance = chase_range
	for player_id in players.keys():
		var player = players[player_id]
		var distance = global_transform.origin.distance_to(player.global_transform.origin)
		if distance < closest_distance:
			closest_distance = distance
			closest_player = player
	
	target_player = closest_player
