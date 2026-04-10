@tool
extends PanelContainer

@onready var _output: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var _copy_btn: Button = $VBoxContainer/HeaderBox/CopyButton

var _compile_count: int = 0
var _plain_text: String = ""


func _ready() -> void:
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_copy_btn.pressed.connect(_on_copy_pressed)


func _on_copy_pressed() -> void:
	if not _plain_text.is_empty():
		DisplayServer.clipboard_set(_plain_text)


func clear_output() -> void:
	_compile_count = 0
	_plain_text = ""
	_output.clear()


func show_compiling() -> void:
	_plain_text = ""
	_output.clear()
	_output.append_text("[color=gray]Compiling...[/color]")


func show_result(result: Dictionary) -> void:
	_compile_count += 1
	_output.clear()
	_plain_text = ""

	var run_label := "[color=gray]Run #%d[/color]  " % _compile_count
	var status_line: String
	if result.get("success", false):
		status_line = "Run #%d  Compile successful\n" % _compile_count
		_output.append_text(run_label + "[color=green]Compile successful[/color]\n")
	else:
		status_line = "Run #%d  Compile failed\n" % _compile_count
		_output.append_text(run_label + "[color=red]Compile failed[/color]\n")
	_plain_text += status_line

	for issue in result.get("issues", []):
		var severity: int = issue.get("severity", 2)
		var msg: String   = issue.get("message", "")
		var node_id: String = issue.get("node_id", "")
		var code: String  = issue.get("code", "")

		var color: String = "red" if severity == 2 else ("yellow" if severity == 1 else "gray")
		var prefix: String = "ERROR" if severity == 2 else ("WARN" if severity == 1 else "INFO")

		var plain_line := "[%s]" % prefix
		if not node_id.is_empty():
			plain_line += " %s" % node_id
		if not code.is_empty():
			plain_line += " [%s]" % code
		plain_line += " — %s\n" % msg
		_plain_text += plain_line

		var bbcode_line := "[color=%s]%s[/color]\n" % [color, plain_line.strip_edges()]
		_output.append_text(bbcode_line)
