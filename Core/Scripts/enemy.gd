extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MAX_TARGET_SWITCH_TIME = 2.0
const TARGET_SWITCH_THRESHOLD = 1.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var health_component: Node = $health_component


var current_target: Node3D = null
var time_since_target_switch: float = 0.0

func _ready() -> void:
	# Wait for scene tree to be ready
	await get_tree().process_frame
	
	# Connect damage signal
	$hit_box.connect("body_entered", take_damage)
	
	# Initialize navigation
	call_deferred("_initialize_navigation")

func _initialize_navigation() -> void:
	# Ensure navigation is properly initialized
	await get_tree().physics_frame
	find_closest_player()

func _physics_process(delta: float) -> void:
	# Apply gravity when not on floor
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	_handle_target_switching(delta)
	_update_movement()
	move_and_slide()

func _handle_target_switching(delta: float) -> void:
	time_since_target_switch += delta
	if time_since_target_switch >= MAX_TARGET_SWITCH_TIME:
		find_closest_player()
		time_since_target_switch = 0.0

func _update_movement() -> void:
	if not current_target:
		return
	
	# Update navigation target
	nav_agent.target_position = current_target.global_position
	
	# Get next navigation point
	var next_position: Vector3 = nav_agent.get_next_path_position()
	
	# Calculate direction
	var direction: Vector3 = (next_position - global_position).normalized()
	
	# Update velocity
	velocity.x = direction.x * SPEED
	velocity.z = direction.z * SPEED
	
	# Update rotation - Only if we're actually moving
	var look_at_pos = Vector3(next_position.x, global_position.y, next_position.z)
	if not global_position.is_equal_approx(look_at_pos):
		look_at(look_at_pos, Vector3.UP)

func find_closest_player() -> void:
	var players = get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	
	var closest_distance: float = INF
	var closest_player: Node3D = null
	
	for player in players:
		var distance = global_position.distance_to(player.global_position)
		
		# Only switch if new target is significantly closer
		if current_target and distance >= closest_distance - TARGET_SWITCH_THRESHOLD:
			continue
		
		closest_distance = distance
		closest_player = player
	
	if closest_player:
		current_target = closest_player

func take_damage(body: Node) -> void:
	if not body.is_in_group("bullet"):
		return
		
	health_component.take_damage(body.damage)
	body.queue_free()
