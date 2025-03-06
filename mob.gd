extends RigidBody2D

var health = 50.0
var max_health = 50.0
var is_dead = false
@export var chase_speed = 150.0  # Fixed speed for chasing player
@export var damage = 5.0  # Each monster can have different damage
var repulsion_active = false

func _ready():
	$AnimatedSprite2D.play()
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	add_to_group("mobs") # Add mob to group for collision detection
	
	# Create health bar
	var health_bar = preload("res://health_bar.gd").new()
	add_child(health_bar)
	health_bar.name = "HealthBar"
	health_bar.width = 30 # Smaller width for mobs
	health_bar.offset = Vector2(0, -20) # Adjust offset for mobs
	health_bar.update_health(health, max_health)
	
	# Change physics mode to enable controlled movement
	freeze = false
	gravity_scale = 0
	linear_damp = 1.0
	contact_monitor = true
	max_contacts_reported = 4
	
	# Randomize damage slightly for each monster instance
	damage = randf_range(4.0, 6.0)  # Random damage between 4-6

func _physics_process(_delta):
	if is_dead:
		return
		
	var player = get_node("/root/Main/Player")
	if !player:
		return
	
	# Calculate direction to player
	var direction_to_player = (player.global_position - global_position).normalized()
	var final_velocity = direction_to_player * chase_speed
	
	# Get all nearby mobs and calculate avoidance
	var nearby_mobs = get_tree().get_nodes_in_group("mobs")
	var avoidance_force = Vector2.ZERO
	
	for other_mob in nearby_mobs:
		if other_mob != self:
			var to_other = global_position.direction_to(other_mob.global_position)
			var distance = global_position.distance_to(other_mob.global_position)
			
			if distance < 15:  # If closer than desired separation
				# Calculate avoidance vector (stronger when closer)
				var avoidance = -to_other * (15.0 / max(distance, 1.0)) * chase_speed
				avoidance_force += avoidance
	
	# If there are mobs to avoid, adjust the velocity
	if avoidance_force != Vector2.ZERO:
		# Normalize avoidance force and scale it
		avoidance_force = avoidance_force.normalized() * chase_speed
		
		# Blend between direct path to player and avoidance
		# More weight to avoidance when very close to other mobs
		var blend_factor = clamp(avoidance_force.length() / chase_speed, 0.0, 1.0)
		final_velocity = final_velocity.lerp(avoidance_force, blend_factor)
	
	# Apply the final movement
	linear_velocity = final_velocity
	
	# Update sprite direction
	if final_velocity.x != 0:
		$AnimatedSprite2D.flip_h = final_velocity.x < 0

func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	$HealthBar.update_health(health, max_health)
	
	if health <= 0:
		die()

func die():
	is_dead = true
	# Give experience to player
	var player = get_node("/root/Main/Player")
	if player:
		player.gain_exp(1)  # Give 1 exp per mob kill
	hide()
	queue_free()

# Remove the screen exit handler since mobs will now chase the player
# func _on_VisibilityNotifier2D_screen_exited():
#     queue_free()

func apply_repulsion(repel_vector):
	if repel_vector.length() > 0:
		global_position += repel_vector
		repulsion_active = true
		await get_tree().create_timer(0.1).timeout
		repulsion_active = false

# Add collision handling
func _on_body_entered(body):
	if body.is_in_group("mobs"):
		# Check distance between mob centers
		var distance = global_position.distance_to(body.global_position)
		if distance < 15:  # 15 pixel minimum separation
			# Calculate repulsion direction and strength
			var repel_direction = (global_position - body.global_position).normalized()
			var repel_strength = (15 - distance) * 2  # Stronger repulsion when closer
			
			# Apply repulsion to both mobs
			global_position += repel_direction * repel_strength
			body.apply_repulsion(-repel_direction * repel_strength)
			
			# Add opposing velocities
			linear_velocity += repel_direction * 150
			body.linear_velocity += -repel_direction * 150

func _integrate_forces(state):
	# Additional repulsion check during physics integration
	for body in get_colliding_bodies():
		if body.is_in_group("mobs"):
			var distance = global_position.distance_to(body.global_position)
			if distance < 15:
				var repel_direction = (global_position - body.global_position).normalized()
				state.linear_velocity += repel_direction * 150
