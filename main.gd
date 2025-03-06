extends Node

@export var mob_scene: PackedScene
var score

func game_over():
	$ScoreTimer.stop()
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()

func new_game():
	get_tree().call_group(&"mobs", &"queue_free")
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	$Music.play()


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
		if existing_mob.position.distance_to(spawn_position) < 30:  # Increased spawn separation
			can_spawn = false
			break
	
	if can_spawn:
		mob.position = spawn_position
		
		# Set initial velocity towards player, considering other mobs
		var player = get_node("Player")
		if player:
			var direction = (player.position - spawn_position).normalized()
			mob.linear_velocity = direction * mob.chase_speed
		
		# Spawn the mob
		add_child(mob)
	else:
		mob.queue_free()

func _on_ScoreTimer_timeout():
	score += 1
	$HUD.update_score(score)


func _on_StartTimer_timeout():
	$MobTimer.start()
	$ScoreTimer.start()
