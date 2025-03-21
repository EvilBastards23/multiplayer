extends CharacterBody3D

@export var bolder_speed: float = 0.0  # Speed of the boulder
var direction: Vector3  # The direction the boulder will move in
@export var damage:int

# This method is called by the BoulderSummonComponent to set the movement direction
func set_direction(player_direction: Vector3,damage_amount:int) -> void:
	direction = player_direction.normalized()  # Normalize direction to keep speed consistent
	damage = damage_amount
	$Node3D.rotation.y = atan2(player_direction.x, player_direction.z)

func _process(_delta: float) -> void:
	# Move the boulder in the set direction with the specified speed
	velocity = direction * bolder_speed
	move_and_slide()
