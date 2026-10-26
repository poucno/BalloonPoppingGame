extends RefCounted

enum Difficulty { EASY, MEDIUM, HARD }

const SAVE_PATH := "user://balloon_pop_save.dat"
const TOTAL_ROUNDS := 10

static var current_difficulty: int = Difficulty.EASY
static var high_scores: Dictionary = {}
static var last_score: int = 0
static var last_rounds_completed: int = 0
static var last_was_high_score: bool = false
static var _loaded: bool = false


static func _ensure_loaded() -> void:
	if not _loaded:
		_loaded = true
		_load_data()


# Difficulty  

static func get_difficulty_name(diff: int = -1) -> String:
	if diff < 0:
		diff = current_difficulty
	match diff:
		Difficulty.EASY: return "Easy"
		Difficulty.MEDIUM: return "Medium"
		Difficulty.HARD: return "Hard"
	return ""


static func get_round_time() -> float:
	match current_difficulty:
		Difficulty.EASY: return 20.0
		Difficulty.MEDIUM: return 15.0
		Difficulty.HARD: return 10.0
	return 20.0


static func get_balloon_count() -> int:
	match current_difficulty:
		Difficulty.EASY: return 20
		Difficulty.MEDIUM: return 24
		Difficulty.HARD: return 28
	return 20


# Score 

static func submit_score(p_score: int, rounds_done: int) -> void:
	_ensure_loaded()
	last_score = p_score
	last_rounds_completed = rounds_done
	var key := str(current_difficulty)
	var prev: int = high_scores.get(key, 0)
	last_was_high_score = p_score > prev and p_score > 0
	if last_was_high_score:
		high_scores[key] = p_score
		_save_data()


static func get_high_score(diff: int = -1) -> int:
	_ensure_loaded()
	if diff < 0:
		diff = current_difficulty
	return high_scores.get(str(diff), 0)


# Persistence

static func _save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_scores)


static func _load_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				high_scores = data
