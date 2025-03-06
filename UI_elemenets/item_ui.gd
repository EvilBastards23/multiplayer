extends Control
@export var inventory: Node
@onready var texture_rect: TextureRect = $GridContainer/TextureRect1
@onready var texture_rect_2: TextureRect = $GridContainer/TextureRect2
@onready var drop_timer: Timer = $DropTimer
var selected_index: int = 0
var held_key_index: int = -1
var is_dropping: bool = false
var active_inputs: Dictionary = {}

func _ready() -> void:
	# Only connect signals and process input for the authoritative player
	if is_multiplayer_authority():
		texture_rect.gui_input.connect(_on_slot_pressed.bind(0))
		texture_rect_2.gui_input.connect(_on_slot_pressed.bind(1))
		
		# Connect the inventory signals to our methods
		inventory.connect("hide_label", Callable(self, "hide_label"))
		inventory.connect("show_label", Callable(self, "show_label"))
		
		# Connect timer
		drop_timer.timeout.connect(_on_drop_timer_timeout)
		drop_timer.one_shot = true
		
		# Debug print to confirm connections
		print("UI signals connected")
	else:
		# Hide UI for non-authoritative players (optional)
		visible = false

func hide_label(texture: TextureRect) -> void:
	if is_multiplayer_authority():
		print("Hiding label for: ", texture.name)
		var label = texture.get_node("Label")
		if label:
			label.hide()
		else:
			print("ERROR: Label node not found in ", texture.name)

func show_label(texture: TextureRect) -> void:
	if is_multiplayer_authority():
		print("Showing label for: ", texture.name)
		var label = texture.get_node("Label")
		if label:
			label.show()
		else:
			print("ERROR: Label node not found in ", texture.name)

func _on_slot_pressed(event: InputEvent, index: int) -> void:
	if not is_multiplayer_authority():
		return
	if event is InputEventMouseButton:
		if event.pressed:
			start_drop_timer(index, "mouse")
		elif event.is_released():
			if held_key_index == index and not is_dropping and has_item_at_index(index):
				use_item_at_index(index)
			reset_drop_state("mouse")

func _input(event) -> void:
	if not is_multiplayer_authority():
		return
	if event.is_action_pressed("use_item_left"):
		selected_index = 0
		start_drop_timer(selected_index, "q")
	elif event.is_action_released("use_item_left"):
		if held_key_index == selected_index and not is_dropping and has_item_at_index(selected_index):
			use_item_at_index(selected_index)
		reset_drop_state("q")
	if event.is_action_pressed("use_item_right"):
		selected_index = 1
		start_drop_timer(selected_index, "e")
	elif event.is_action_released("use_item_right"):
		if held_key_index == selected_index and not is_dropping and has_item_at_index(selected_index):
			use_item_at_index(selected_index)
		reset_drop_state("e")
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				selected_index = 0
				start_drop_timer(0, "1")
			KEY_2:
				selected_index = 1
				start_drop_timer(1, "2")
	elif event is InputEventKey and event.is_released():
		match event.keycode:
			KEY_1:
				if held_key_index == 0 and not is_dropping and has_item_at_index(0):
					use_item_at_index(0)
				reset_drop_state("1")
			KEY_2:
				if held_key_index == 1 and not is_dropping and has_item_at_index(1):
					use_item_at_index(1)
				reset_drop_state("2")

func has_item_at_index(index: int) -> bool:
	return index >= 0 and index < inventory.inventory.size() and inventory.inventory[index] != null

func start_drop_timer(index: int, input_id: String) -> void:
	if not active_inputs.has(input_id):
		active_inputs[input_id] = true
	held_key_index = index
	is_dropping = false
	if not drop_timer.is_stopped():
		drop_timer.stop()
	if has_item_at_index(index):
		drop_timer.start(0.5)

func _on_drop_timer_timeout() -> void:
	if held_key_index != -1 and active_inputs.size() > 0 and has_item_at_index(held_key_index):
		is_dropping = true
		drop_item_at_index(held_key_index)
		print("Item dropped from index: ", held_key_index)

func use_item_at_index(index: int) -> void:
	if has_item_at_index(index):
		var item_name = inventory.inventory[index]
		inventory.use_item(item_name)
		print("Item used from index: ", index)

func drop_item_at_index(index: int) -> void:
	if has_item_at_index(index):
		var item_name = inventory.inventory[index]
		inventory.drop_item(item_name)

func reset_drop_state(input_id: String) -> void:
	if active_inputs.has(input_id):
		active_inputs.erase(input_id)
	if active_inputs.size() == 0:
		held_key_index = -1
		is_dropping = false
		drop_timer.stop()
