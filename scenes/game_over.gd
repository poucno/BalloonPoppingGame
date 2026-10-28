extends Node2D
const GameManager = preload("res://scripts/game_manager.gd")
const Balloon = preload("res://scripts/balloon.gd")
const SfxGenerator = preload("res://scripts/sfx_generator.gd")

var sfx_click: AudioStreamWAV


func _ready() -> void:
	sfx_click = SfxGenerator.click_sound()
	_create_ui()
	_spawn_decorative_balloons()
	if GameManager.last_was_high_score:
		_celebrate()


func _draw() -> void:
	var vs := get_viewport_rect().size
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color("#a9e7f5"))
	_draw_cloud(Vector2(vs.x * 0.14, vs.y * 0.10), 55)
	_draw_cloud(Vector2(vs.x * 0.80, vs.y * 0.08), 65)
	_draw_cloud(Vector2(vs.x * 0.50, vs.y * 0.15), 40)
	draw_rect(Rect2(0, vs.y - 60, vs.x, 60), Color("#75c4c6"))


# UI 

func _create_ui() -> void:
	var vs := get_viewport_rect().size
	var cx := vs.x / 2.0

	# Title
	var title_text: String
	if GameManager.last_was_high_score:
		title_text = "NEW HIGH SCORE! "
	elif GameManager.last_score > 0:
		title_text = "GREAT JOB!"
	else:
		title_text = "GAME OVER"
	var title := _make_label(title_text, 48, Color("#243052"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(720, 65)
	title.position = Vector2(cx - 360, vs.y * 0.08)
	add_child(title)

	# Score
	var sl := _make_label("Score: %d" % GameManager.last_score, 42, Color("#243052"))
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sl.size = Vector2(500, 58)
	sl.position = Vector2(cx - 250, vs.y * 0.22)
	add_child(sl)

	# High score
	var hl := _make_label("Best: %d" % GameManager.get_high_score(), 26, Color("#4a6fa5"))
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.size = Vector2(400, 36)
	hl.position = Vector2(cx - 200, vs.y * 0.35)
	add_child(hl)

	# Info
	var info := _make_label(
		"%s   •   Rounds: %d / %d" % [
			GameManager.get_difficulty_name(),
			GameManager.last_rounds_completed,
			GameManager.TOTAL_ROUNDS],
		20, Color("#5a7fa5"))
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.size = Vector2(520, 30)
	info.position = Vector2(cx - 260, vs.y * 0.44)
	add_child(info)

	# Buttons
	var bw := 225.0
	var bh := 60.0
	var gap := 30.0
	_styled_button("🎮  Play Again",
		Vector2(cx - bw - gap / 2.0, vs.y * 0.56),
		Vector2(bw, bh), _on_play_again, Color("#22c55e"))
	_styled_button("Main Menu",
		Vector2(cx + gap / 2.0, vs.y * 0.56),
		Vector2(bw, bh), _on_main_menu, Color("#2563eb"))


# Navigation 

func _on_play_again() -> void:
	_play_sfx(sfx_click)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_main_menu() -> void:
	_play_sfx(sfx_click)
	get_tree().change_scene_to_file("res://main.tscn")


# Celebration confetti

func _celebrate() -> void:
	var vs := get_viewport_rect().size
	for burst in 5:
		var pos := Vector2(randf_range(100, vs.x - 100), randf_range(80, 280))
		get_tree().create_timer(burst * 0.35).timeout.connect(_burst.bind(pos))


func _burst(pos: Vector2) -> void:
	var colors := [Color("#ff6b8a"), Color("#ffd700"), Color("#4ade80"),
				   Color("#7ca8ff"), Color("#c38cff")]
	for i in 14:
		var p := ColorRect.new()
		p.size = Vector2(randf_range(5, 11), randf_range(5, 11))
		p.color = colors[i % colors.size()]
		p.position = pos
		p.pivot_offset = p.size / 2.0
		add_child(p)
		var angle := randf() * TAU
		var dist := randf_range(60, 190)
		var target := pos + Vector2(cos(angle), sin(angle)) * dist + Vector2(0, randf_range(30, 80))
		var dur := randf_range(0.5, 0.9)
		var tw := create_tween().set_parallel(true)
		tw.tween_property(p, "position", target, dur).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
		tw.tween_property(p, "modulate:a", 0.0, dur + 0.3)
		tw.tween_property(p, "rotation", randf_range(-5, 5), dur)
		tw.chain().tween_callback(p.queue_free)


# Decorative balloons 

func _spawn_decorative_balloons() -> void:
	var vs := get_viewport_rect().size
	for i in 6:
		var b := Balloon.new()
		b.answer = randi_range(0, 9)
		b.set_sprite_index(i)
		b.size = Vector2(70, 96)
		b.is_active = false
		b.animate_entry = false
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.base_position = Vector2(randf_range(20, vs.x - 90),
								  randf_range(vs.y * 0.55, vs.y - 120))
		b.position = b.base_position
		b.modulate.a = 0.3
		b.bob_amplitude = randf_range(8, 14)
		b.bob_speed = randf_range(0.6, 1.2)
		add_child(b)


# Helpers 

func _draw_cloud(pos: Vector2, sz: float) -> void:
	var c := Color(1, 1, 1, 0.4)
	draw_circle(pos, sz * 0.7, c)
	draw_circle(pos + Vector2(-sz * 0.5, sz * 0.1), sz * 0.5, c)
	draw_circle(pos + Vector2(sz * 0.5, sz * 0.15), sz * 0.55, c)


func _make_label(text: String, fs: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	return l


func _styled_button(text: String, pos: Vector2, sz: Vector2,
		cb: Callable, color: Color, fs: int = 24) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.position = pos
	btn.size = sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", fs)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1, 0.8))
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(14)
	s.content_margin_left = 16;  s.content_margin_right = 16
	s.content_margin_top = 8;    s.content_margin_bottom = 8
	btn.add_theme_stylebox_override("normal", s)
	var h := s.duplicate(); h.bg_color = color.lightened(0.12)
	btn.add_theme_stylebox_override("hover", h)
	var p := s.duplicate(); p.bg_color = color.darkened(0.1)
	btn.add_theme_stylebox_override("pressed", p)
	btn.add_theme_stylebox_override("focus", s.duplicate())
	btn.pressed.connect(cb)
	add_child(btn)
	return btn


func _play_sfx(stream: AudioStreamWAV) -> void:
	var pl := AudioStreamPlayer.new()
	pl.stream = stream
	add_child(pl)
	pl.play()
	pl.finished.connect(pl.queue_free)

