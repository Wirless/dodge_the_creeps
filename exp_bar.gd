extends Node2D

var width = 500  # Width of exp bar
var height = 30  # Height of exp bar
var margin_bottom = 50  # Margin from bottom of screen

func _ready():
	z_index = 100  # Ensure it's drawn on top
	update_position()

func update_position():
	# Get screen size and set position
	var screen_size = get_viewport_rect().size
	# Position at bottom center of screen
	global_position = Vector2(
		screen_size.x/2 - width/2,  # Center horizontally
		screen_size.y - margin_bottom - height  # Position from bottom
	)

func _draw():
	# Draw background (empty exp bar)
	draw_rect(Rect2(0, 0, width, height), Color(0.2, 0.2, 0.2, 0.8))
	
	# Draw current exp
	if exp_to_next > 0:
		var exp_width = (width * current_exp) / exp_to_next
		var exp_color = Color(1, 0.65, 0, 0.8)  # Orange color
		draw_rect(Rect2(0, 0, exp_width, height), exp_color)
	
	# Draw border
	var border_color = Color(0.3, 0.3, 0.3, 1)
	draw_rect(Rect2(0, 0, width, height), border_color, false, 2.0)
	
	# Draw text
	var font = ThemeDB.fallback_font
	var font_size = 16
	var text = "%d/%d (Level %d)" % [current_exp, exp_to_next, current_level]
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(
		width/2 - text_size.x/2,
		height/2 + text_size.y/4
	)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func update_exp(curr_exp, exp_needed, level):
	current_exp = curr_exp
	exp_to_next = exp_needed
	current_level = level
	queue_redraw()

var current_exp = 0
var exp_to_next = 125
var current_level = 1
