extends Node

# Headless-Einstieg: alle Suites laufen lassen, dann mit Exit-Code beenden.
# Aufruf: godot --headless --path godot res://addons/dame/tests/run_all.tscn

const TestContext = preload("res://addons/dame/tests/test_context.gd")
const SUITES := [
	"res://addons/dame/tests/test_stage1.gd",
	"res://addons/dame/tests/test_rules_core.gd",
	"res://addons/dame/tests/test_peek.gd",
	"res://addons/dame/tests/test_throw_in.gd",
	"res://addons/dame/tests/test_king.gd",
	"res://addons/dame/tests/test_modes.gd",
	"res://addons/dame/tests/test_ai.gd",
	"res://addons/dame/tests/test_table_ui.gd",
	"res://addons/dame/tests/test_meta.gd",
	"res://addons/dame/tests/test_net.gd",
	"res://addons/dame/tests/test_table_net.gd",
	"res://addons/dame/tests/test_presence.gd",
	"res://addons/dame/tests/test_peer_link.gd",
	"res://addons/dame/tests/test_online_table.gd",
	"res://addons/dame/tests/test_rtc_code.gd",
	"res://addons/dame/tests/test_rtc_connector.gd",
	"res://addons/dame/tests/test_ice_servers.gd",
	"res://addons/dame/tests/test_ice_fetcher.gd",
	"res://addons/dame/tests/test_signaling.gd",
	"res://addons/dame/tests/test_rejoin.gd",
	"res://addons/dame/tests/test_online_screen.gd",
	"res://addons/dame/tests/test_golden.gd",
]

func _ready() -> void:
	var app := get_node_or_null("/root/App")
	if app != null:
		# DAMEs Tests prüfen DAMEs eigenen Ablauf, auch wenn eine einbettende App (Latte) home_scene umgelenkt hat.
		app.home_scene = app.MAIN_MENU
		app.use_test_storage()
	var ctx = TestContext.new()
	ctx.root = self
	for path in SUITES:
		ctx.current_suite = path.get_file().get_basename()
		var script: GDScript = load(path)
		if script == null:
			ctx.failures.append("%s: Suite nicht ladbar" % path)
			continue
		var suite = script.new()
		suite.run(ctx)
	if ctx.failures.is_empty():
		print("ALL_TESTS_OK checks=%d suites=%d" % [ctx.checks, SUITES.size()])
		call_deferred("_quit", 0)
	else:
		for line in ctx.failures:
			print("TEST_FAIL ", line)
		call_deferred("_quit", 1)

func _quit(code: int) -> void:
	get_tree().quit(code)
