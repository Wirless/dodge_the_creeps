extends CanvasLayer

signal start_game

var coins = 0

func _ready():
	add_to_group("hud")
	# Create coin sack display
	update_coin_display()

func _draw_coin_sack():
	var sack = $CoinSack
	if !sack:
		sack = Node2D.new()
		sack.name = "CoinSack"
		add_child(sack)
		
		# Position in bottom right
		var screen_size = get_viewport().get_visible_rect().size
		sack.position = Vector2(screen_size.x - 100, screen_size.y - 100)

func update_coin_display():
	# Create or update the coin counter
	if !has_node("CoinCounter"):
		var label = Label.new()
		label.name = "CoinCounter"
		label.text = str(coins)
		# Position near bottom right
		var screen_size = get_viewport().get_visible_rect().size
		label.position = Vector2(screen_size.x - 80, screen_size.y - 90)
		add_child(label)
	else:
		$CoinCounter.text = str(coins)

func add_coins(amount):
	coins += amount
	update_coin_display()

func show_message(text):
	$MessageLabel.text = text
	$MessageLabel.show()
	$MessageTimer.start()


func show_game_over():
	show_message("Game Over")
	await $MessageTimer.timeout
	$MessageLabel.text = "Dodge the\nCreeps"
	$MessageLabel.show()
	await get_tree().create_timer(1).timeout
	$StartButton.show()


func update_score(score):
	$ScoreLabel.text = str(score)


func update_health(new_health):
	$HealthLabel.text = "Health: %d" % new_health


func _on_StartButton_pressed():
	$StartButton.hide()
	start_game.emit()


func _on_MessageTimer_timeout():
	$MessageLabel.hide()
