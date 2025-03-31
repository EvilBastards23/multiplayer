extends Node

@export var bolder_speed: float = 10.0  # Speed of the boulder
@export var bolder_scene: PackedScene  # Reference to the boulder scene

var player: CharacterBody3D  # The player character to get facing direction
var damage: int = 100

@export var attack_cooldown: float = 0.5
var can_attack: bool = true
var cooldown_timer: Timer  # Correctly define the Timer as a class variable

func _ready() -> void:
	# Ensure we can access the player or get it dynamically
	player = get_parent() as CharacterBody3D
	if player == null:
		print("Warning: The BoulderSummonComponent expects the player to be its parent.")
		
	# Create the Timer and store it in the class variable
	cooldown_timer = Timer.new()
	cooldown_timer.wait_time = attack_cooldown
	cooldown_timer.one_shot = true  # Ensure it only runs once per attack
	cooldown_timer.connect("timeout", _on_timeout)  # Correct connection
	add_child(cooldown_timer)  # Add Timer to the node tree

func _on_timeout() -> void:
	can_attack = true  # Reset attack permission when the timer finishes
	
func _process(_delta: float) -> void:
	# Check if the summon input is pressed
	if player.is_multiplayer_authority() and not player.is_dead and can_attack:
		if Input.is_action_just_pressed("summon_boulder"):
			summon_boulder()

# Summon the boulder and shoot it in the direction the player is facing
func summon_boulder() -> void:
	if player:
		can_attack = false
		cooldown_timer.start()  # Start cooldown timer

		var forward_direction = -player.transform.basis.z.normalized()  # Facing along negative Z-axis
		forward_direction.y = 0  # Ensure movement stays in X-Z plane

		# Position the boulder in front of the player (2 units away)
		var spawn_position = $"../Node3D".global_position

		# Synchronize the boulder spawn with all other clients
		rpc("summon_boulder_network", spawn_position, forward_direction)
		
		# Locally instantiate the boulder (so it appears instantly on the server)
		create_boulder(spawn_position, forward_direction)

# The RPC method to spawn the boulder on all clients
@rpc("reliable")
func summon_boulder_network(spawn_position: Vector3, forward_direction: Vector3) -> void:
	create_boulder(spawn_position, forward_direction)

# Function to create and shoot the boulder
func create_boulder(spawn_position: Vector3, forward_direction: Vector3) -> void:
	# Instantiate the boulder scene
	var boulder = bolder_scene.instantiate()
	
	# Add the boulder to the scene (root or specific node)
	get_parent().get_parent().add_child(boulder)
	boulder.global_position = spawn_position
	boulder.set_direction(forward_direction, damage)
