extends Control

signal game_restarted
signal game_paused

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
var paused := false

func _ready():
	score.text = str(score_val)
	best.text = str(best_val)
	info_panel.hide()
	win_panel.hide()
	game_over_panel.hide()
	info_ok_button.set_disabled(true)
	win_ok_button.set_disabled(true)
	game_over_ok_button.set_disabled(true)
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
	timer_label.text = time_string()

func reset_timer():
	time_h = 0
	time_m = 0
	time_s = 0
	timer_label.text = time_string()
	timer.start()

func time_string() -> String:
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
	emit_signal("game_restarted")

func _on_RestartButton_pressed():
	restart_game()

func _on_PauseButton_pressed():
	if paused:
		continue_game()
	else:
		pause_game()
		
func pause_game():
	paused = true
	restart_button.set_disabled(true)
	pause_label.show()
	timer.stop()
	emit_signal("game_paused", true)

func continue_game():
	paused = false
	restart_button.set_disabled(false)
	pause_label.hide()
	timer.start()
	emit_signal("game_paused", false)

func _on_InfoButton_pressed():
	restart_button.set_disabled(true)
	pause_button.set_disabled(true)
	info_button.set_disabled(true)
	info_ok_button.set_disabled(false)
	info_panel.show()
	emit_signal("game_paused", true)

func _on_InfoPanel_OkButton_pressed():
	restart_button.set_disabled(false)
	pause_button.set_disabled(false)
	info_button.set_disabled(false)
	info_ok_button.set_disabled(true)
	info_panel.hide()
	emit_signal("game_paused", false)

func win_game():
	if won: #preventing duplication
		return
	won = true
	restart_button.set_disabled(true)
	pause_button.set_disabled(true)
	info_button.set_disabled(true)
	win_ok_button.set_disabled(false)
	win_label.text = "Congratulations! You win.\nScore: %s\nTime: %s" \
									   %[str(score_val), time_string()]
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
								%[str(score_val), time_string()]
	else:
		game_over_label.text = "Game over.\nScore: %s\nTime: %s" \
								%[str(score_val), time_string()]
	restart_button.set_disabled(true)
	pause_button.set_disabled(true)
	info_button.set_disabled(true)
	game_over_ok_button.set_disabled(false)
	game_over_panel.show()
	pause_game()

func _on_GameOverPanel_OkButton_pressed():
	paused = false
	restart_button.set_disabled(false)
	pause_button.set_disabled(false)
	info_button.set_disabled(false)
	game_over_ok_button.set_disabled(true)
	game_over_panel.hide()
	pause_label.hide()
	restart_game()

func quit():
	get_tree().quit()
