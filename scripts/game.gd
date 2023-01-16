extends Node

const CONFIG_FILE_PATH = "user://config_2048.cfg"
const MAX_VAL = 131072
const GOAL_SCORE = 2048
const MATRIX_SIZE = 4
var paused := false

func _ready():
	randomize()
	read_config()
	
func pause():
	paused = true

func continue():
	paused = false

func is_paused() -> bool:
	return paused

func read_config():
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK || !Game.is_correct_config_file():
		return
	paused = config.get_value("PAUSE", "paused", false)

func is_correct_config_file() -> bool:
	var config = ConfigFile.new()
	var err = config.load(CONFIG_FILE_PATH)
	if err != OK:
		return false
	if !check_score(config) || !check_time(config) || !check_condition(config) \
							|| !check_tiles(config):
		return false
	return true

func check_score(var config) -> bool:
	if !config.has_section_key("SCORE","score_val"):
		return false
	if !config.has_section_key("SCORE", "best_val"):
		return false
	var score_val = config.get_value("SCORE", "score_val")
	var best_val = config.get_value("SCORE", "best_val")
	if !(score_val is int) || !(best_val is int):
		return false
	if score_val < 0 || best_val < 0:
		return false
	return true

func check_time(var config) -> bool:
	if !config.has_section_key("TIME", "time_h"):
		return false
	if !config.has_section_key("TIME", "time_m"):
		return false
	if !config.has_section_key("TIME", "time_s"):
		return false
	var time_h = config.get_value("TIME", "time_h")
	var time_m = config.get_value("TIME", "time_m")
	var time_s = config.get_value("TIME", "time_s")
	if !(time_h is int) || !(time_m is int) || !(time_s is int):
		return false
	return true

func check_condition(var config) -> bool:
	if !config.has_section_key("WON", "won"):
		return false
	var won  = config.get_value("WON", "won")
	if !(won is bool):
		return false
	if !config.has_section_key("PAUSE", "paused"):
		return false
	var paused_loc = config.get_value("PAUSE", "paused")
	if !(paused_loc is bool):
		return false
	return true
	
func check_tiles(var config) -> bool:
	for i in Game.MATRIX_SIZE:
		for j in Game.MATRIX_SIZE:
			if !config.has_section_key("TILES", str("tile-%d-%d" %[i, j])):
				return false
	var m = []
	for i in Game.MATRIX_SIZE:
		m.append(Array())
		for j in Game.MATRIX_SIZE:
			var val = config.get_value("TILES", str("tile-%d-%d" %[i, j]))
			if val == null:
				return false
			m[i].append(val)
	var sum = 0
	for i in Game.MATRIX_SIZE:
		for j in Game.MATRIX_SIZE:
			var val = m[i][j]
			if !(val is int) || val < 0 || val % 2 != 0 || val > MAX_VAL:
				return false
			sum += val
	if sum <= 0:
		return false
	return true
