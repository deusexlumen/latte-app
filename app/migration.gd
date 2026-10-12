# PURPOSE: Übernimmt beim ersten Start Spielstände der Einzel-Apps (LOBBY-LOOP, Dame) in den Datenordner der App. Kopiert nur, löscht nie.
# ARCHITECTURE: autoload
# DEPENDENCIES: none
# PIPELINE: runtime, test
# LAST_VALIDATED: 2026-10-12
extends Node

## Alte App-Ordner unter app_userdata und was daraus übernommen wird. Ordner werden rekursiv kopiert.
const SOURCES := {
	"LOBBY-LOOP": ["savegame.json", "gm_proxy.cfg", "widerlegung_bibliothek"],
	"Dame": ["profile.json", "settings.json", "stats.json", "save.dat"],
}
const MARKER := "migration.json"

## Ergebnis des letzten Laufs, z. B. für einen Hinweis im Flur.
var report: Array = []


func _ready() -> void:
	# Läuft als erster Autoload, damit DAMEs App und Lobby-Loops GameState schon die übernommenen Dateien lesen.
	# Im Browser gibt es keine fremden App-Ordner (jede Origin hat ihren eigenen Speicher).
	if OS.has_feature("web"):
		return
	report = migrate(OS.get_user_data_dir(), OS.get_user_data_dir().get_base_dir())


## Kopiert fehlende Dateien aus `<appdata_root>/<Alt-App>/` nach `user_dir`. Vorhandenes wird nie überschrieben.
## Läuft nur einmal (Markerdatei). Liefert die Liste der übernommenen Einträge.
static func migrate(user_dir: String, appdata_root: String) -> Array:
	var marker := user_dir.path_join(MARKER)
	if FileAccess.file_exists(marker):
		return []
	var done := []
	for app in SOURCES:
		var old_dir: String = appdata_root.path_join(app)
		if old_dir == user_dir or not DirAccess.dir_exists_absolute(old_dir):
			continue
		for entry in SOURCES[app]:
			var src: String = old_dir.path_join(entry)
			var dst: String = user_dir.path_join(entry)
			if FileAccess.file_exists(src) and not FileAccess.file_exists(dst):
				DirAccess.make_dir_recursive_absolute(user_dir)
				if DirAccess.copy_absolute(src, dst) == OK:
					done.append("%s/%s" % [app, entry])
			elif DirAccess.dir_exists_absolute(src) and not DirAccess.dir_exists_absolute(dst):
				if _copy_dir(src, dst):
					done.append("%s/%s/" % [app, entry])
	DirAccess.make_dir_recursive_absolute(user_dir)
	var f := FileAccess.open(marker, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify({"migrated": done, "at": Time.get_datetime_string_from_system()}, " "))
	return done


static func _copy_dir(src: String, dst: String) -> bool:
	DirAccess.make_dir_recursive_absolute(dst)
	for f in DirAccess.get_files_at(src):
		if DirAccess.copy_absolute(src.path_join(f), dst.path_join(f)) != OK:
			return false
	for d in DirAccess.get_directories_at(src):
		if not _copy_dir(src.path_join(d), dst.path_join(d)):
			return false
	return true
