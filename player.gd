extends CharacterBody3D

const SPEED = 10
const JUMP_VELOCITY = 4.5

@export var camera: Camera3D

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready() -> void:
	
	if is_multiplayer_authority():
		
		camera = get_parent().get_camera1()
			
		camera.target = self
			
		print(camera.target.name)
	else:
			
		camera = get_parent().get_camera2()
		camera.target = self
		print(camera.target.name)
			
	position = Vector3(0,0.852,18.223)
	
	

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if is_multiplayer_authority():
		if not is_on_floor():
			velocity += get_gravity() * delta

		# Handle jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Get the input direction
		var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
		# Convert the input to world space direction relative to camera
		var camera_basis = camera.global_transform.basis
		var direction = Vector3.ZERO
		direction += camera_basis.x * input_dir.x
		direction += camera_basis.z * input_dir.y
		direction.y = 0  # Keep movement on the horizontal plane
		direction = direction.normalized()

		# Apply movement
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)

		move_and_slide()

		# Handle mouse aim
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_direction = camera.project_ray_normal(mouse_pos) * 500
		var ray_end = ray_origin + ray_direction
		
		var ray_query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		ray_query.collide_with_bodies = true
		
		var space_state = get_world_3d().direct_space_state
		var ray_result = space_state.intersect_ray(ray_query)
		
		if !ray_result.is_empty():
			var look_at_pos = ray_result.position
			look_at_pos.y = global_position.y  # Keep the look direction horizontal
			look_at(look_at_pos)
