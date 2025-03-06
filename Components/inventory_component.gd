extends Node
var inventory = []  # Array to store items
const max_inventory_size: int = 2
var parent: CharacterBody3D
var is_full: bool = false
signal show_label(texture: TextureRect)
signal hide_label(texture: TextureRect)
# Dictionary to store item names and their respective scenes
var item_scenes: Dictionary = {
	"health_potion": preload("res://Core/Scene/Game_Scene/health_potion.tscn"),
	"speed_potion": preload("res://Core/Scene/Game_Scene/speed_potion.tscn"),
	"soul": preload("res://Core/Scene/Game_Scene/soul.tscn")
}
# Dictionary to store item textures for UI
var item_textures: Dictionary = {
	"health_potion": preload("res://Background/Icon24.png"),
	"speed_potion": preload("res://Background/Icon26.png"),
	"soul": preload("res://Background/Icon40.png")
}
func _ready() -> void:
	parent = get_parent()
# Add item to inventory (called locally by authoritative player)
func add_inventory(item: String) -> void:
	if inventory.size() < max_inventory_size:
		inventory.append(item)
		print("Item added: " + item + " (Inventory size: " + str(inventory.size()) + ")")
		
		# Remove the item from the world if it exists
		for child in get_tree().get_nodes_in_group("dropped_items"):
			if child.item_name == item:
				child.queue_free()
				break
		
		# Sync inventory across all clients
		rpc("sync_inventory", inventory)
		if parent.is_multiplayer_authority():
			update_inventory_ui()
	else:
		print("Inventory is full! Cannot add " + item)
		is_full = true
# Drop an item
func drop_item(item: String) -> void:
	if item in inventory:
		var item_index = inventory.find(item)
		if item_index != -1:
			inventory.remove_at(item_index)
		
			if item_scenes.has(item):
				rpc("spawn_dropped_item", item, parent.global_transform)
		
			# Sync inventory across all clients
			rpc("sync_inventory", inventory)
			if parent.is_multiplayer_authority():
				update_inventory_ui()
			
			if is_full:
				is_full = false
# Use an item
func use_item(item: String) -> void:
	if item in inventory:
		var item_index = inventory.find(item)
		var scene_index = item_scenes.find_key(item)
		if item_index != -1 and scene_index != -1:
			var item_instance = item_scenes[item].instantiate()
			if item_instance.has_method("consume"):
				item_instance.consume(parent)
				inventory.remove_at(item_index)
				
				# Sync inventory after using item
				rpc("sync_inventory", inventory)
				if parent.is_multiplayer_authority():
					update_inventory_ui()
				
	else:
		print("Item not found in inventory!")
# RPC to sync inventory state across all clients
@rpc("authority", "call_local", "reliable")
func sync_inventory(new_inventory: Array) -> void:
	inventory = new_inventory.duplicate()  # Update local inventory
	if parent.is_multiplayer_authority():
		update_inventory_ui()
# RPC to spawn dropped item
@rpc("authority", "call_local", "reliable")
func spawn_dropped_item(item: String, transform_data: Transform3D) -> void:
	if item_scenes.has(item):
		var dropped_item = item_scenes[item].instantiate()
		dropped_item.scale = Vector3(0.4, 0.4, 0.4)
		var drop_offset = parent.global_transform.basis.z.normalized() * 2
		dropped_item.global_transform = transform_data.translated(drop_offset + Vector3(0, 1, 0))
		
		get_tree().get_root().add_child(dropped_item)
		dropped_item.add_to_group("dropped_items")
		dropped_item.item_name = item
# Update the UI (only for the authoritative player)
func update_inventory_ui() -> void:
	if not parent.is_multiplayer_authority():
		return
	
	print("Current inventory: " + str(inventory))
	is_full = inventory.size() >= max_inventory_size
	
	if parent.has_node("CanvasLayer"):
		var grid_container = parent.get_node("CanvasLayer/item_ui/GridContainer")
		if grid_container:
			# Clear all TextureRects
			for i in range(max_inventory_size):
				var texture_rect = grid_container.get_node("TextureRect" + str(i + 1))
				if texture_rect:
					texture_rect.texture = null
					emit_signal("hide_label", texture_rect)
			
			# Assign textures based on inventory
			for idx in range(inventory.size()):
				var item_name = inventory[idx]
				if item_textures.has(item_name):
					var texture_rect = grid_container.get_node("TextureRect" + str(idx + 1))
					if texture_rect:
						texture_rect.texture = item_textures[item_name]
						emit_signal("show_label", texture_rect)
			
			# Debug print to verify UI update
			print("UI updated with inventory: ", inventory)
