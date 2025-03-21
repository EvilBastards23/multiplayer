extends Node

signal health_changed(new_hp: int, max_hp: int)
signal died()  # New signal for death events

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
	
	# Check for death after health update
	if current_hp <= min_hp:
		died.emit()
		handle_death.rpc()

@rpc("any_peer", "call_local")
func take_damage(damage: int) -> void:
	if not is_multiplayer_authority():
		return  # Prevent clients from applying damage
	
	current_hp = max(min_hp, current_hp - damage)
	update_health.rpc(current_hp, max_hp)  # Sync HP across network

@rpc("any_peer", "call_local")
func restore_health(amount: int) -> void:
	if not is_multiplayer_authority():
		return
	
	current_hp = min(max_hp, current_hp + amount)
	update_health.rpc(current_hp, max_hp)  # Sync HP across network

@rpc("any_peer", "call_local")
func increase_max_hp(amount: int) -> void:
	if not is_multiplayer_authority():
		return
	
	max_hp += amount
	update_health.rpc(current_hp, max_hp)  # Sync new max HP

@rpc("any_peer", "call_local")
func decrease_max_hp(amount: int) -> void:
	if not is_multiplayer_authority():
		return
	
	max_hp = max(min_hp, max_hp - amount)
	current_hp = min(current_hp, max_hp)  # Prevent exceeding max HP
	update_health.rpc(current_hp, max_hp)  # Sync across network

@rpc("authority", "call_local")
func handle_death() -> void:
	# Get the parent node (player or enemy)
	var parent = get_parent()
	
	
	if parent.is_in_group("players"):
		# If we're running on the server, queue free with a small delay
		# This ensures all clients receive the death notification
		if is_multiplayer_authority():
			parent.is_dead = true
			parent.hide()
			parent.get_node("CollisionShape3D").call_deferred("set_disabled", true)
			parent.camera.target = parent.get_parent().get_camera2().target
			parent.soul_component.drop_soul()
			parent.position = Vector3(0,100,0)
			
		# If we're on a client, we can queue free immediately
		else:
			parent.is_dead = true
			parent.hide()
			parent.get_node("CollisionShape3D").call_deferred("set_disabled", true)
			#parent.camera.target = parent.get_parent().get_camera1().target
	elif parent.is_in_group("Mob"):
		
		emit_signal("died")
		
		parent.queue_free()
		
			
