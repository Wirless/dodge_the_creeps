extends Node2D

var width = 50  # Default width of health bar
var height = 4  # Default height of health bar
var offset = Vector2(0, -30)  # Position above entity

func _ready():
	z_index = 1  # Ensure health bar appears above other elements

func _draw():
	# Draw background (empty health bar)
	draw_rect(Rect2(offset.x - width/2, offset.y, width, height), Color(0.2, 0.2, 0.2))
	
	# Draw current health - calculate proper width based on percentage
	var health_percentage = float(health) / float(max_health)
	var health_width = width * health_percentage
	
	if health > 0:
		var health_color = Color(0, 1, 0)  # Green for health
		draw_rect(Rect2(offset.x - width/2, offset.y, health_width, height), health_color)

func update_health(current_health, maximum_health):
	health = current_health
	max_health = maximum_health
	queue_redraw()  # Redraw the health bar

var health = 100
var max_health = 100

func _process(_delta):
	# Update position to follow parent
	if get_parent():
		global_position = get_parent().global_position + offset
