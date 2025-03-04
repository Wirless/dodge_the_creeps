extends Node2D

@export var chunk_size = 512
@export var noise_scale = 50.0
@export var noise_octaves = 4
@export var noise_persistence = 0.5
@export var noise_lacunarity = 2.0
@export var noise_base = 0.5

var noise = FastNoiseLite.new()
var loaded_chunks = {}
var player_chunk = Vector2i.ZERO

func _ready():
	# Setup noise generator
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 1.0 / noise_scale
	noise.fractal_octaves = noise_octaves
	noise.fractal_lacunarity = noise_lacunarity
	noise.fractal_gain = noise_persistence
	noise.fractal_weighted_strength = noise_base
	
	# Start with initial chunk
	generate_chunk(Vector2i.ZERO)

func _process(_delta):
	var player = get_node("/root/Main/Player")
	if player:
		var new_chunk = Vector2i(
			floor(player.position.x / chunk_size),
			floor(player.position.y / chunk_size)
		)
		
		if new_chunk != player_chunk:
			player_chunk = new_chunk
			update_chunks()

func update_chunks():
	# Generate chunks around player
	for x in range(player_chunk.x - 1, player_chunk.x + 2):
		for y in range(player_chunk.y - 1, player_chunk.y + 2):
			var chunk_pos = Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				generate_chunk(chunk_pos)
	
	# Remove distant chunks
	var chunks_to_remove = []
	for chunk_pos in loaded_chunks:
		if chunk_pos.distance_to(player_chunk) > 2:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		remove_chunk(chunk_pos)

func generate_chunk(chunk_pos: Vector2i):
	var chunk = Node2D.new()
	chunk.name = "Chunk_%d_%d" % [chunk_pos.x, chunk_pos.y]
	add_child(chunk)
	
	# Generate terrain
	var tilemap = TileMap.new()
	chunk.add_child(tilemap)
	
	# Create tileset from texture
	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()
	source.texture = preload("res://sprite_37.png") # Replace with your texture path
	source.texture_region_size = Vector2i(32, 32) # Adjust based on your texture
	
	tileset.add_source(source)
	tilemap.tile_set = tileset
	
	# Generate terrain using noise
	for x in range(chunk_size):
		for y in range(chunk_size):
			var world_x = chunk_pos.x * chunk_size + x
			var world_y = chunk_pos.y * chunk_size + y
			
			var noise_value = noise.get_noise_2d(world_x, world_y)
			
			# Convert noise to tile type
			var tile_type = get_tile_type(noise_value)
			if tile_type != -1:
				tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(tile_type, 0))
	
	loaded_chunks[chunk_pos] = chunk

func get_tile_type(noise_value: float) -> int:
	if noise_value < -0.2:
		return 0  # Deep water
	elif noise_value < 0.0:
		return 1  # Water
	elif noise_value < 0.2:
		return 2  # Sand
	elif noise_value < 0.4:
		return 3  # Grass
	elif noise_value < 0.6:
		return 4  # Forest
	elif noise_value < 0.8:
		return 5  # Mountain
	else:
		return 6  # Snow

func remove_chunk(chunk_pos: Vector2i):
	if loaded_chunks.has(chunk_pos):
		loaded_chunks[chunk_pos].queue_free()
		loaded_chunks.erase(chunk_pos)