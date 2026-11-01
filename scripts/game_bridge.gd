extends Node

signal questions_received(questions: Array)

var questions: Array = []
var _started: bool = false
var _callback_ref: JavaScriptObject

func _ready() -> void:
	if not OS.has_feature("web"):
		return

	var window := JavaScriptBridge.get_interface("window")
	if window == null:
		return

	_callback_ref = JavaScriptBridge.create_callback(_on_message)
	window.addEventListener("message", _callback_ref)
	_post({"type": "ready"})

func _on_message(args: Array) -> void:
	if args.is_empty() or _started:
		return

	var message = JSON.parse_string(str(args[0].data))
	if typeof(message) != TYPE_DICTIONARY or message.get("type") != "start":
		return

	_started = true
	questions = message.get("questions", [])
	questions_received.emit(questions)

func send_result(payload: Dictionary) -> void:
	_post({"type": "result", "payload": payload})

func _post(message: Dictionary) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		"window.parent.postMessage(%s, window.location.origin);" % JSON.stringify(JSON.stringify(message)),
		true
	)
