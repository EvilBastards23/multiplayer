extends Node

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 5.0
@export var max_enemies: int = 10
@export_range(0, 10) var min_enemies: int = 10  # Minimum enemies to maintain

@onready var spawn_area: Area3D = $"spawner area"
@onready var collision_shape: CollisionShape3D = $"spawner area/CollisionShape3D"
@onready var spawn_timer: Timer = $SpawnTimer

var active_enemies: Array[Node] = []

func _ready() -> void:
	if not is_multiplayer_authority():
		return
		
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()
	
	# Initial spawn
	for i in min_enemies:
		spawn_enemy.rpc()

func _on_spawn_timer_timeout() -> void:
	if not is_multiplayer_authority():
		return
	
	# Clean up any null references (dead enemies)
	active_enemies = active_enemies.filter(func(enemy): return is_instance_valid(enemy))
	
	# Only spawn if below max enemies
	if active_enemies.size() < max_enemies:
		spawn_enemy.rpc()

@rpc("authority", "call_local")
func spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()
	
	# Get random position within the Area3D
	var spawn_position = get_random_position_in_area()
	enemy.position = spawn_position
	
	# Track enemy
	active_enemies.append(enemy)
	
	# Connect to enemy's death
	if enemy.has_node("health_component"):
		enemy.get_node("health_component").died.connect(
			func():
				if not enemy.is_dead:
				
					active_enemies.erase(enemy)
					enemy.is_dead = true
		)

	# Add to scene
	add_child(enemy, true)

func get_random_position_in_area() -> Vector3:
	# Get the collision shape's extents (assuming BoxShape3D)
	var box_shape: BoxShape3D = collision_shape.shape
	var extents = box_shape.size / 2
	
	# Generate random position within the box
	var random_position = Vector3(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y),
		randf_range(-extents.z, extents.z)
	)
	
	# Transform the position to world space
	return collision_shape.global_position + random_position
