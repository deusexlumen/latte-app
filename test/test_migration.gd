# PURPOSE: Migration alter Spielstände: kopiert fehlende Dateien und Ordner, überschreibt nie, läuft nur einmal.
# ARCHITECTURE: test
# DEPENDENCIES: app/migration.gd
# PIPELINE: test
# LAST_VALIDATED: 2026-10-12
extends GutTest

const Migration := preload("res://app/migration.gd")

var root := ""


func before_each() -> void:
	root = OS.get_user_data_dir().path_join("test_migration")
	_rm(root)
	DirAccess.make_dir_recursive_absolute(root.path_join("LOBBY-LOOP/widerlegung_bibliothek"))
	DirAccess.make_dir_recursive_absolute(root.path_join("Dame"))
	DirAccess.make_dir_recursive_absolute(root.path_join("Latte"))
	_write(root.path_join("LOBBY-LOOP/savegame.json"), '{"current_scene": "fraktionssitzung"}')
	_write(root.path_join("LOBBY-LOOP/widerlegung_bibliothek/index.json"), '{"lehren": []}')
	_write(root.path_join("Dame/settings.json"), '{"language": "de"}')


func after_all() -> void:
	_rm(root)


func test_copies_missing_files_and_dirs() -> void:
	var done := Migration.migrate(root.path_join("Latte"), root)
	assert_true(done.has("LOBBY-LOOP/savegame.json"))
	assert_true(done.has("LOBBY-LOOP/widerlegung_bibliothek/"))
	assert_true(done.has("Dame/settings.json"))
	assert_eq(FileAccess.get_file_as_string(root.path_join("Latte/savegame.json")), '{"current_scene": "fraktionssitzung"}')
	assert_true(FileAccess.file_exists(root.path_join("Latte/widerlegung_bibliothek/index.json")))
	assert_true(FileAccess.file_exists(root.path_join("LOBBY-LOOP/savegame.json")), "Quelle bleibt erhalten")


func test_never_overwrites_and_runs_once() -> void:
	_write(root.path_join("Latte/savegame.json"), '{"current_scene": "neu"}')
	Migration.migrate(root.path_join("Latte"), root)
	assert_eq(FileAccess.get_file_as_string(root.path_join("Latte/savegame.json")), '{"current_scene": "neu"}')
	DirAccess.remove_absolute(root.path_join("Latte/settings.json"))
	assert_eq(Migration.migrate(root.path_join("Latte"), root), [], "zweiter Lauf tut nichts (Marker)")
	assert_false(FileAccess.file_exists(root.path_join("Latte/settings.json")))


func test_missing_old_apps_is_fine() -> void:
	_rm(root.path_join("LOBBY-LOOP"))
	_rm(root.path_join("Dame"))
	assert_eq(Migration.migrate(root.path_join("Latte"), root), [])


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)


func _rm(dir: String) -> void:
	if not DirAccess.dir_exists_absolute(dir):
		return
	for f in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_rm(dir.path_join(d))
	DirAccess.remove_absolute(dir)
