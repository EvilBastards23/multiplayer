extends Area3D

# Dictionary to store multiple players by their IDs
var players: Dictionary = {}

func _ready() -> void:
	# Connect area signals

	
	# Set up keyboard shortcut for the button
	var shortcut := Shortcut.new()
	var key_event := InputEventKey.new()
	key_event.keycode = KEY_F  
	shortcut.set_events([key_event])
	$"../CanvasLayer/Control/Button".shortcut = shortcut

func player_entered(body) -> void:
	if body.is_in_group("players"):
		# Only show UI elements for the local player (multiplayer authority)
		if body.is_multiplayer_authority():
			# Store the player reference in our dictionary using their unique ID
			var player_id = body.get_multiplayer_authority()
			players[player_id] = body
			
			# Show interaction prompt
			$"../CanvasLayer/Control/Label".show()

func player_exited(body) -> void:
	if body.is_in_group("players"):
		# Only handle UI elements for the local player
		if body.is_multiplayer_authority():
			# Get the player ID
			var player_id = body.get_multiplayer_authority()
			
			# Hide the level menu if it's showing
			if players.has(player_id):
				body.level_menu.hide()
				$"../CanvasLayer/shop_menu".hide()
				
			# Remove player from our tracking dictionary
			players.erase(player_id)
			
			# Hide interaction prompt if no players are in range
			if players.size() == 0:
				$"../CanvasLayer/Control/Label".hide()

func _on_button_pressed() -> void:
	# Only respond to button press if we're the multiplayer authority
	var local_player = null
	
	# Find the local player in our players dictionary
	for player_id in players.keys():
		var player = players[player_id]
		if player.is_multiplayer_authority():
			local_player = player
			break
	# If we found the local player, show their level menu
	if local_player != null:
		$"../CanvasLayer/shop_menu".show()
		$"../CanvasLayer/shop_menu/Panel/next_level_label".text = str(local_player.level_component.current_cost)
		$"../CanvasLayer/shop_menu/Panel/current_soul_label".text = str(local_player.soul_component.soul_value)
		local_player.level_menu.show()
		$"../CanvasLayer/Control/Label".hide()


func _on_buy_soul_pressed() -> void:
	# Find the local player in our players dictionary
	var local_player = null
	
	for player_id in players.keys():
		var player = players[player_id]
		if player.is_multiplayer_authority():
			local_player = player
			break
	
	# If we found the local player, handle the soul purchase
	if local_player != null:
		var soul_component = local_player.soul_component
		var level_component = local_player.level_component
		
		# Check if player has enough souls to purchase level upgrade
		if soul_component.soul_value >= level_component.current_cost:
			# Subtract cost from souls
			soul_component.soul_value -= level_component.current_cost
			
			# Increase level
			level_component.upgrade()
			
			# Update UI text
			$"../CanvasLayer/shop_menu/Panel/next_level_label".text = str(level_component.current_cost)
			$"../CanvasLayer/shop_menu/Panel/current_soul_label".text = str(soul_component.soul_value)
			local_player.soul_ui.chaging_label(level_component.current_cost)
		else:
			# Optional: Show message that player doesn't have enough souls
			print("Not enough souls to level up!")
	
