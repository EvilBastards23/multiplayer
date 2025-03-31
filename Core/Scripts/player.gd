extends CharacterBody3D

# Constants for movement speed and jump velocity
var SPEED:int = 10
const JUMP_VELOCITY = 4.5
var is_dead:bool = false
const MOB_KNOCKBACK_FORCE = 80.0  # Force to push mobs away when they're hit

# Exported variable for camera reference
@export var camera: Camera3D
@onready var health_component: Node = $health_component
@onready var healt_bar: Node3D = $healt_bar
@onready var buff_component: BuffComponent = $buff_component



@onready var level_menu: Control = $CanvasLayer/level_menu
@onready var level_component: Node = $level_component




# Called when the node enters the scene tree
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())


# Called when the node is ready
func _ready() -> void:
	
	if is_multiplayer_authority():
		camera = get_parent().get_camera1()
		camera.target = self
	else:
		camera = get_parent().get_camera2()
		camera.target = self
	
		
	position = Vector3(0, 0.852, 18.223)
	$hit_box.connect("body_entered", take_damage)
	if is_multiplayer_authority():
		$CanvasLayer.visible = true
	else:
		$CanvasLayer.visible = false
	
	
# Function to check if mouse is over any UI element
func is_mouse_over_ui() -> bool:
	# Get the mouse position
	var mouse_pos = get_viewport().get_mouse_position()
	# Check if any Control node in the UI layer is under the mouse
	for child in $CanvasLayer.get_children():
		if child is Control and child.visible:
			if child.get_global_rect().has_point(mouse_pos):
				return true
	return false

# Handle input
func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	# If the mouse is over UI, prevent shooting and other mouse interactions
	if is_mouse_over_ui() and (event is InputEventMouseButton or event.is_action("summon_boulder")):
		get_tree().set_input_as_handled()
		return

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority() and !is_dead:
		if not is_on_floor():
			velocity += get_gravity() * delta

		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# WASD movement
		var input_dir = Vector2.ZERO
		input_dir.x = Input.get_action_strength("d") - Input.get_action_strength("a")
		input_dir.y = Input.get_action_strength("s") - Input.get_action_strength("w")
		input_dir = input_dir.normalized()
		
		var camera_basis = camera.global_transform.basis
		var direction = Vector3.ZERO
		direction += camera_basis.x * input_dir.x
		direction += camera_basis.z * input_dir.y
		direction.y = 0
		direction = direction.normalized()

		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			$AnimationPlayer.play("Run")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			velocity.z = move_toward(velocity.z, 0, SPEED)
			$AnimationPlayer.play("Idle")

		move_and_slide()

		# Only handle mouse aiming if not over UI
		if not is_mouse_over_ui():
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
				look_at_pos.y = global_position.y
				look_at(look_at_pos)
			
func take_damage(body)->void:
	if body.is_in_group("bullet"):
		$health_component.take_damage(body.damage)
		body.queue_free()
	if body.is_in_group("Mob"):
		$health_component.take_damage(body.damage)
		body.knock_back()
		



func spawn(area: Area3D):
	is_dead = false
	self.show()
	health_component.current_hp = health_component.max_hp
	# Get the collision shape inside the Area3D
	var collision_shape = area.get_node_or_null("CollisionShape3D")
	if collision_shape and collision_shape.shape is BoxShape3D:
		var shape: BoxShape3D = collision_shape.shape
		var extents = shape.size / 2  # Half the size for proper positioning
		var center = collision_shape.global_transform.origin
		
		# Generate a random position within the box shape
		var random_x = randf_range(center.x - extents.x, center.x + extents.x)
		var random_y = randf_range(center.y - extents.y, center.y + extents.y)
		var random_z = randf_range(center.z - extents.z, center.z + extents.z)
		
		var spawn_position = Vector3(random_x, random_y, random_z)
		global_transform.origin = spawn_position

	else:
		push_error("No valid CollisionShape3D found in Area3D!")

	# Enable collision after spawning
	get_node("CollisionShape3D").call_deferred("set_disabled", false)
	
	# Set camera to follow this character
	camera.target = self
