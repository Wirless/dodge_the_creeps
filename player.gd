extends Area2D

signal hit
signal health_changed(new_health) # New signal for health updates

@export var speed = 400 # How fast the player will move (pixels/sec).
@export var attack_radius = 80.0 # Radius of the attack
@export var attack_damage = 25.0 # Damage per attack
@export var attack_angle = 140.0 # Angle of the cone in degrees
var screen_size # Size of the game window.
var maxhealth = 100 # Player's health
var health = 100 # current health
var attack = 5 # current attack value
var attackspeed = 2000 #miliseconds
var can_take_damage = true # Damage cooldown flag
var damage_cooldown = 1.0 # Damage cooldown in seconds
var can_attack = true
var attack_cooldown = 0.5 # Attack cooldown in seconds
var is_dead = false
@export var contact_damage = 5      # Initial damage when monster touches player
@export var dot_damage = 5          # Damage over time while in monster radius
@export var dot_interval = 2.0      # Seconds between damage ticks
var in_contact_with_mobs = {}       # Track mob contact time and timers
var current_level = 1
var current_exp = 0
var exp_to_next_level = 125  # Initial exp needed for level 1->2
var hit_counter = 0  # Track number of hits
var base_attack_radius = 80.0  # Store the base attack radius
@onready var attack_sound = preload("res://hit.ogg")

func _ready():
	screen_size = get_viewport_rect().size
	hide()
	
	# Create health bar
	var health_bar = preload("res://health_bar.gd").new()
	add_child(health_bar)
	health_bar.name = "HealthBar"
	
	# Create exp bar
	var exp_bar = preload("res://exp_bar.gd").new()
	add_child(exp_bar)
	exp_bar.name = "ExpBar"
	update_exp_bar()
	
	# Create attack area if it doesn't exist
	if not has_node("AttackArea"):
		var attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		add_child(attack_area)
		
		var collision_shape = CollisionShape2D.new()
		collision_shape.name = "CollisionShape2D"
		var shape = ConvexPolygonShape2D.new()
		# Create cone shape points
		var points = create_cone_points(attack_radius, attack_angle)
		shape.points = points
		collision_shape.shape = shape
		attack_area.add_child(collision_shape)
	else:
		# If it exists, update the shape
		var shape = ConvexPolygonShape2D.new()
		shape.points = create_cone_points(attack_radius, attack_angle)
		$AttackArea/CollisionShape2D.shape = shape
	
	# Initialize health bar with correct values
	$HealthBar.update_health(health, maxhealth)
	
	# Create audio player for attack sound
	var audio_player = AudioStreamPlayer.new()
	audio_player.name = "AttackSound"
	audio_player.stream = attack_sound
	add_child(audio_player)

func _process(delta):
	var velocity = Vector2.ZERO # The player's movement vector.
	# we can increment player speed here.
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1

	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()

	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

	# Update player facing direction based on mouse position
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	# Update sprite direction based on mouse position
	if abs(direction_to_mouse.x) > abs(direction_to_mouse.y):
		# Horizontal movement animation
		$AnimatedSprite2D.animation = "right"
		$AnimatedSprite2D.flip_h = direction_to_mouse.x < 0
		$AnimatedSprite2D.flip_v = false
		rotation = 0  # Reset rotation
	else:
		# Vertical movement animation
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_v = direction_to_mouse.y > 0
		$AnimatedSprite2D.flip_h = false
		rotation = 0  # Reset rotation

	# Handle attack with left mouse button
	if Input.is_action_just_pressed("attack") and can_attack:
		perform_attack()
		can_attack = false
		await get_tree().create_timer(attack_cooldown).timeout
		can_attack = true

func start(pos):
	position = pos
	rotation = 0
	maxhealth = 100
	health = 100
	current_level = 1
	current_exp = 0
	exp_to_next_level = 125
	can_take_damage = true
	show()
	$CollisionShape2D.disabled = false
	$HealthBar.update_health(health, maxhealth)
	update_exp_bar()

func _on_body_entered(body):
	if body.is_in_group("mobs") and can_take_damage:
		take_damage(4)
		can_take_damage = false
		# Start damage cooldown timer
		await get_tree().create_timer(damage_cooldown).timeout
		can_take_damage = true

func take_damage(amount):
	if is_dead:
		return
		
	health = max(0, health - amount)
	health_changed.emit(health)
	$HealthBar.update_health(health, maxhealth)
	
	# Spawn damage number
	spawn_damage_number(amount)
	
	if health <= 0:
		die()

func perform_attack():
	# Play attack sound
	$AttackSound.play()
	
	# Increment hit counter
	hit_counter += 1
	
	# Every third hit gets bonus range
	var current_radius = attack_radius
	if hit_counter % 3 == 0:
		current_radius += 50.0
	
	# Get mouse position and calculate direction
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Create visual effect with current radius
	var effect = create_attack_effect(current_radius)
	effect.rotation = direction.angle()
	add_child(effect)
	
	# Update attack area rotation and shape for this attack
	$AttackArea.rotation = direction.angle()
	var shape = ConvexPolygonShape2D.new()
	shape.points = create_cone_points(current_radius, attack_angle)
	$AttackArea/CollisionShape2D.shape = shape
	
	# Check for mobs in attack area
	var mobs = $AttackArea.get_overlapping_bodies()
	for mob in mobs:
		if mob.is_in_group("mobs"):
			mob.take_damage(attack_damage)
	
	# Remove effect after animation
	await get_tree().create_timer(0.5).timeout
	effect.queue_free()
	
	# Reset attack area to base radius
	if hit_counter % 3 == 0:
		shape.points = create_cone_points(attack_radius, attack_angle)
		$AttackArea/CollisionShape2D.shape = shape

# Modified to accept radius parameter
func create_attack_effect(current_radius):
	var effect = Node2D.new()
	var sprite = Sprite2D.new()
	var texture = create_cone_texture(current_radius, attack_angle)
	sprite.texture = texture
	sprite.modulate = Color(1, 1, 1, 0.7)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
	
	effect.add_child(sprite)
	return effect

func create_cone_points(radius, angle_degrees):
	var points = PackedVector2Array()
	var angle_rad = deg_to_rad(angle_degrees)
	var num_points = 8  # Increased points for smoother arc
	
	# Add center point
	points.push_back(Vector2.ZERO)
	
	# Create arc points
	for i in range(num_points + 1):
		var t = float(i) / num_points
		var current_angle = -angle_rad/2 + angle_rad * t
		var point = Vector2(
			radius * cos(current_angle),
			radius * sin(current_angle)
		)
		points.push_back(point)
	
	return points

func create_cone_texture(radius, angle_degrees):
	var image = Image.create(radius * 2, radius * 2, false, Image.FORMAT_RGBA8)
	var center = Vector2(radius, radius)
	var angle_rad = deg_to_rad(angle_degrees)
	
	for x in range(image.get_width()):
		for y in range(image.get_height()):
			var point = Vector2(x - radius, y - radius)  # Centered coordinates
			var distance = point.length()
			var angle = point.angle()
			
			if distance <= radius and abs(angle) <= angle_rad/2:
				var alpha = 1.0 - (distance / radius) * 0.5  # Softer fade
				var edge_fade = 1.0 - abs(angle) / (angle_rad/2)  # Fade at edges
				alpha *= edge_fade
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
	
	return ImageTexture.create_from_image(image)

func die():
	is_dead = true
	hide()
	hit.emit()
	$CollisionShape2D.set_deferred("disabled", true)

func heal(amount):
	if is_dead:
		return
		
	health = min(maxhealth, health + amount)  # Don't exceed max health
	health_changed.emit(health)
	$HealthBar.update_health(health, maxhealth)

func _physics_process(_delta):
	if is_dead:
		return
		
	var current_time = Time.get_ticks_msec()
	
	# Check each mob we're in contact with
	for mob in in_contact_with_mobs.keys():
		if !is_instance_valid(mob):
			in_contact_with_mobs.erase(mob)
			continue
			
		var contact_data = in_contact_with_mobs[mob]
		
		# Check if mob is within 8 pixel radius of player center
		var distance = global_position.distance_to(mob.global_position)
		if distance <= 8:  # 8 pixel radius check
			# Initial hit after entering radius
			if !contact_data["initial_hit"] and can_take_damage:
				take_damage(mob.damage)  # Use mob's damage value
				contact_data["initial_hit"] = true
				contact_data["last_damage_time"] = current_time
			
			# DoT damage every interval
			var time_since_last_damage = (current_time - contact_data["last_damage_time"]) / 1000.0
			if time_since_last_damage >= dot_interval and can_take_damage:
				take_damage(dot_damage)
				contact_data["last_damage_time"] = current_time
		else:
			# Reset contact if mob moves outside radius
			contact_data["initial_hit"] = false

func gain_exp(amount):
	current_exp += amount
	while current_exp >= exp_to_next_level:
		level_up()
	update_exp_bar()

func level_up():
	current_exp -= exp_to_next_level
	current_level += 1
	# Increase exp needed for next level by 10%
	exp_to_next_level = int(exp_to_next_level * 1.1)
	# Could add level up effects/bonuses here

func update_exp_bar():
	if has_node("ExpBar"):
		$ExpBar.update_exp(current_exp, exp_to_next_level, current_level)

# Add this new function for damage numbers
func spawn_damage_number(amount):
	var damage_label = Label.new()
	damage_label.text = str(amount)
	damage_label.add_theme_color_override("font_color", Color(1, 0, 0))  # Red color
	damage_label.add_theme_font_size_override("font_size", 32)  # Doubled from 16 to 32
	
	# Position slightly above player
	damage_label.position = Vector2(-20, -20)  # Offset from player center
	add_child(damage_label)
	
	# Create animation
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Move up - doubled from 50 to 100 pixels
	tween.tween_property(damage_label, "position:y", 
		damage_label.position.y - 100, 1.0)  # Move up 100 pixels
	
	# Fade out
	tween.tween_property(damage_label, "modulate:a", 
		0.0, 1.0)  # Fade out over 1 second
	
	# Delete after animation
	await tween.finished
	damage_label.queue_free()
