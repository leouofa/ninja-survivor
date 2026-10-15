extends Node

@warning_ignore("unused_signal")
signal level_cleared(track_name: String)
@warning_ignore("unused_signal")
signal game_over_triggered()
@warning_ignore("unused_signal")
signal xp_changed(current_xp: int, next_level_xp: int)
@warning_ignore("unused_signal")
signal player_leveled_up(new_level: int)

const SAVE_PATH = "user://ninja_save.json"

var tracks_list: Array[Dictionary] = []
var unlocked_tracks: Array[String] = []
var high_scores: Dictionary = {} # track_name -> { "best_time": float, "cleared": bool, "kills": int }
var current_track_info: Dictionary = {}

var player_kills: int = 0
var player_damage_dealt: float = 0.0
var run_elapsed_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_all_tracks()
	load_save_data()

func load_all_tracks() -> void:
	tracks_list.clear()
	var dir = DirAccess.open("res://tracks")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".mp3"):
				var track_title = file_name.trim_suffix(".mp3")
				var full_path = "res://tracks/" + file_name
				tracks_list.append({
					"title": track_title,
					"file_name": file_name,
					"path": full_path,
				})
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Sort tracks alphabetically for consistent level order
	tracks_list.sort_custom(func(a, b): return a["title"] < b["title"])
	
	# If no save yet, default unlock the first track (e.g. Armageddon / Olympus Mainframe)
	if tracks_list.size() > 0 and unlocked_tracks.is_empty():
		unlocked_tracks.append(tracks_list[0]["title"])

func is_track_unlocked(track_title: String) -> bool:
	return track_title in unlocked_tracks

func get_next_track(current_title: String) -> Dictionary:
	for i in range(tracks_list.size()):
		if tracks_list[i]["title"] == current_title:
			if i + 1 < tracks_list.size():
				return tracks_list[i + 1]
			else:
				return tracks_list[0]
	return tracks_list[0] if not tracks_list.is_empty() else {}

func mark_level_cleared(track_title: String, survival_time: float, kills: int) -> void:
	if not track_title in unlocked_tracks:
		unlocked_tracks.append(track_title)
	
	# Unlock next track in sequence
	var next_track = get_next_track(track_title)
	if not next_track.is_empty() and not next_track["title"] in unlocked_tracks:
		unlocked_tracks.append(next_track["title"])
	
	var current_best = high_scores.get(track_title, {"best_time": 0.0, "cleared": false, "kills": 0})
	high_scores[track_title] = {
		"best_time": max(current_best.get("best_time", 0.0), survival_time),
		"cleared": true,
		"kills": max(current_best.get("kills", 0), kills)
	}
	
	save_game_data()
	level_cleared.emit(track_title)

func record_run_stats(survival_time: float, kills: int) -> void:
	if current_track_info.has("title"):
		var title = current_track_info["title"]
		var current_best = high_scores.get(title, {"best_time": 0.0, "cleared": false, "kills": 0})
		high_scores[title] = {
			"best_time": max(current_best.get("best_time", 0.0), survival_time),
			"cleared": current_best.get("cleared", false),
			"kills": max(current_best.get("kills", 0), kills)
		}
		save_game_data()

func save_game_data() -> void:
	var data = {
		"unlocked_tracks": unlocked_tracks,
		"high_scores": high_scores
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func load_save_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		var parsed = JSON.parse_string(json_text)
		if parsed is Dictionary:
			if parsed.has("unlocked_tracks"):
				for t in parsed["unlocked_tracks"]:
					if not t in unlocked_tracks:
						unlocked_tracks.append(t)
			if parsed.has("high_scores"):
				high_scores = parsed["high_scores"]
	
	# Ensure first track is always unlocked
	if tracks_list.size() > 0 and not tracks_list[0]["title"] in unlocked_tracks:
		unlocked_tracks.append(tracks_list[0]["title"])

func start_run(track_data: Dictionary) -> void:
	current_track_info = track_data
	player_kills = 0
	player_damage_dealt = 0.0
	run_elapsed_time = 0.0
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/GameArena.tscn")

func return_to_level_select() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/LevelSelect.tscn")

func return_to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/menu/MainMenu.tscn")
