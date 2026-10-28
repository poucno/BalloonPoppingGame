extends Node2D

const GameManager = preload("res://scripts/game_manager.gd")
const Balloon = preload("res://scripts/balloon.gd")
const SfxGenerator = preload("res://scripts/sfx_generator.gd")

var rng := RandomNumberGenerator.new()
var balloons: Array = []
var correct_answer := 0
var current_equation := ""
var score := 0
var streak := 0
var round_number := 0
var round_active := false
var time_remaining := 0.0
var round_time := 0.0
var last_tick_sec := -1

# UI
var equation_label: Label
var feedback_label: Label
var score_label: Label
var round_label: Label
var timer_label: Label

# Audio
var sfx_pop: AudioStreamWAV
var sfx_correct: AudioStreamWAV
var sfx_wrong: AudioStreamWAV
var sfx_tick: AudioStreamWAV


func _ready() -> void:
	rng.randomize()
	_setup_audio()
	_create_ui()
	_start_round()


func _process(delta: float) -> void:
	if round_active:
		time_remaining -= delta
		if time_remaining <= 0.0:
			time_remaining = 0.0
			_time_up()
		timer_label.text = "⏱ %.1f" % time_remaining
		var sec := int(ceil(time_remaining))
		if time_remaining <= 5.0 and sec != last_tick_sec and time_remaining > 0.0:
			last_tick_sec = sec
			_play_sfx(sfx_tick)
	queue_redraw()


# Drawing 

func _draw() -> void:
	var vs := get_viewport_rect().size
	# Sky
	draw_rect(Rect2(0, 0, vs.x, vs.y * 0.6), Color("#a9e7f5"))
	draw_rect(Rect2(0, vs.y * 0.6, vs.x, vs.y * 0.4), Color("#8dd8e8"))
	# Clouds
	_draw_cloud(Vector2(vs.x * 0.10, 55), 50)
	_draw_cloud(Vector2(vs.x * 0.85, 78), 65)
	_draw_cloud(Vector2(vs.x * 0.48, 32), 40)
	# Ground
	draw_rect(Rect2(0, vs.y - 50, vs.x, 50), Color("#75c4c6"))

	# Timer bar
	if round_time > 0.0:
		var margin := 40.0
		var bar_w := vs.x - margin * 2
		var bar_y := 188.0
		var bar_h := 8.0
		var pct := clampf(time_remaining / round_time, 0.0, 1.0)
		draw_rect(Rect2(margin, bar_y, bar_w, bar_h), Color(0, 0, 0, 0.12))
		var bar_col: Color
		if pct > 0.5:    bar_col = Color("#4ade80")
		elif pct > 0.25: bar_col = Color("#fbbf24")
		else:            bar_col = Color("#f87171")
		draw_rect(Rect2(margin, bar_y, bar_w * pct, bar_h), bar_col)


func _draw_cloud(pos: Vector2, sz: float) -> void:
	var c := Color(1, 1, 1, 0.4)
	draw_circle(pos, sz * 0.7, c)
	draw_circle(pos + Vector2(-sz * 0.5, sz * 0.1), sz * 0.5, c)
	draw_circle(pos + Vector2(sz * 0.5, sz * 0.15), sz * 0.55, c)
	draw_circle(pos + Vector2(0, sz * 0.3), sz * 0.45, c)


# Audio 

func _setup_audio() -> void:
	sfx_pop     = SfxGenerator.pop_sound()
	sfx_correct = SfxGenerator.correct_chime()
	sfx_wrong   = SfxGenerator.wrong_buzz()
	sfx_tick    = SfxGenerator.countdown_tick()


func _play_sfx(stream: AudioStreamWAV) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


# UI

func _create_ui() -> void:
	var vs := get_viewport_rect().size

	round_label = _make_label("", 22, Color("#243052"))
	round_label.position = Vector2(30, 16)
	add_child(round_label)

	score_label = _make_label("", 22, Color("#243052"))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_label.position = Vector2(vs.x - 350, 16)
	score_label.size = Vector2(320, 32)
	add_child(score_label)

	equation_label = _make_label("", 48, Color("#243052"))
	equation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equation_label.position = Vector2(vs.x / 2.0 - 260, 50)
	equation_label.size = Vector2(520, 62)
	add_child(equation_label)

	feedback_label = _make_label("", 22, Color.WHITE)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.position = Vector2(vs.x / 2.0 - 310, 122)
	feedback_label.size = Vector2(620, 32)
	add_child(feedback_label)

	timer_label = _make_label("", 22, Color("#243052"))
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.position = Vector2(vs.x / 2.0 - 50, 155)
	timer_label.size = Vector2(100, 28)
	add_child(timer_label)


func _make_label(text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l


# Problem generation

func _generate_problem() -> void:
	var d: int = GameManager.current_difficulty
	match d:
		GameManager.Difficulty.EASY:
			var a := rng.randi_range(1, 9)
			var b := rng.randi_range(1, 9)
			correct_answer = a + b
			current_equation = "%d + %d = ?" % [a, b]

		GameManager.Difficulty.MEDIUM:
			var op := rng.randi_range(0, 2)
			if op == 0:
				var a := rng.randi_range(2, 15)
				var b := rng.randi_range(2, 15)
				correct_answer = a + b
				current_equation = "%d + %d = ?" % [a, b]
			elif op == 1:
				var a := rng.randi_range(5, 20)
				var b := rng.randi_range(1, a - 1)
				correct_answer = a - b
				current_equation = "%d − %d = ?" % [a, b]
			else:
				var a := rng.randi_range(2, 6)
				var b := rng.randi_range(2, 6)
				correct_answer = a * b
				current_equation = "%d × %d = ?" % [a, b]

		GameManager.Difficulty.HARD:
			var op := rng.randi_range(0, 2)
			if op == 0:
				var a := rng.randi_range(10, 50)
				var b := rng.randi_range(10, 50)
				correct_answer = a + b
				current_equation = "%d + %d = ?" % [a, b]
			elif op == 1:
				var a := rng.randi_range(20, 60)
				var b := rng.randi_range(5, a - 1)
				correct_answer = a - b
				current_equation = "%d − %d = ?" % [a, b]
			else:
				var a := rng.randi_range(2, 12)
				var b := rng.randi_range(2, 9)
				correct_answer = a * b
				current_equation = "%d × %d = ?" % [a, b]


# Answers 

func _build_answers(count: int) -> Array[int]:
	var answers: Array[int] = [correct_answer]
	while answers.size() < count:
		var wrong: int
		if rng.randf() < 0.4:
			wrong = correct_answer + rng.randi_range(-5, 5)
		else:
			wrong = rng.randi_range(maxi(1, correct_answer - 15),
									correct_answer + 15)
		if wrong > 0 and wrong != correct_answer and wrong not in answers:
			answers.append(wrong)
	answers.shuffle()
	return answers


# Round lifecycle 

func _start_round() -> void:
	# clean previous
	for b in balloons:
		if is_instance_valid(b):
			b.queue_free()
	balloons.clear()

	round_number += 1
	if round_number > GameManager.TOTAL_ROUNDS:
		_end_game()
		return

	_generate_problem()
	round_time = GameManager.get_round_time()
	time_remaining = round_time
	last_tick_sec = -1
	round_active = true

	# refresh UI
	equation_label.text = current_equation
	round_label.text = "Round %d / %d" % [round_number, GameManager.TOTAL_ROUNDS]
	score_label.text = "%d    %d" % [score, streak]
	feedback_label.text = "Pop the correct answer!"
	feedback_label.add_theme_color_override("font_color", Color.WHITE)

	# spawn balloons
	var count: int = GameManager.get_balloon_count()
	var answers := _build_answers(count)
	var vs := get_viewport_rect().size

	var cols: int
	match count:
		20: cols = 5
		24: cols = 6
		28: cols = 7
		_:  cols = 6
	var rows := ceili(count / float(cols))

	var top := 205.0
	var bot := 20.0
	var side := 30.0
	var aw := vs.x - side * 2
	var ah := vs.y - top - bot
	var xs := aw / float(cols)
	var ys := ah / float(rows)
	var bsz := Vector2(minf(xs * 0.75, 85), minf(ys * 0.92, 115))

	for i in count:
		var b := Balloon.new()
		b.answer = answers[i]
		b.set_sprite_index(i)
		b.size = bsz
		var c := i % cols
		var r := i / cols
		var pos := Vector2(
			side + c * xs + xs / 2.0 - bsz.x / 2.0 + rng.randf_range(-8, 8),
			top + r * ys + rng.randf_range(-6, 6))
		b.base_position = pos
		b.position = pos
		b.bob_speed = rng.randf_range(1.2, 2.0)
		b.bob_amplitude = rng.randf_range(4.0, 8.0)
		b.popped.connect(_on_balloon_popped.bind(b))
		add_child(b)
		balloons.append(b)


# nteraction

func _on_balloon_popped(answer: int, balloon: Balloon) -> void:
	if not round_active:
		return
	# Correct answer
	if answer == correct_answer:
		
		round_active = false
		streak += 1
		var bonus := 10 + (streak - 1) * 2
		score += bonus

		_play_sfx(sfx_pop)
		get_tree().create_timer(0.08).timeout.connect(func(): _play_sfx(sfx_correct))

		feedback_label.text = "Correct!  +%d points!" % bonus
		feedback_label.add_theme_color_override("font_color", Color("#176b58"))
		score_label.text = "%d     %d" % [score, streak]

		_spawn_confetti(balloon.position + balloon.size / 2.0, balloon.balloon_color)
		_show_floating_text("+%d" % bonus,
				balloon.position + Vector2(balloon.size.x / 2.0 - 30, -10),
				Color("#176b58"))
		balloon.pop_animate()

		# freeze remaining balloons
		for b in balloons:
			if is_instance_valid(b) and b != balloon:
				b.is_active = false
				b.mouse_filter = Control.MOUSE_FILTER_IGNORE

		await get_tree().create_timer(1.4).timeout
		_start_round()
	else:
		# Wrong answer
		streak = 0
		_play_sfx(sfx_wrong)
		feedback_label.text = "Not quite — try another balloon!"
		feedback_label.add_theme_color_override("font_color", Color("#b83b5e"))
		score_label.text = "%d    %d" % [score, streak]
		balloon.shake()


func _time_up() -> void:
	if not round_active:
		return
	round_active = false
	streak = 0

	feedback_label.text = "Time's up!  The answer was %d" % correct_answer
	feedback_label.add_theme_color_override("font_color", Color("#b83b5e"))
	score_label.text = "%d    %d" % [score, streak]

	# Flash the correct balloon for help
	for b in balloons:
		if is_instance_valid(b):
			b.is_active = false
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if b.answer == correct_answer:
				var tw := create_tween().set_loops(3)
				tw.tween_property(b, "modulate", Color(1, 1, 1, 0.3), 0.2)
				tw.tween_property(b, "modulate", Color.WHITE, 0.2)

	await get_tree().create_timer(2.0).timeout
	_start_round()


func _end_game() -> void:
	GameManager.submit_score(score, round_number - 1)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


# VFX

func _spawn_confetti(pos: Vector2, color: Color) -> void:
	for i in 18:
		var piece := ColorRect.new()
		piece.size = Vector2(rng.randf_range(4, 10), rng.randf_range(4, 10))
		var c := color.lightened(rng.randf_range(-0.1, 0.3))
		if rng.randf() < 0.25:
			c = Color("#ffd700")
		piece.color = c
		piece.position = pos - piece.size / 2.0
		piece.pivot_offset = piece.size / 2.0
		add_child(piece)
		var angle := rng.randf() * TAU
		var dist := rng.randf_range(50, 160)
		var target := pos + Vector2(cos(angle), sin(angle)) * dist + Vector2(0, rng.randf_range(20, 65))
		var dur := rng.randf_range(0.35, 0.65)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(piece, "position", target, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(piece, "modulate:a", 0.0, dur + 0.15)
		tw.tween_property(piece, "rotation", rng.randf_range(-5, 5), dur)
		tw.tween_property(piece, "scale", Vector2(0.2, 0.2), dur)
		tw.chain().tween_callback(piece.queue_free)


func _show_floating_text(text: String, pos: Vector2, color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 30)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size = Vector2(120, 40)
	lbl.position = Vector2(pos.x - 60, pos.y)
	add_child(lbl)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(lbl, "position:y", pos.y - 65, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tw.chain().tween_callback(lbl.queue_free)

