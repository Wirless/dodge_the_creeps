extends Node

@export var mob_scene: PackedScene
const Coin = preload("res://coin.tscn")
var score
var coin_spawn_time_min = 2.0  # Minimum time between coin spawns
var coin_spawn_time_max = 5.0  # Maximum time between coin spawns

func _ready():
	# Create exp bar at game start
	var exp_bar = preload("res://exp_bar.gd").new()
	add_child(exp_bar)
	exp_bar.name = "ExpBar"
	
	# Create coin spawn timer
	var coin_timer = Timer.new()
	coin_timer.name = "CoinTimer"
	coin_timer.wait_time = randf_range(coin_spawn_time_min, coin_spawn_time_max)
	coin_timer.one_shot = false  # Make it repeat
	coin_timer.autostart = true  # Start automatically
	add_child(coin_timer)
	coin_timer.timeout.connect(spawn_random_coin)
	coin_timer.start()  # Start the timer

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$CoinTimer.stop()  # Stop coin spawning on game over
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	get_tree().call_group(&"mobs", &"queue_free")
	get_tree().call_group(&"coins", &"queue_free")  # Clear existing coins
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Music.play()
	
	# Start coin spawning
	if has_node("CoinTimer"):
		$CoinTimer.start()
	
	# Make sure ExpBar exists and is updated
	if !has_node("ExpBar"):
		var exp_bar = preload("res://exp_bar.gd").new()
		add_child(exp_bar)
		exp_bar.name = "ExpBar"

func spawn_random_coin():
	var coin = Coin.instantiate()
	
	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Generate random position within viewport
	var random_x = randf_range(50, viewport_size.x - 50)
	var random_y = randf_range(50, viewport_size.y - 50)
	
	# Set position and add to scene
	coin.global_position = Vector2(random_x, random_y)
	add_child(coin)
	
	# Set next spawn time
	if has_node("CoinTimer"):
		$CoinTimer.wait_time = randf_range(coin_spawn_time_min, coin_spawn_time_max)
		$CoinTimer.start()

func _on_MobTimer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on Path2D.
	var mob_spawn_location = get_node("MobPath/MobSpawnLocation")
	mob_spawn_location.progress = randi()

	# Set the mob's position to a random location.
	var spawn_position = mob_spawn_location.position
	
	# Check if spawn position is too close to other mobs
	var can_spawn = true
	for existing_mob in get_tree().get_nodes_in_group("mobs"):
		if existing_mob.position.distance_to(spawn_position) < 50:  # Increased to 50 pixels
			can_spawn = false
			break
	
	if can_spawn:
		mob.position = spawn_position
		add_child(mob)
	else:
		mob.queue_free()

func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)

func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
