extends Node

<<<<<<< HEAD
signal health_changed(new_hp: int, max_hp: int)

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
=======
@export var max_hp:int
var current_hp : int

func _ready() -> void:
	current_hp = max_hp
	
>>>>>>> ae4590d395038bf44e5e93bf5056f5b2035332ef
