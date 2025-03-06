extends Area2D

var speed = 400
var pickup_radius = 30
var is_being_collected = false
var target_player = null
var start_scale = Vector2(0.5, 0.5)

func _ready():
	z_index = -1  # Below other sprites
	scale = start_scale
	
	# Create sprite if it doesn't exist
	if !has_node("Sprite2D"):
		var sprite = Sprite2D.new()
		sprite.texture = preload("res://coin.png")
		sprite.name = "Sprite2D"
		add_child(sprite)
	
	# Create collision shape if it doesn't exist
	if !has_node("CollisionShape2D"):
		var collision_shape = CollisionShape2D.new()
		var circle_shape = CircleShape2D.new()
		circle_shape.radius = pickup_radius
		collision_shape.shape = circle_shape
		collision_shape.name = "CollisionShape2D"
		add_child(collision_shape)
	
	# Connect signal if not already connected
	if !is_connected("body_entered", _on_body_entered):
		connect("body_entered", _on_body_entered)

func _physics_process(delta):
	if is_being_collected and target_player:
		var direction = target_player.global_position - global_position
		if direction.length() < 5:
			queue_free()
		else:
			global_position += direction.normalized() * speed * delta
			var distance_factor = direction.length() / pickup_radius
			scale = start_scale * distance_factor
			modulate.a = distance_factor

func _on_body_entered(body):
	if body.is_in_group("player") and !is_being_collected:
		is_being_collected = true
		target_player = body
