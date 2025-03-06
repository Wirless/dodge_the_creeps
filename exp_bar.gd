extends Node2D

var width = 50  # Default width of exp bar
var height = 4  # Default height of exp bar
var offset = Vector2(0, -30)  # Position above entity

func _ready():
	z_index = 1  # Ensure exp bar appears above other elements

func _draw():
	# Draw background (empty exp bar)
	draw_rect(Rect2(offset.x - width/2, offset.y, width, height), Color(0.2, 0.2, 0.2))
	
	# Draw current exp
	var exp_width = (width * current_exp) / exp_to_next
	if current_exp > 0:
		var exp_color = Color(1, 0.65, 0)  # Orange for exp
		draw_rect(Rect2(offset.x - width/2, offset.y, exp_width, height), exp_color)
	
	# Draw text
	var font = ThemeDB.fallback_font
	var font_size = 12
	var text = "%d/%d (Level %d)" % [current_exp, exp_to_next, current_level]
	var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(
		offset.x - text_size.x/2,  # Center text
		offset.y + height + text_size.y  # Position below bar
	)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

func update_exp(curr_exp, exp_needed, level):
	current_exp = curr_exp
	exp_to_next = exp_needed
	current_level = level
	queue_redraw()  # Redraw the exp bar

var current_exp = 0
var exp_to_next = 125
var current_level = 1
