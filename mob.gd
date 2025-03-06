extends RigidBody2D

var health = 50.0
var max_health = 50.0
var is_dead = false
@export var chase_speed = 150.0  # Fixed speed for chasing player
@export var damage = 5.0  # Each monster can have different damage
var repulsion_active = false
const Coin = preload("res://coin.tscn")
var coin_drop_chance = 1.0  # Changed to 100% for testing

func _ready():
	$AnimatedSprite2D.play()
	var mob_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = mob_types.pick_random()
	add_to_group("mobs") # Add mob to group for collision detection
	
	# Physics settings
	freeze = false
	gravity_scale = 0
	linear_damp = 1.0
	contact_monitor = true
	max_contacts_reported = 4
	
	# Create health bar
	var health_bar = preload("res://health_bar.gd").new()
	add_child(health_bar)
	health_bar.name = "HealthBar"
	health_bar.width = 30 # Smaller width for mobs
	health_bar.offset = Vector2(0, -20) # Adjust offset for mobs
	health_bar.update_health(health, max_health)
	
	# Randomize damage slightly for each monster instance
	damage = randf_range(4.0, 6.0)  # Random damage between 4-6

func _physics_process(_delta):
	if is_dead:
		return
		
	var player = get_node("/root/Main/Player")
	if !player:
		return
	
	# First, handle mob separation
	var separation_force = Vector2.ZERO
	var nearby_mobs = get_tree().get_nodes_in_group("mobs")
	
	for other_mob in nearby_mobs:
		if other_mob != self and is_instance_valid(other_mob) and !other_mob.is_dead:
			var to_other = global_position - other_mob.global_position
			var distance = to_other.length()
			
			if distance < 50:  # Increased to 50 pixel separation
				# Strong separation force when too close
				var separation = to_other.normalized() * (50 - distance) * 20
				separation_force += separation
				
				# Immediate position correction if extremely close
				if distance < 40:  # Also increased
					global_position += to_other.normalized() * (50 - distance)
	
	# Then handle player chasing
	var to_player = player.global_position - global_position
	var direction_to_player = to_player.normalized()
	
	# Combine forces
	var final_velocity = Vector2.ZERO
	
	if separation_force.length() > 0:
		# Prioritize separation when too close to other mobs
		final_velocity = separation_force.normalized() * chase_speed * 2
	else:
		# Normal chase behavior when not too close to others
		final_velocity = direction_to_player * chase_speed
	
	# Set the final velocity
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
	var player = get_node("/root/Main/Player")
	if player:
		player.gain_exp(1)
	
	# Debug coin spawn
	print("Spawning coin at position: ", global_position)
	var coin = Coin.instantiate()
	coin.global_position = global_position
	coin.modulate = Color(1, 1, 0, 1)  # Make sure it's yellow and visible
	coin.z_index = 0  # Make sure it's visible
	get_parent().add_child(coin)
	print("Coin spawned with position: ", coin.global_position)
	
	hide()
	queue_free()

# Remove the screen exit handler since mobs will now chase the player
# func _on_VisibilityNotifier2D_screen_exited():
#     queue_free()

func apply_repulsion(repel_vector):
	global_position += repel_vector
	linear_velocity += repel_vector * 2

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
