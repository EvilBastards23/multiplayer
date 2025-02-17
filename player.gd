extends CharacterBody3D

# Constants for movement speed and jump velocity
const SPEED = 10
const JUMP_VELOCITY = 4.5

# Exported variable for camera reference
@export var camera: Camera3D

# Called when the node enters the scene tree
func _enter_tree() -> void:
	# Set the multiplayer authority to the player (based on their ID)
	set_multiplayer_authority(name.to_int())

# Called when the node is ready (after being added to the scene)
func _ready() -> void:
	
	# If this object has multiplayer authority (host or the player controlling the character)
	if is_multiplayer_authority():
		# Get the camera for the player from the parent node (camera1 for host or first player)
		camera = get_parent().get_camera1()
		# Set this player as the camera's target
		camera.target = self
		print(camera.target.name)  # Print the player's name (target of the camera)
	else:
		# For players who don't have authority (other clients), assign camera2
		camera = get_parent().get_camera2()
		# Set this player as the camera's target
		camera.target = self
		print(camera.target.name)  # Print the player's name (target of the camera)
		
	# Set initial position of the player
	position = Vector3(0, 0.852, 18.223)
	$hit_box.connect("body_entered",take_damage)
	

# Called every physics frame (for handling movement and physics)
func _physics_process(delta: float) -> void:
	# Add gravity if the player has multiplayer authority (host or main player)
	if is_multiplayer_authority():
		if not is_on_floor():
			# Apply gravity if not on the floor
			velocity += get_gravity() * delta

		# Handle jump: If the player presses the jump button (UI accept) and is on the floor
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			# Set vertical velocity for the jump
			velocity.y = JUMP_VELOCITY

		# Get input direction from user controls (arrow keys or WASD)
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Convert input direction into world space based on the camera orientation
		var camera_basis = camera.global_transform.basis
		var direction = Vector3.ZERO
		# Combine the input direction with the camera's forward and right directions
		direction += camera_basis.x * input_dir.x
		direction += camera_basis.z * input_dir.y
		direction.y = 0  # Ensure movement is only on the horizontal plane (no vertical tilt)
		direction = direction.normalized()  # Normalize the direction to prevent faster diagonal movement

		# Apply movement if there is an input direction
		if direction:
			velocity.x = direction.x * SPEED  # Horizontal movement in the X-axis
			velocity.z = direction.z * SPEED  # Horizontal movement in the Z-axis
		else:
			# If no input, gradually decelerate velocity towards 0 on the X and Z axes
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		# Apply the movement to the character, including physics and collision handling
		move_and_slide()

		# Handle mouse aiming (for example, for aiming weapons or orientation)
		var mouse_pos = get_viewport().get_mouse_position()  # Get the mouse position on the screen
		var ray_origin = camera.project_ray_origin(mouse_pos)  # Create a ray origin based on the camera and mouse position
		var ray_direction = camera.project_ray_normal(mouse_pos) * 500  # Create a ray direction with a length of 500 units
		var ray_end = ray_origin + ray_direction  # Calculate the endpoint of the ray
		
		# Set up a ray query to check for collisions along the ray's path
		var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		ray_query.collide_with_bodies = true  # Ensure the ray checks against physical bodies in the world
		
		# Perform the ray query to check for intersections with objects in the scene
		var space_state = get_world_3d().direct_space_state
		var ray_result = space_state.intersect_ray(ray_query)
		
		# If the ray hits something, adjust the player's rotation to "look" at the hit position
		if !ray_result.is_empty():
			var look_at_pos = ray_result.position  # Get the position where the ray hit
			look_at_pos.y = global_position.y  # Keep the look direction on the same horizontal plane as the player
			look_at(look_at_pos)  # Rotate the character to face the look-at position
			
func take_damage(body)->void:
	if body.is_in_group("bullet"):
		
		print("taking damage")
		$health_component.take_damage(body.damage)
		body.queue_free()
<<<<<<< HEAD
=======
		
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869
