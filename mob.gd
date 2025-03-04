extends RigidBody2D

var health = 50.0
var max_health = 50.0
var is_dead = false

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

func take_damage(amount):
	if is_dead:
		return
		
	health -= amount
	$HealthBar.update_health(health, max_health)
	
	if health <= 0:
		die()

func die():
	is_dead = true
	# Add death animation or effect here
	hide()
	queue_free()

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
