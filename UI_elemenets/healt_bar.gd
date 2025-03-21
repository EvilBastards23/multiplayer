extends Node3D

@export var player: Node3D  # Assign the player in the editor
@onready var texture_progress_bar: TextureProgressBar = $SubViewport/Control/TextureProgressBar
@export var health_component: Node  # Assign the HealthComponent in the editor


func _ready() -> void:
	if health_component:
		texture_progress_bar.max_value = health_component.max_hp
		texture_progress_bar.value = health_component.current_hp

func _process(_delta: float) -> void:
	
	if health_component:
		texture_progress_bar.value = health_component.current_hp
	
	if player:
		var viewport := get_viewport()
		var camera := viewport.get_camera_3d()
		
		if camera:
			# Convert player's world position to screen position
			var screen_pos := camera.unproject_position(player.global_transform.origin + Vector3(0, 2, 0))  # Adjust Y offset
			
			
func update_hp_bar()->void:
	texture_progress_bar.value = health_component.current_hp
