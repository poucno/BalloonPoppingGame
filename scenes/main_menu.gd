extends Node2D
const GameManager = preload("res://scripts/game_manager.gd")
const Balloon = preload("res://scripts/balloon.gd")
const SfxGenerator = preload("res://scripts/sfx_generator.gd")

var selected_difficulty: int = GameManager.Difficulty.EASY
var difficulty_buttons: Array[Button] = []
var high_score_label: Label
var sfx_click: AudioStreamWAV


func _ready() -> void:
	sfx_click = SfxGenerator.click_sound()
	selected_difficulty = GameManager.current_difficulty
	_create_ui()
	_spawn_background_balloons()


func _draw() -> void:
	var vs := get_viewport_rect().size
	# Sky
	draw_rect(Rect2(0, 0, vs.x, vs.y), Color("#a9e7f5"))
	# Clouds
	_draw_cloud(Vector2(vs.x * 0.12, vs.y * 0.08), 55)
	_draw_cloud(Vector2(vs.x * 0.78, vs.y * 0.13), 70)
	_draw_cloud(Vector2(vs.x * 0.45, vs.y * 0.05), 42)
	_draw_cloud(Vector2(vs.x * 0.93, vs.y * 0.22), 38)
	# Ground
	draw_rect(Rect2(0, vs.y - 60, vs.x, 60), Color("#75c4c6"))


# UI creation 

func _create_ui() -> void:
	var vs := get_viewport_rect().size
	var cx := vs.x / 2.0

	# Title
	var title := _make_label("BALLOON POP MATH", 52, Color("#243052"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size = Vector2(750, 70)
	title.position = Vector2(cx - 375, vs.y * 0.10)
	title.pivot_offset = title.size / 2.0
	add_child(title)
	# Pulse
	var tw := create_tween().set_loops()
	tw.tween_property(title, "scale", Vector2(1.03, 1.03), 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(title, "scale", Vector2.ONE, 1.2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Subtitle
	var sub := _make_label("Pop the right balloons to solve math problems!", 22, Color("#4a6fa5"))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(620, 35)
	sub.position = Vector2(cx - 310, vs.y * 0.24)
	add_child(sub)

	# Select Difficulty
	var dh := _make_label("Select Difficulty:", 22, Color("#243052"))
	dh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dh.size = Vector2(300, 30)
	dh.position = Vector2(cx - 150, vs.y * 0.34)
	add_child(dh)

	# Difficulty buttons
	var bw := 155.0
	var bh := 52.0
	var gap := 22.0
	var total := bw * 3 + gap * 2
	var sx := cx - total / 2.0
	var by := vs.y * 0.42

	var diffs := [
		{"label": "Easy",   "color": Color("#22c55e")},
		{"label": "Medium", "color": Color("#eab308")},
		{"label": "Hard",   "color": Color("#ef4444")},
	]
	for i in diffs.size():
		var btn := _styled_button(diffs[i]["label"],
				Vector2(sx + i * (bw + gap), by), Vector2(bw, bh),
				_on_difficulty.bind(i), diffs[i]["color"])
		difficulty_buttons.append(btn)
	_refresh_difficulty_highlight()

	# PLAY button
	_styled_button("PLAY", Vector2(cx - 135, vs.y * 0.57),
			Vector2(270, 68), _on_play, Color("#2563eb"), 30)

	# High score
	high_score_label = _make_label(
			"Best Score: %d" % GameManager.get_high_score(selected_difficulty),
			22, Color("#4a6fa5"))
	high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	high_score_label.size = Vector2(400, 30)
	high_score_label.position = Vector2(cx - 200, vs.y * 0.73)
	add_child(high_score_label)


# Difficulty selection

func _on_difficulty(diff: int) -> void:
	selected_difficulty = diff
	GameManager.current_difficulty = diff
	_refresh_difficulty_highlight()
	high_score_label.text = "Best Score: %d" % GameManager.get_high_score(diff)
	_play_sfx(sfx_click)


func _refresh_difficulty_highlight() -> void:
	for i in difficulty_buttons.size():
		var btn := difficulty_buttons[i]
		var s: StyleBoxFlat = btn.get_theme_stylebox("normal").duplicate()
		if i == selected_difficulty:
			s.border_width_bottom = 3; s.border_width_top = 3
			s.border_width_left = 3;   s.border_width_right = 3
			s.border_color = Color.WHITE
		else:
			s.border_width_bottom = 0; s.border_width_top = 0
			s.border_width_left = 0;   s.border_width_right = 0
		btn.add_theme_stylebox_override("normal", s)
		var h := s.duplicate()
		h.bg_color = h.bg_color.lightened(0.12)
		btn.add_theme_stylebox_override("hover", h)


func _on_play() -> void:
	_play_sfx(sfx_click)
	get_tree().change_scene_to_file("res://scenes/game.tscn")


# Background balloons
# TODO Make them not clickable
func _spawn_background_balloons() -> void:
	var vs := get_viewport_rect().size
	for i in 10:
		var b := Balloon.new()
		b.answer = randi_range(0, 9)
		b.set_sprite_index(i)
		b.size = Vector2(70, 96)
		b.is_active = false
		b.animate_entry = false
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.base_position = Vector2(randf_range(20, vs.x - 95),
								  randf_range(180, vs.y - 160))
		b.position = b.base_position
		b.modulate.a = 0.28
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
		cb: Callable, color: Color, fs: int = 22) -> Button:
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
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)

