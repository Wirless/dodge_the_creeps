extends Node2D

var width = 200
var height = 20
var offset = Vector2(0, 30)  # Position below health bar

func _ready():
	z_index = 1

func _draw():
	# Draw background (empty exp bar)
	draw_rect(Rect2(-width/2, 0, width, height), Color(0.2, 0.2, 0.2, 0.8))
	
	# Draw current exp
	if exp_to_next > 0:
		var exp_width = (width * current_exp) / exp_to_next
		draw_rect(Rect2(-width/2, 0, exp_width, height), Color(1, 0.65, 0, 0.8))  # Orange color
	
	# Draw text
	var font = ThemeDB.fallback_font
	var font_size = 14
	var text = "%d/%d (Level %d)" % [current_exp, exp_to_next, current_level]
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(
		-text_size.x/2,  # Center text
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
