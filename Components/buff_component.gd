extends Node

class_name BuffComponent

# Buff structure: { effect_type: { value, duration, timer } }
var active_buffs: Dictionary = {}
var target:CharacterBody3D
func _ready() -> void:
	target = get_parent()


# Apply a buff or debuff
func apply_buff(effect_type: String, value: float, duration: float):
	if not target:
		return

	# If the effect is already active, refresh the timer
	if effect_type in active_buffs:
		active_buffs[effect_type]["timer"].start(duration)
		return
	
	# Apply effect based on type
	match effect_type:
		"speed":
				target.SPEED +=value
		#"damage_boost":
			#if target.has_method("increase_damage"):
				#target.increase_damage(value)
		#"defense_boost":
			#if target.has_method("increase_defense"):
				#target.increase_defense(value)
		#"slow":
			#if target.has_method("decrease_speed"):
				#target.decrease_speed(value)
		#"weaken":
			#if target.has_method("decrease_damage"):
				#target.decrease_damage(value)
		#"vulnerable":
			#if target.has_method("decrease_defense"):
				#target.decrease_defense(value)
		#_:
			#print("Unknown buff: " + effect_type)
			#return

	# Create a timer to remove the effect after duration
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	timer.timeout.connect(func(): remove_buff(effect_type, value))
	add_child(timer)
	timer.start()

	# Store active buff data
	active_buffs[effect_type] = { "value": value, "duration": duration, "timer": timer }
	print(target.name + " received " + effect_type + " for " + str(duration) + " seconds.")

# Remove buff after duration expires
func remove_buff(effect_type: String, value: float):
	if effect_type not in active_buffs:
		return

	match effect_type:
		"speed":
				target.SPEED -= value  # Reverse effect
		#"damage_boost":
			#if target.has_method("increase_damage"):
				#target.increase_damage(-value)
		#"defense_boost":
			#if target.has_method("increase_defense"):
				#target.increase_defense(-value)
		#"slow":
			#if target.has_method("decrease_speed"):
				#target.decrease_speed(-value)
		#"weaken":
			#if target.has_method("decrease_damage"):
				#target.decrease_damage(-value)
		#"vulnerable":
			#if target.has_method("decrease_defense"):
				#target.decrease_defense(-value)

	# Clean up
	active_buffs[effect_type]["timer"].queue_free()
	active_buffs.erase(effect_type)
	print(target.name + "'s " + effect_type + " effect has worn off.")
