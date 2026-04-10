## Lightweight test base class.
## Extend it and prefix methods with "test_" — runner auto-discovers them.
## Optionally override setup() and teardown() for per-test fixtures.
class_name TestCase


var _pass_count: int = 0
var _fail_count: int = 0
var _current_test: String = ""


# Called once before the entire suite.
func before_all():
	pass


# Called once after the entire suite.
func after_all():
	pass


# Called before each test_ method.
func setup():
	pass


# Called after each test_ method.
func teardown():
	pass


func run_all() -> void:
	_pass_count = 0
	_fail_count = 0

	await before_all()

	var methods: Array[String] = []
	for m in get_method_list():
		var mname: String = m["name"]
		if mname.begins_with("test_"):
			methods.append(mname)
	methods.sort()

	for method_name in methods:
		_current_test = method_name
		await setup()
		await call(method_name)
		await teardown()

	await after_all()


func get_pass_count() -> int:
	return _pass_count


func get_fail_count() -> int:
	return _fail_count


func suite_name() -> String:
	return get_script().resource_path.get_file().trim_suffix(".gd")


# ---- Assertion helpers ----

func assert_eq(actual, expected, msg: String = "") -> void:
	if actual == expected:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected %s == %s" % [_repr(actual), _repr(expected)], msg)


func assert_ne(actual, not_expected, msg: String = "") -> void:
	if actual != not_expected:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected %s != %s" % [_repr(actual), _repr(not_expected)], msg)


func assert_true(condition: bool, msg: String = "") -> void:
	if condition:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected true", msg)


func assert_false(condition: bool, msg: String = "") -> void:
	if not condition:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected false", msg)


func assert_null(value, msg: String = "") -> void:
	if value == null:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected null, got %s" % _repr(value), msg)


func assert_not_null(value, msg: String = "") -> void:
	if value != null:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected non-null value", msg)


func assert_contains(haystack: String, needle: String, msg: String = "") -> void:
	if haystack.contains(needle):
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail('expected string to contain "%s"' % needle, msg)


func assert_not_contains(haystack: String, needle: String, msg: String = "") -> void:
	if not haystack.contains(needle):
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail('expected string NOT to contain "%s"' % needle, msg)


func assert_gt(actual, minimum, msg: String = "") -> void:
	if actual > minimum:
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected %s > %s" % [_repr(actual), _repr(minimum)], msg)


func assert_array_has(arr: Array, value, msg: String = "") -> void:
	if arr.has(value):
		_pass_count += 1
	else:
		_fail_count += 1
		_report_fail("expected array to contain %s" % _repr(value), msg)


# ---- Internal helpers ----

func _report_fail(detail: String, user_msg: String) -> void:
	var info := "[FAIL] %s::%s — %s" % [suite_name(), _current_test, detail]
	if not user_msg.is_empty():
		info += " | %s" % user_msg
	print(info)


func _repr(v) -> String:
	if v == null:
		return "null"
	if v is String:
		return '"%s"' % v
	return str(v)
