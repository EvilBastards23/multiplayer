extends Node3D

@onready var ready_button: Button = $Camera3D/CanvasLayer/Control/Button
var parent: Node
signal queue_changed

@onready var monicans := {
	1: $monican1,
	2: $monican2,
	3: $monican3,
	4: $monican4
}

var player_ids = {}  # Maps player index -> network ID
var ready_status := {}  # Tracks player readiness
var player_count: int = 0  # Start from 0, including the host

func _ready() -> void:
	parent = get_parent()
	multiplayer.multiplayer_peer.connect("peer_connected", on_peer_connected)
	ready_button.connect("pressed",_on_ready_button_pressed)
	# Host initialization
	if multiplayer.is_server():
		var host_id = multiplayer.get_unique_id()
		player_count += 1
		player_ids[player_count] = host_id
		ready_status[player_count] = false

		# Show the first monican for the host
		monicans[player_count].show()
		
func on_peer_connected(id: int) -> void:
	if player_count >= 4:
		print("Lobby full!")
		return

	player_count += 1
	player_ids[player_count] = id
	ready_status[player_count] = false

	if monicans.has(player_count):
		monicans[player_count].show()
		sync_monican_show.rpc(player_count)

	# Only the host should sync the player list to the new player
	if multiplayer.is_server():
		sync_all_players.rpc_id(id, player_ids,ready_status)
		sync_queue_change.rpc(player_count)

@rpc("authority")
func sync_queue_change(number:int)->void:
	var queue_string :String =  str(number) + "/4"
	emit_signal("queue_changed",queue_string)
	

@rpc("any_peer")
func sync_monican_show(player_index: int) -> void:
	if monicans.has(player_index):
		monicans[player_index].show()

@rpc("authority")
func sync_all_players(updated_player_ids: Dictionary, updated_ready_status:Dictionary) -> void:
	player_ids = updated_player_ids
	ready_status = updated_ready_status

func _on_ready_button_pressed() -> void:
		var local_id = multiplayer.get_unique_id()
		var player_index = player_ids.find_key(local_id)
		if player_index:
			ready_status[player_index] = !ready_status[player_index]
			
			sync_ready_state.rpc(player_index, ready_status[player_index])
			

@rpc("any_peer","call_local")
func sync_ready_state(player_index: int, is_ready: bool) -> void:
	if monicans.has(player_index):
		var checkbox: Control = monicans[player_index].get_node("SubViewport/Control")
		checkbox.check_player_ready(is_ready)
