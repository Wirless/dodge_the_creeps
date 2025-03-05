extends RigidBody2D

var health = 50.0
var max_health = 50.0
var is_dead = false
@export var chase_speed = 150.0  # Fixed speed for chasing player
@export var damage = 5.0  # Damage dealt to player (matches the contact_damage in player.gd)

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

func _physics_process(_delta):
	if is_dead:
		return
		
	var player = get_node("/root/Main/Player")  # Adjust path if needed
	if player:
		# Calculate direction to player
		var direction = (player.global_position - global_position).normalized()
		# Set velocity towards player
		linear_velocity = direction * chase_speed
		
		# Update sprite direction
		if direction.x != 0:
			$AnimatedSprite2D.flip_h = direction.x < 0

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
