extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_TARGET_SWITCH_TIME = 2.0  # Time before re-evaluating the target
const TARGET_SWITCH_THRESHOLD = 1.0  # Only switch targets if the new target is closer by this amount

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var players: Array = []
var current_target: Node3D = null
var update_target_time: float = 0.5
var target_timer: float = 0.0
var target_switch_timer: float = 0.0  # Timer to control when to switch targets

# Define a custom signal for target change
signal target_changed(new_target: Node3D)

func _ready() -> void:
	# Set default navigation parameters
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5
	
	# Wait a bit before starting to find players to ensure they're all spawned
	await get_tree().create_timer(0.5).timeout
	find_players()

	# Connect the signal to the method that handles target change
	connect("target_changed", _on_target_changed)

func find_players() -> void:
	# Clear existing players array
	players.clear()
	
	# Find all players in the scene
	var potential_players = get_tree().get_nodes_in_group("players")
	for player in potential_players:
		if player != null and is_instance_valid(player):
			players.append(player)

func update_target() -> void:
	if players.is_empty():
		find_players()
		if players.is_empty():
			return
	
	# Find the closest player
	var new_target = find_closest_player()
	if new_target != null:
		# Only switch targets if the new target is significantly closer
		if current_target == null or global_position.distance_to(new_target.global_position) < global_position.distance_to(current_target.global_position) - TARGET_SWITCH_THRESHOLD:
			emit_signal("target_changed", new_target)
		
		# Always update the navigation agent's target position
		nav_agent.target_position = new_target.global_position

func find_closest_player() -> Node3D:
	var closest_distance: float = INF
	var closest_player: Node3D = null
	
	# Find the closest player
	for player in players:
		if player != null and is_instance_valid(player):
			var distance = global_position.distance_to(player.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_player = player
	
	return closest_player

# This method is called when the signal is emitted

func _on_target_changed(new_target: Node3D) -> void:
	print("Target changed to: ", new_target.name)
	current_target = new_target

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Update target periodically
	target_timer += delta
	target_switch_timer += delta
	
	if target_switch_timer >= update_target_time:
		target_switch_timer = 0
		update_target()
	
	if current_target != null and not nav_agent.is_navigation_finished():
		var next_pos = nav_agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		
		# Set horizontal velocity
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Stop horizontal movement if no target or reached destination
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()

# Optional: Add functions to handle player disconnection or removal
func remove_player(player: Node3D) -> void:
	var index = players.find(player)
	if index != -1:
		players.remove_at(index)
		if current_target == player:
			current_target = null
			target_switch_timer = MAX_TARGET_SWITCH_TIME  # Force re-evaluation of target
