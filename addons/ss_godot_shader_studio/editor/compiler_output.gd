@tool
extends PanelContainer

@onready var _output: RichTextLabel = $VBoxContainer/RichTextLabel

var _compile_count: int = 0


func _ready() -> void:
	_output.bbcode_enabled = true
	_output.scroll_following = true


func clear_output() -> void:
	_compile_count = 0
	_output.clear()


func show_compiling() -> void:
	_output.clear()
	_output.append_text("[color=gray]Compiling...[/color]")


func show_result(result: Dictionary) -> void:
	_compile_count += 1
	_output.clear()

	var run_label := "[color=gray]Run #%d[/color]  " % _compile_count
	if result.get("success", false):
		_output.append_text(run_label + "[color=green]Compile successful[/color]\n")
	else:
		_output.append_text(run_label + "[color=red]Compile failed[/color]\n")

	for issue in result.get("issues", []):
		var severity: int = issue.get("severity", 2)
		var msg: String   = issue.get("message", "")
		var node_id: String = issue.get("node_id", "")
		var code: String  = issue.get("code", "")

		var color: String = "red" if severity == 2 else ("yellow" if severity == 1 else "gray")
		var prefix: String = "ERROR" if severity == 2 else ("WARN" if severity == 1 else "INFO")

		var line := "[color=%s][%s]" % [color, prefix]
		if not node_id.is_empty():
			line += " %s" % node_id
		if not code.is_empty():
			line += " [%s]" % code
		line += " — %s[/color]\n" % msg
		_output.append_text(line)
