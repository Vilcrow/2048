extends TextureRect

signal score_changed
signal game_won
signal game_over

const SIZE = 4
const GOAL_SCORE = 2048
enum direction { up, down, left, right }
const DOUBLING_MARK = 1 #added to value of tile when doubling for marking
var tiles_matrix = []
var values_matrix = []
var score := 0
var paused := false
#for touch control
const SWIPE_SPEED = 30
var ignore_swipe := false
var swipe_dir = null

func _ready():
	randomize()
	connect_signals()
	for i in SIZE:
		tiles_matrix.append(Array())
		for j in SIZE:
			tiles_matrix[i].append(get_node("Tile_" + str(i) + "-" + str(j)))
	values_matrix = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	new_tile()
	
func _physics_process(_delta):
	if paused:
		pass
	elif !is_moving_possible():
		game_over()
	elif Input.is_action_just_pressed("move_up") || swipe_dir == direction.up:
		move_tiles(direction.up)
	elif Input.is_action_just_pressed("move_down") || swipe_dir == direction.down:
		move_tiles(direction.down)
	elif Input.is_action_just_pressed("move_left") || swipe_dir == direction.left:
		move_tiles(direction.left)
	elif Input.is_action_just_pressed("move_right") || swipe_dir == direction.right:
		move_tiles(direction.right)

#for touch control
func _input(event):
	if ignore_swipe:
		if event is InputEventScreenTouch:
			if !event.pressed: #touch released
				ignore_swipe = false
		swipe_dir = null
	elif event is InputEventScreenDrag:
		if !swipe_dir:
			if event.relative.y < -SWIPE_SPEED:
				swipe_dir = direction.up
				ignore_swipe = true
			elif event.relative.y > SWIPE_SPEED:
				swipe_dir = direction.down
				ignore_swipe = true
			elif event.relative.x < -SWIPE_SPEED:
				swipe_dir = direction.left
				ignore_swipe = true
			elif event.relative.x > SWIPE_SPEED:
				swipe_dir = direction.right
				ignore_swipe = true

func connect_signals():
	var err = connect("score_changed", get_node("../HUD"), "change_score")
	if err:
		print("Error: %d. Signal connection failed." % err)
	err = get_node("../HUD").connect("game_restarted", self, "restart_game")
	if err:
		print("Error: %d. Signal connection failed." % err)
	err = get_node("../HUD").connect("game_paused", self, "set_paused")
	if err:
		print("Error: %d. Signal connection failed." % err)
	err = connect("game_won", get_node("../HUD"), "win_game")
	if err:
		print("Error: %d. Signal connection failed." % err)
	err = connect("game_over", get_node("../HUD"), "game_over")
	if err:
		print("Error: %d. Signal connection failed." % err)

func move_tiles(var dir):
	var old_val = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	copy_matrix(old_val, values_matrix)
	for i in SIZE:
		shift_values(dir, i)
	if !is_same_matrices(old_val, values_matrix):
		update_tiles_matrix()
		new_tile()

func shift_values(var dir, var num): # num is number of row or col
	if is_line_empty(dir, num):
		return
	var tmp = get_line(dir, num)
	pack_line(tmp)
	var last = last_not_empty(tmp)
	summarize_tiles(tmp, last)
	rewrite_line(dir, num, tmp)

#extract array of tiles by direction and number
func get_line(var dir, var num):
	var line = []
	match dir:
		direction.up:
			for i in SIZE:
				line.append(values_matrix[i][num])
		direction.down:
			for i in range(SIZE-1, -1, -1):
				line.append(values_matrix[i][num])
		direction.left:
			for i in SIZE:
				line.append(values_matrix[num][i])
		direction.right:
			for i in range(SIZE-1, -1, -1):
				line.append(values_matrix[num][i])
	return line

func rewrite_line(var dir, var num, var new_line):
	match dir:
		direction.up:
			for i in SIZE:
				values_matrix[i][num] = new_line[i]
		direction.down:
			var j = 0
			for i in range(SIZE-1, -1, -1):
				values_matrix[i][num] = new_line[j]
				j += 1
		direction.left:
			for i in SIZE:
				values_matrix[num][i] = new_line[i]
		direction.right:
			var j = 0
			for i in range(SIZE-1, -1, -1):
				values_matrix[num][i] = new_line[j]
				j += 1

#shift non-zero values to the beginning of array
func pack_line(var line):
	for i in line.size()-1:
		if line[i] == 0 && i < line.size()-1:
			for j in range(i+1, line.size()):
				if line[j]:
					line[i] = line[j]
					line[j] = 0
					break

#return index of tile in array with value != null
func last_not_empty(var arr) -> int:
	var last := -2
	for i in arr.size():
		if arr[i] == 0:
			last = i - 1
			break
	if last == -2: #don't have tile with value
		last = arr.size() - 1
	elif last == -1: #all tile with value
		last = 0
	return last

#summarize neighboring tiles with same value
func summarize_tiles(var arr, var last):
	for i in last:
		var next = i + 1
		if next > last:
			break
		if arr[i] && arr[i] == arr[next]:
			arr[i] = arr[i] * 2 + DOUBLING_MARK
			set_score(score+arr[i]-DOUBLING_MARK)
			arr[next] = 0
	pack_line(arr)

#update values_matrix
func update_val_matrix():
	for i in SIZE:
		for j in SIZE:
			values_matrix[i][j] = tiles_matrix[i][j].get_value()

func update_tiles_matrix():
	for i in SIZE:
		for j in SIZE:
			if values_matrix[i][j] % 2 == DOUBLING_MARK:
				tiles_matrix[i][j].play_doubling_animation()
				values_matrix[i][j] -= DOUBLING_MARK
			tiles_matrix[i][j].set_value(values_matrix[i][j])
			if values_matrix[i][j] == GOAL_SCORE:
				emit_signal("game_won")

func new_tile():
	if !have_empty_tile():
			return
	var value = 4 if (randi() % 10) == 9 else 2
	var tile = null
	while !tile || tile.get_value():
		tile = tiles_matrix[randi() % SIZE][randi() % SIZE]
	tile.set_value(value)
	update_val_matrix()
	tile.play_appearance_animation()
	
func have_empty_tile() -> bool:
	for i in SIZE:
		for j in SIZE:
			if values_matrix[i][j] == 0:
				return true
	return false

func is_line_empty(var dir, var num) -> bool:
	if dir == direction.up || dir == direction.down:
		for i in SIZE:
			if values_matrix[i][num]:
				return false
	else:
		for i in SIZE:
			if values_matrix[num][i]:
				return false
	return true

func is_moving_possible() -> bool:
	if have_empty_tile():
		return true
	for i in SIZE:
		for j in SIZE:
			if i == 0:
				#top left corner
				if j == 0:
					if values_matrix[i][j] == values_matrix[i+1][j] || \
					   values_matrix[i][j] == values_matrix[i][j+1]:
						return true
				#top right corner
				elif j == SIZE - 1:
					if values_matrix[i][j] == values_matrix[i][j-1] || \
					   values_matrix[i][j] == values_matrix[i+1][j]:
						return true
				#top middle
				else:
					if values_matrix[i][j] == values_matrix[i][j-1] || \
					   values_matrix[i][j] == values_matrix[i][j+1] || \
					   values_matrix[i][j] == values_matrix[i+1][j]:
						return true
			elif i == SIZE - 1:
				#down left corner
				if j == 0:
					if values_matrix[i][j] == values_matrix[i-1][j] || \
					   values_matrix[i][j] == values_matrix[i][j+1]:
						return true
				#down right corner
				elif j == SIZE - 1:
					if values_matrix[i][j] == values_matrix[i-1][j] || \
					   values_matrix[i][j] == values_matrix[i][j-1]:
						return true
				#down middle
				else:
					if values_matrix[i][j] == values_matrix[i-1][j] || \
					   values_matrix[i][j] == values_matrix[i][j-1] || \
					   values_matrix[i][j] == values_matrix[i][j+1]:
						return true
			#left middle
			elif j == 0:
				if values_matrix[i][j] == values_matrix[i-1][j] || \
				   values_matrix[i][j] == values_matrix[i+1][j] || \
				   values_matrix[i][j] == values_matrix[i][j+1]:
					return true
			#right middle
			elif j == SIZE - 1:
				if values_matrix[i][j] == values_matrix[i-1][j] || \
				   values_matrix[i][j] == values_matrix[i+1][j] || \
				   values_matrix[i][j] == values_matrix[i][j-1]:
					return true
			#center
			else:
				if values_matrix[i][j] == values_matrix[i-1][j] || \
					   values_matrix[i][j] == values_matrix[i][j-1] || \
					   values_matrix[i][j] == values_matrix[i+1][j] || \
					   values_matrix[i][j] == values_matrix[i][j+1]:
						return true
	return false

func copy_matrix(var dst, var src):
	for i in SIZE:
		for j in SIZE:
			dst[i][j] = src[i][j]

func is_same_matrices(var first, var second) -> bool:
	for i in SIZE:
		for j in SIZE:
			if first[i][j] != second[i][j]:
				return false
	return true

func game_over():
	emit_signal("game_over")

func restart_game():
	paused = false
	values_matrix = [[0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0], [0, 0, 0, 0]]
	update_tiles_matrix()
	new_tile()
	set_score(0)

func set_score(var s):
	score = s
	emit_signal("score_changed", score)

func set_paused(var b):
	paused = b
