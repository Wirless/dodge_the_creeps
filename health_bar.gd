extends Node2D

@export var width = 50
@export var height = 5
@export var offset = Vector2(0, -30) # Offset from parent node

var max_health = 100
var current_health = 100

func _ready():
	# Make sure we're drawn on top
	z_index = 100

func _draw():
	# Draw background (gray)
	draw_rect(Rect2(-width/2, -height/2, width, height), Color(0.2, 0.2, 0.2))
	
	# Calculate health percentage and color
	var health_percent = current_health / max_health
	var color = Color.from_hsv(health_percent * 0.3, 1.0, 1.0) # Green (0.3) to Red (0.0)
	
	# Draw health bar
	draw_rect(Rect2(-width/2, -height/2, width * health_percent, height), color)

func update_health(current, maximum):
	current_health = current
	max_health = maximum
	queue_redraw()

func _process(_delta):
	# Update position to follow parent
	if get_parent():
		global_position = get_parent().global_position + offset
