extends CharacterBody3D

@export var bolder_speed: float = 10.0  # Speed of the boulder
var direction: Vector3  # The direction the boulder will move in

# This method is called by the BoulderSummonComponent to set the movement direction
func set_direction(player_direction: Vector3) -> void:
	direction = player_direction.normalized()  # Normalize direction to keep speed consistent

func _process(delta: float) -> void:
	# Move the boulder in the set direction with the specified speed
	velocity = direction * bolder_speed
	move_and_slide()
