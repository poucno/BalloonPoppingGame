extends Control

signal popped(answer: int)

const SPRITE_PATHS: Array[String] = [
	"res://sprites/balloon_form_1_1.png",
	"res://sprites/balloon_form_1_8.png",
	"res://sprites/balloon_form_1_13.png",
	"res://sprites/balloon_form_1_16.png",
	"res://sprites/balloon_form_1_20.png",
	"res://sprites/balloon_form_1_24.png",
	"res://sprites/balloon_form_1_27.png",
	"res://sprites/balloon_form_1_28.png",
	"res://sprites/balloon_form_1_31.png",
	"res://sprites/balloon_form_1_34.png",
]


const COLORS: Array[Color] = [
	Color("#ff3681"), 
	Color("#752dea"), 
	Color("#4ad7ff"), 
	Color("#3afa72"), 
	Color("#f6ff4a"),
	Color("#ff863f"), 
	Color("#df172f"), 
	Color("#ffd7fe"), 
	Color("#d6b7fe"), 
	Color("#ff9813"), 
]

static var _cached_textures: Array[Texture2D] = []


static func get_texture(index: int) -> Texture2D:
	if _cached_textures.is_empty():
		for path in SPRITE_PATHS:
			if ResourceLoader.exists(path):
				var tex := load(path) as Texture2D
				if tex:
					_cached_textures.append(tex)
	if _cached_textures.is_empty():
		return null
	return _cached_textures[posmod(index, _cached_textures.size())]


var answer := 0
var balloon_color := Color.WHITE
var sprite_index := 0
var texture: Texture2D
var base_position := Vector2.ZERO
var bob_phase := 0.0
var bob_time := 0.0
var bob_speed := 1.5
var bob_amplitude := 6.0
var is_active := true
var animate_entry := true
var _hover := false
var _popping := false


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_STOP
	bob_phase = randf() * TAU
	pivot_offset = size / 2.0
	mouse_entered.connect(func(): _hover = true; queue_redraw())
	mouse_exited.connect(func(): _hover = false; queue_redraw())

	if texture == null:
		texture = get_texture(sprite_index)
	if balloon_color == Color.WHITE:
		balloon_color = COLORS[posmod(sprite_index, COLORS.size())]

	if animate_entry:
		scale = Vector2.ZERO
		modulate.a = 0.0
		var delay := randf() * 0.35
		var tw := create_tween()
		tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.set_parallel(true)
		tw.tween_property(self, "scale", Vector2.ONE, 0.35).set_delay(delay)
		tw.tween_property(self, "modulate:a", 1.0, 0.2).set_delay(delay)


func set_sprite_index(idx: int) -> void:
	sprite_index = idx
	texture = get_texture(idx)
	balloon_color = COLORS[posmod(idx, COLORS.size())]
	queue_redraw()


func _process(delta: float) -> void:
	if _popping:
		return
	bob_time += delta
	position = Vector2(
		base_position.x,
		base_position.y + sin(bob_time * bob_speed + bob_phase) * bob_amplitude
	)
	queue_redraw()


func _draw() -> void:
	if texture == null:
		texture = get_texture(sprite_index)

	# Calculate sprite dimensions preserving aspect ratio
	var tex_w := 107.0
	var tex_h := 148.0
	if texture:
		tex_w = texture.get_width()
		tex_h = texture.get_height()
	var aspect := tex_w / tex_h

	
	var string_reserve := size.y * 0.16
	var max_sprite_h := size.y - string_reserve
	var sprite_h := minf(max_sprite_h, size.x / aspect)
	var sprite_w := sprite_h * aspect
	var sprite_x := (size.x - sprite_w) / 2.0
	var sprite_y := 2.0
	var sprite_rect := Rect2(sprite_x, sprite_y, sprite_w, sprite_h)

	# Soft drop shadow
	if texture:
		draw_texture_rect(texture, Rect2(sprite_x + 3.0, sprite_y + 4.0, sprite_w, sprite_h), false, Color(0.08, 0.12, 0.26, 0.2))

	# String hanging from knot
	var knot_pos := Vector2(size.x / 2.0, sprite_y + sprite_h - 1.0)
	var string_bot := Vector2(size.x / 2.0, size.y - 2.0)
	var swing := sin(bob_time * 2.0 + bob_phase) * 3.5
	var string_mid := (knot_pos + string_bot) / 2.0 + Vector2(swing, 0.0)
	var string_col := balloon_color.darkened(0.35)
	draw_line(knot_pos, string_mid, string_col, 1.8)
	draw_line(string_mid, string_bot, string_col, 1.8)

	# Balloon sprite
	if texture:
		var tint := Color(1.15, 1.15, 1.15, 1.0) if (_hover and is_active) else Color.WHITE
		draw_texture_rect(texture, sprite_rect, false, tint)

	# Number label 
	var font: Font = ThemeDB.fallback_font
	var txt := str(answer)
	var fs: int = int(clampf(sprite_h * 0.26, 20.0, 32.0))
	var ts := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	var text_center_y := sprite_y + sprite_h * 0.40
	var text_pos := Vector2(size.x / 2.0 - ts.x / 2.0, text_center_y + ts.y * 0.32)

	# Outline 
	draw_string_outline(font, text_pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 5, Color(1, 1, 1, 0.95))
	draw_string(font, text_pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("#1a2238"))


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		popped.emit(answer)


# Balloon shake 
func shake() -> void:
	var bx := base_position.x
	var tw := create_tween()
	tw.tween_property(self, "base_position:x", bx + 10, 0.04)
	tw.tween_property(self, "base_position:x", bx - 10, 0.04)
	tw.tween_property(self, "base_position:x", bx + 6, 0.04)
	tw.tween_property(self, "base_position:x", bx - 6, 0.04)
	tw.tween_property(self, "base_position:x", bx, 0.04)


# Pop animation
func pop_animate() -> void:
	_popping = true
	is_active = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(queue_free)
