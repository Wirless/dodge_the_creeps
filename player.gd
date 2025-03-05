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

func _ready():
	screen_size = get_viewport_rect().size
	hide()
	
	# Create health bar
	var health_bar = preload("res://health_bar.gd").new()
	add_child(health_bar)
	health_bar.name = "HealthBar"
	
	# Create attack area if it doesn't exist
	if not has_node("AttackArea"):
		var attack_area = Area2D.new()
		attack_area.name = "AttackArea"
		add_child(attack_area)
		
		var collision_shape = CollisionShape2D.new()
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
	maxhealth = 100 # reset too
	health = 100 # Reset health when starting new game
	can_take_damage = true
	show()
	$CollisionShape2D.disabled = false
	$HealthBar.update_health(health, 100)

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
		
	health -= amount
	health_changed.emit(health)
	$HealthBar.update_health(health, 100)
	
	if health <= 0:
		die()

func perform_attack():
	# Get mouse position and calculate direction
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Create visual effect
	var effect = create_attack_effect()
	effect.rotation = direction.angle()  # Rotate effect to face mouse
	add_child(effect)
	
	# Update attack area rotation to face mouse cursor
	$AttackArea.rotation = direction.angle()
	
	# Check for mobs in attack area
	var mobs = $AttackArea.get_overlapping_bodies()
	for mob in mobs:
		if mob.is_in_group("mobs"):
			mob.take_damage(attack_damage)
	
	# Remove effect after animation
	await get_tree().create_timer(0.5).timeout
	effect.queue_free()

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

func create_attack_effect():
	var effect = Node2D.new()
	
	# Create visual mask
	var sprite = Sprite2D.new()
	var texture = create_cone_texture(attack_radius, attack_angle)
	sprite.texture = texture
	sprite.modulate = Color(1, 1, 1, 0.7)  # Slightly transparent white
	
	# Add a smooth fade out and slight scaling effect
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
	
	effect.add_child(sprite)
	return effect

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
