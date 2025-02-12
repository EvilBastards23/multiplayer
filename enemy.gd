extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_TARGET_SWITCH_TIME = 2.0  # Time before re-evaluating the target
const TARGET_SWITCH_THRESHOLD = 1.0  # Only switch targets if the new target is closer by this amount

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
var current_target: Node3D = null
var time_since_target_switch: float = 0.0
@onready var health_component: Node = $health_component


func _ready() -> void:
	$hit_box.connect("body_entered",take_damage)
	# Make sure navigation is ready
	await get_tree().create_timer(0.1).timeout
	find_closest_player()
	

func _physics_process(delta: float) -> void:
	# Apply gravity if not on floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# Update target switching timer
	time_since_target_switch += delta
	if time_since_target_switch >= MAX_TARGET_SWITCH_TIME:
		find_closest_player()
		time_since_target_switch = 0.0
	
	if current_target:
		# Update the navigation target
		nav_agent.target_position = current_target.global_position
		
		# Get the next navigation point
		var next_position: Vector3 = nav_agent.get_next_path_position()
		
		# Calculate direction and distance
		var direction: Vector3 = (next_position - global_position).normalized()
		
		# Set velocity
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# Look at target
		look_at(Vector3(next_position.x, global_position.y, next_position.z))
	
	# Apply movement
	move_and_slide()

func find_closest_player() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	
	var closest_distance: float = INF
	var closest_player: Node3D = null
	
	for player in players:
		var distance = global_position.distance_to(player.global_position)
		
		# If we have a current target, only switch if the new target is significantly closer
		if current_target and distance >= closest_distance - TARGET_SWITCH_THRESHOLD:
			continue
			
		closest_distance = distance
		closest_player = player
	
	# Update current target if we found a closer player
	if closest_player:
		current_target = closest_player
		

func take_damage(body)->void:
	if body.is_in_group("bullet"):
		
		print("taking damage")
		$health_component.take_damage(body.damage)
		body.queue_free()
