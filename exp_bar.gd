extends Node2D

var width = 500  # Width of exp bar
var height = 30  # Height of exp bar
var margin_top = 50  # Margin from top of screen
var level_box_size = 50  # Size of the level display box
var scroll_offset = 0.0  # For sliding animation
var base_scroll_speed = 30.0  # Base speed when empty
var max_scroll_speed = 120.0  # Maximum speed when full

# For the textures
var rng = RandomNumberGenerator.new()
var noise_texture = NoiseTexture2D.new()
var exp_bar_noise = NoiseTexture2D.new()

func _ready():
	z_index = 100
	setup_noise_textures()
	update_position()

func _process(delta):
	# Calculate current scroll speed based on exp bar fill percentage
	var fill_percent = float(current_exp) / float(exp_to_next) if exp_to_next > 0 else 0
	var current_scroll_speed = lerp(base_scroll_speed, max_scroll_speed, fill_percent)
	
	# Update scroll offset with dynamic speed
	scroll_offset += delta * current_scroll_speed
	if scroll_offset >= width:
		scroll_offset = 0
	queue_redraw()

func setup_noise_textures():
	# For level box
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.05
	noise_texture.noise = noise
	noise_texture.width = level_box_size
	noise_texture.height = level_box_size
	
	# For exp bar - make it twice the width for seamless scrolling
	var exp_noise = FastNoiseLite.new()
	exp_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	exp_noise.seed = randi()
	exp_noise.frequency = 0.02
	exp_bar_noise.noise = exp_noise
	exp_bar_noise.width = width * 2  # Double width for scrolling
	exp_bar_noise.height = height

func update_position():
	var screen_size = get_viewport_rect().size
	global_position = Vector2(
		screen_size.x/2 - width/2,
		margin_top
	)

func _draw():
	# Draw base dark wood texture
	var dark_wood = Color(0.2, 0.1, 0.05, 0.9)
	
	# Calculate fill percentage for color and speed
	var fill_percent = float(current_exp) / float(exp_to_next) if exp_to_next > 0 else 0
	
	# Draw scrolling background (dark)
	var source_rect = Rect2(scroll_offset, 0, width, height)
	draw_texture_rect_region(
		exp_bar_noise,
		Rect2(0, 0, width, height),
		source_rect,
		dark_wood
	)
	
	# Draw the filled portion with scrolling
	if exp_to_next > 0:
		var exp_width = (width * current_exp) / exp_to_next
		
		# Calculate brighter color based on progress
		var fill_color = Color(
			lerp(0.4, 0.8, fill_percent),
			lerp(0.2, 0.4, fill_percent),
			lerp(0.1, 0.2, fill_percent),
			0.9
		)
		
		# Draw scrolling filled portion
		var fill_source_rect = Rect2(scroll_offset, 0, exp_width, height)
		draw_texture_rect_region(
			exp_bar_noise,
			Rect2(0, 0, exp_width, height),
			fill_source_rect,
			fill_color
		)
		
		# Optional: Add a glow effect when near full
		if fill_percent > 0.8:
			var glow_color = fill_color
	
	# Draw border for exp bar
	var border_color = Color(0.3, 0.15, 0.0)
	draw_rect(Rect2(0, 0, width, height), border_color, false, 2.0)
	
	# Draw level box below the exp bar
	var box_pos = Vector2(
		width/2 - level_box_size/2,
		height
	)
	
	# Draw wood texture for level box
	draw_texture_rect(
		noise_texture,
		Rect2(box_pos, Vector2(level_box_size, level_box_size)),
		false,
		Color(0.82, 0.41, 0.12)  # Medium brown
	)
	
	# Draw border for level box
	draw_rect(
		Rect2(box_pos, Vector2(level_box_size, level_box_size)),
		border_color,
		false,
		3.0
	)
	
	# Draw level number
	var font = ThemeDB.fallback_font
	var font_size = 32
	var level_text = str(current_level)
	var text_size = font.get_string_size(level_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos = Vector2(
		box_pos.x + level_box_size/2 - text_size.x/2,
		box_pos.y + level_box_size/2 + text_size.y/4
	)
	
	# Draw text shadow for level
	draw_string(font, text_pos + Vector2(2, 2), level_text, 
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.5))
	draw_string(font, text_pos, level_text, 
		HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Draw exp text
	var exp_font_size = 16
	var exp_text = "%d/%d" % [current_exp, exp_to_next]
	var exp_text_size = font.get_string_size(exp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, exp_font_size)
	var exp_text_pos = Vector2(
		width/2 - exp_text_size.x/2,
		height/2 + exp_text_size.y/4
	)
	
	# Draw exp text with shadow
	draw_string(font, exp_text_pos + Vector2(1, 1), exp_text, 
		HORIZONTAL_ALIGNMENT_LEFT, -1, exp_font_size, Color(0, 0, 0, 0.5))
	draw_string(font, exp_text_pos, exp_text, 
		HORIZONTAL_ALIGNMENT_LEFT, -1, exp_font_size, Color.WHITE)

func update_exp(curr_exp, exp_needed, level):
	current_exp = curr_exp
	exp_to_next = exp_needed
	current_level = level
	queue_redraw()

var current_exp = 0
var exp_to_next = 125
var current_level = 1
