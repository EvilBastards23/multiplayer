extends Node

@export var bolder_speed: float = 10.0  # Speed of the boulder
@export var bolder_scene: PackedScene  # Reference to the boulder scene

var player: CharacterBody3D  # The player character to get facing direction

func _ready() -> void:
	# Ensure we can access the player or get it dynamically (if the component is on the player, this works)	
	player = get_parent() as CharacterBody3D  # Assuming the component is a child of the player
	if player == null:
		print("Warning: The BoulderSummonComponent expects the player to be its parent.")

func _process(delta: float) -> void:
	# Check if the summon input is pressed
	if player.is_multiplayer_authority():
		if Input.is_action_just_pressed("summon_boulder"):
			summon_bolder()

# Summon the boulder and shoot it in the direction the player is facing
func summon_bolder() -> void:
	if player:
		var forward_direction = -player.transform.basis.z.normalized()  # Facing along negative Z-axis
		forward_direction.y = 0  # Ensure movement stays in X-Z plane

		# Position the boulder in front of the player (2 units away)
		var spawn_position = $"../Node3D".global_position

		# Synchronize the boulder spawn with all other clients
		rpc("summon_bolder_network", spawn_position, forward_direction)
		
		# Locally instantiate the boulder (so it appears instantly on the server)
		create_boulder(spawn_position, forward_direction)

# The RPC method to spawn the boulder on all clients
@rpc("reliable")
func summon_bolder_network(spawn_position: Vector3, forward_direction: Vector3) -> void:
	create_boulder(spawn_position, forward_direction)

# Function to create and shoot the boulder
func create_boulder(spawn_position: Vector3, forward_direction: Vector3) -> void:
	# Instantiate the boulder scene
	var bolder = bolder_scene.instantiate()
	

	# Set the boulder's position
	

	# Add the boulder to the scene (root or specific node)
	get_tree().root.add_child(bolder)
	bolder.global_position = spawn_position
	bolder.set_direction(forward_direction,20)
