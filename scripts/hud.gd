extends Control

signal game_restarted

onready var score = $Panel/ScoreAndBestContainer/ScoreContainer/ValueLabel
onready var best = $Panel/ScoreAndBestContainer/BestContainer/ValueLabel
onready var info_panel = $InfoPanel
onready var win_panel = $WinPanel
onready var game_over_panel = $GameOverPanel
onready var info_ok_button = $InfoPanel/OkButton
onready var win_ok_button = $WinPanel/OkButton
onready var game_over_ok_button = $GameOverPanel/OkButton
onready var restart_button = $Panel/ButtonsContainer/RestartButton
onready var pause_button = $Panel/ButtonsContainer/PauseButton
onready var info_button = $Panel/ButtonsContainer/InfoButton
onready var exit_button = $Panel/ButtonsContainer/ExitButton
onready var win_label = $WinPanel/WinLabel
onready var game_over_label = $GameOverPanel/Label
onready var timer = $Timer
onready var timer_label = $Panel/TimerLabel
onready var pause_label = $Panel/PauseLabel

var score_val := 0
var best_val := 0
var time_s := 0
var time_m := 0
var time_h := 0
var won := false

func _ready():
	read_config()
	score.text = str(score_val)
	best.text = str(best_val)
	timer_label.text = get_time_string()
	info_panel.hide()
	win_panel.hide()
	game_over_panel.hide()
	info_ok_button.set_disabled(true)
	win_ok_button.set_disabled(true)
	game_over_ok_button.set_disabled(true)
	if !Game.is_paused():
		timer.start()
		pause_label.hide()

func update_timer():
	time_s += 1
	if time_s == 60:
		time_m += 1
		time_s = 0
	if time_m == 60:
		time_h += 1
		time_m = 0
	timer_label.text = get_time_string()

func reset_timer():
	time_h = 0
	time_m = 0
	time_s = 0
	timer_label.text = get_time_string()
	timer.start()

func get_time_string() -> String:
	return str("%02d:%02d:%02d" %[time_h, time_m, time_s])

func change_score(var s):
	score_val = s
	if score_val > best_val:
		best_val = score_val
	score.text = str(score_val)
	best.text = str(best_val)

func restart_game():
	won = false
	reset_timer()
	pause_label.hide()
	emit_signal("game_restarted")

func _on_RestartButton_pressed():
	restart_game()

func _on_PauseButton_pressed():
	if Game.is_paused():
		continue_game()
	else:
		pause_game()

func pause_game():
	pause_label.show()
	timer.stop()
	Game.pause()

func continue_game():
	pause_label.hide()
	timer.start()
	Game.continue()

func _on_InfoButton_pressed():
	restart_button.set_disabled(true)
	pause_button.set_disabled(true)
	info_button.set_disabled(true)
	info_ok_button.set_disabled(false)
	info_panel.show()
	pause_game()

func _on_InfoPanel_OkButton_pressed():
	restart_button.set_disabled(false)
	pause_button.set_disabled(false)
	info_button.set_disabled(false)
	info_ok_button.set_disabled(true)
	info_panel.hide()

func win_game():
	if won: #preventing duplication
		return
	won = true
	restart_button.set_disabled(true)
	pause_button.set_disabled(true)
	info_button.set_disabled(true)
	win_ok_button.set_disabled(false)
	win_label.text = "Congratulations! You win.\nScore: %s\nTime: %s" \
									   %[str(score_val), get_time_string()]
	win_panel.show()
	pause_game()

func _on_WinPanel_OkButton_pressed():
	restart_button.set_disabled(false)
	pause_button.set_disabled(false)
	info_button.set_disabled(false)
	win_ok_button.set_disabled(true)
	win_panel.hide()

func game_over():
	if !won:
		game_over_label.text = "You lose.\nScore: %s\nTime: %s" \
								%[str(score_val), get_time_string()]
	else:
		game_over_label.text = "Game over.\nScore: %s\nTime: %s" \
								%[str(score_val), get_time_string()]
	restart_button.set_disabled(true)
	pause_button.set_disabled(true)
	info_button.set_disabled(true)
	game_over_ok_button.set_disabled(false)
	game_over_panel.show()
	pause_game()

func _on_GameOverPanel_OkButton_pressed():
	Game.pause()
	restart_button.set_disabled(false)
	pause_button.set_disabled(false)
	info_button.set_disabled(false)
	game_over_ok_button.set_disabled(true)
	game_over_panel.hide()
	pause_label.hide()
	restart_game()

func quit():
	get_tree().quit()

func _exit_tree():
	save_config_all()

func save_config_all():
	var config = ConfigFile.new()
	config.set_value("SCORE","score_val", score_val)
	config.set_value("SCORE", "best_val", best_val)
	config.set_value("TIME", "time_h", time_h)
	config.set_value("TIME", "time_m", time_m)
	config.set_value("TIME", "time_s", time_s)
	config.set_value("WON", "won", won)
	config.set_value("PAUSE", "paused", Game.is_paused())
	var values_matrix = get_node("../Tiles").get_values_matrix()
	for i in Game.MATRIX_SIZE:
		for j in Game.MATRIX_SIZE:
			config.set_value("TILES", str("tile-%d-%d" %[i, j]) \
									, values_matrix[i][j])
	config.save(Game.CONFIG_FILE_PATH)

func read_config():
	var config = ConfigFile.new()
	var err = config.load(Game.CONFIG_FILE_PATH)
	if err != OK || !Game.is_correct_config_file():
		return
	score_val = config.get_value("SCORE", "score_val", 0)
	best_val = config.get_value("SCORE", "best_val", 0)
	time_h = config.get_value("TIME", "time_h", 0)
	time_m = config.get_value("TIME", "time_m", 0)
	time_s = config.get_value("TIME", "time_s", 0)
	won  = config.get_value("WON", "won", false)
