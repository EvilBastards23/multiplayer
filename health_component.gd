extends Node

signal health_changed(new_hp: int, max_hp: int)
<<<<<<< HEAD
=======
signal died()  # New signal for death events
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869

@export var max_hp: int = 100
var current_hp: int = 100
const min_hp: int = 0

func _ready() -> void:
	if is_multiplayer_authority():  # Only the server initializes HP
		current_hp = max_hp

@rpc("authority", "call_local")
func update_health(new_hp: int, new_max_hp: int) -> void:
	current_hp = new_hp
	max_hp = new_max_hp
	health_changed.emit(current_hp, max_hp)
<<<<<<< HEAD
=======
	
	# Check for death after health update
	if current_hp <= min_hp:
		died.emit()
		handle_death.rpc()
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869

@rpc("any_peer", "call_local")
func take_damage(damage: int) -> void:
	if not is_multiplayer_authority():
		return  # Prevent clients from applying damage
<<<<<<< HEAD

=======
	
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869
	current_hp = max(min_hp, current_hp - damage)
	update_health.rpc(current_hp, max_hp)  # Sync HP across network

@rpc("any_peer", "call_local")
func restore_health(amount: int) -> void:
	if not is_multiplayer_authority():
		return
<<<<<<< HEAD

=======
	
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869
	current_hp = min(max_hp, current_hp + amount)
	update_health.rpc(current_hp, max_hp)  # Sync HP across network

@rpc("any_peer", "call_local")
func increase_max_hp(amount: int) -> void:
	if not is_multiplayer_authority():
		return
<<<<<<< HEAD

=======
	
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869
	max_hp += amount
	update_health.rpc(current_hp, max_hp)  # Sync new max HP

@rpc("any_peer", "call_local")
func decrease_max_hp(amount: int) -> void:
	if not is_multiplayer_authority():
		return
<<<<<<< HEAD

	max_hp = max(min_hp, max_hp - amount)
	current_hp = min(current_hp, max_hp)  # Prevent exceeding max HP
	update_health.rpc(current_hp, max_hp)  # Sync across network
=======
	
	max_hp = max(min_hp, max_hp - amount)
	current_hp = min(current_hp, max_hp)  # Prevent exceeding max HP
	update_health.rpc(current_hp, max_hp)  # Sync across network

@rpc("authority", "call_local")
func handle_death() -> void:
	# Get the parent node (player or enemy)
	var parent = get_parent()
	
	# If we're running on the server, queue free with a small delay
	# This ensures all clients receive the death notification
	if is_multiplayer_authority():
		
		parent.queue_free()
	# If we're on a client, we can queue free immediately
	else:
		parent.queue_free()
>>>>>>> ece3cb5a5642b03da83936a916c5939a513a8869
