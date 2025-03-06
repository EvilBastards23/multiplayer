extends CharacterBody3D

# Constants for movement speed and jump velocity
var SPEED:int = 10
const JUMP_VELOCITY = 4.5

# Exported variable for camera reference
@export var camera: Camera3D
@onready var health_component: Node = $health_component
@onready var healt_bar: Control = $healt_bar
@onready var buff_component: BuffComponent = $buff_component
@onready var inventory_component: Node = $inventory_component
@onready var item_ui: Control = $CanvasLayer/item_ui
@onready var soul_component: Node = $soul_component


# Called when the node enters the scene tree
func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

# Called when the node is ready
func _ready() -> void:
	health_component.current_hp = 50
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
	if is_mouse_over_ui() and (event is InputEventMouseButton or event.is_action("shoot")):
		get_tree().set_input_as_handled()
		return

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
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
