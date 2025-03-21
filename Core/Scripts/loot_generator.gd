extends Node

var loot_references: Dictionary = {
	"health_potion": {
		"scene": preload("res://Core/Scene/Game_Scene/health_potion.tscn"),
		"chance": 10 
	},
	"speed_potion": {
		"scene": preload("res://Core/Scene/Game_Scene/speed_potion.tscn"),
		"chance": 1  
	},
	"no_loot": {  
		"scene": null,  # Represents no loot
		"chance": 89
	}
}

func get_loot(key: String) -> PackedScene:
	if key in loot_references:
		return loot_references[key]["scene"]
	return null

func random_loot() -> PackedScene:
	var loot_pool = []
	
	# Add loot based on their probability weight
	for key in loot_references.keys():
		var entry = loot_references[key]
		for i in range(entry["chance"]):  # Manually add the scene multiple times
			loot_pool.append(entry["scene"]) 
	
	# Select a random item from the weighted list
	if loot_pool.size() > 0:
		return loot_pool[randi() % loot_pool.size()]  # Get a random item
	
	return null  # Fallback if no loot is available
	
@rpc("any_peer","call_local")
func spawn_loot(position:Vector3):
	var loot = random_loot()
	if loot != null:
		var loott = loot.instantiate()
		get_tree().root.add_child(loott)
		loott.global_position = position
