extends Camera3D

@export var target_path: NodePath  # Path to the player/target node
@export var follow_speed: float = 5.0  # How quickly the camera follows the target
@export var height: float = 10.0  # Camera height above target
@export var distance: float = 12.0  # Distance behind target
@export var angle: float = 45.0  # Camera angle in degrees (0 = horizontal, 90 = top-down)
@export var smoothing: bool = true  # Enable smooth camera movement
@export var offset: Vector3 = Vector3(0, 0, 0)  # Optional offset from target

var target: Node3D  # Reference to target node
var target_pos: Vector3  # Position we want camera to be at

func _ready():
	if target_path:
		target = get_node(target_path)
	
	# Set initial camera position
	if target:
		_update_camera_position()

func _physics_process(delta):
	if !target:
		return
	
	_update_camera_position(delta)

func _update_camera_position(delta: float = 1.0):
	# Convert angle to radians
	var angle_rad = deg_to_rad(angle)
	
	# Calculate the position offset using trigonometry
	var height_component = sin(angle_rad) * distance
	var back_component = cos(angle_rad) * distance
	
	# Calculate desired camera position
	target_pos = target.position + Vector3(
		offset.x,
		height + height_component + offset.y,
		back_component + offset.z
	)
	
	if smoothing:
		# Smoothly interpolate to target position
		position = position.lerp(target_pos, follow_speed * delta)
	else:
		# Directly set position
		position = target_pos
	
	# Make camera look at target with offset
	look_at(target.position + Vector3(offset.x, offset.y, offset.z))

# Optional method to change camera angle during runtime
func set_camera_angle(new_angle: float):
	angle = clamp(new_angle, 0, 90)
	_update_camera_position()
