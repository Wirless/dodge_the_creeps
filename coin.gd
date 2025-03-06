extends Area2D

var speed = 400
var pickup_radius = 100  # Increased for better magnetism
var is_being_collected = false
var target_player = null
var start_scale = Vector2(1.0, 1.0)
var value = 1
var acceleration = 1000  # Added for smoother attraction
var current_velocity = Vector2.ZERO  # Track current movement

func _ready():
	print("Coin ready!")  # Debug print
	z_index = 0
	scale = start_scale
	modulate = Color(1.0, 1.0, 0.0, 1.0)  # Yellow tint
	
	# Debug sprite information
	var sprite = $Sprite2D
	if sprite:
		print("Sprite exists with texture: ", sprite.texture)
		print("Sprite modulate: ", sprite.modulate)
		print("Sprite scale: ", sprite.scale)
		print("Sprite position: ", sprite.position)
		# Make sure sprite is visible
		sprite.modulate = Color(1, 1, 0, 1)  # Yellow color
		sprite.visible = true
	else:
		print("No sprite found!")
	
	print("Coin position: ", global_position)
	add_to_group("coins")  # Add to coins group for tracking

func _physics_process(delta):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		
		# Check if player is within pickup radius
		if distance < pickup_radius:
			is_being_collected = true
			target_player = player
			
			# Calculate direction to player
			var direction = (player.global_position - global_position).normalized()
			
			# Apply acceleration towards player
			current_velocity += direction * acceleration * delta
			
			# Cap maximum speed
			if current_velocity.length() > speed:
				current_velocity = current_velocity.normalized() * speed
				
			# Move coin
			global_position += current_velocity * delta
			
			# Scale and fade based on distance
			var distance_factor = clamp(distance / pickup_radius, 0.1, 1.0)
			scale = start_scale * distance_factor
			
			# If very close to player, collect
			if distance < 10:
				collect()
		else:
			# Reset velocity when out of range
			current_velocity = Vector2.ZERO
			is_being_collected = false
			target_player = null
			scale = start_scale
			modulate.a = 1.0

func collect():
	# Add coin to HUD counter
	var hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.add_coins(value)
	# Optional: Add collection effect here (particles, sound, etc.)
	queue_free()

# Optional: Add cleanup when coin is removed
func _exit_tree():
	remove_from_group("coins")
