extends Node2D

var width = 500  # Width of exp bar
var height = 30  # Height of exp bar
var margin_top = 50  # Margin from top of screen
var level_box_size = 50  # Size of the level display box

# For the textures
var rng = RandomNumberGenerator.new()
var noise_texture = NoiseTexture2D.new()
var exp_bar_noise = NoiseTexture2D.new()

func _ready():
	z_index = 100
	setup_noise_textures()
	update_position()

func setup_noise_textures():
	# For level box
	var noise = FastNoiseLite.new()
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.05
	noise_texture.noise = noise
	noise_texture.width = level_box_size
	noise_texture.height = level_box_size
	
	# For exp bar - make it full width to avoid stretching
	var exp_noise = FastNoiseLite.new()
	exp_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	exp_noise.seed = randi()
	exp_noise.frequency = 0.02  # Lower frequency for better wood effect
	exp_bar_noise.noise = exp_noise
	exp_bar_noise.width = width
	exp_bar_noise.height = height

func update_position():
	var screen_size = get_viewport_rect().size
	global_position = Vector2(
		screen_size.x/2 - width/2,
		margin_top
	)

func _draw():
	# Draw base dark wood texture
	var dark_wood = Color(0.2, 0.1, 0.05, 0.9)  # Very dark brown
	draw_texture_rect(
		exp_bar_noise,
		Rect2(0, 0, width, height),
		false,
		dark_wood
	)
	
	# Draw the filled portion
	if exp_to_next > 0:
		var exp_width = (width * current_exp) / exp_to_next
		var progress = float(current_exp) / float(exp_to_next)
		
		# Calculate brighter color based on progress
		var fill_color = Color(
			lerp(0.4, 0.8, progress),  # R: 0.4 to 0.8
			lerp(0.2, 0.4, progress),  # G: 0.2 to 0.4
			lerp(0.1, 0.2, progress),  # B: 0.1 to 0.2
			0.9
		)
		
		# Create a clipped region for the filled portion
		var clip_rect = Rect2(0, 0, exp_width, height)
		draw_texture_rect_region(
			exp_bar_noise,
			clip_rect,
			clip_rect,
			fill_color
		)
	
	# Draw border for exp bar
	var border_color = Color(0.3, 0.15, 0.0)  # Dark brown border
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
