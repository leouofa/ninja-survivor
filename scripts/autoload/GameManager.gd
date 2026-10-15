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

const MANIFEST_PATH = "res://assets/data/tracks_amplitude_manifest.json"
var amplitude_manifest: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_amplitude_manifest()
	load_all_tracks()
	load_save_data()

func load_amplitude_manifest() -> void:
	amplitude_manifest.clear()
	if FileAccess.file_exists(MANIFEST_PATH):
		var file = FileAccess.open(MANIFEST_PATH, FileAccess.READ)
		if file:
			var text = file.get_as_text()
			var parsed = JSON.parse_string(text)
			if parsed is Dictionary:
				amplitude_manifest = parsed

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
				var meta = amplitude_manifest.get(track_title, null)
				if meta == null:
					meta = _generate_fallback_amplitude_metadata(track_title, full_path)
				
				tracks_list.append({
					"title": track_title,
					"file_name": file_name,
					"path": full_path,
					"seed": int(meta.get("seed", hash(track_title) & 0x7FFFFFFF)),
					"rms_db": float(meta.get("rms_db", -16.0)),
					"max_db": float(meta.get("max_db", 0.0)),
					"dynamic_range_db": float(meta.get("dynamic_range_db", 16.0)),
					"normalized_energy": float(meta.get("normalized_energy", 0.5)),
					"height_scale": float(meta.get("height_scale", 1.9)),
					"voronoi_scale": float(meta.get("voronoi_scale", 0.05)),
					"palette_name": str(meta.get("palette_name", "Neon Cyan & Magenta")),
					"primary_color": meta.get("primary_color", [0.0, 0.95, 1.0, 1.0]),
					"secondary_color": meta.get("secondary_color", [1.0, 0.08, 0.58, 1.0]),
					"ambient_color": meta.get("ambient_color", [0.03, 0.02, 0.08, 1.0]),
				})
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# Sort tracks alphabetically for consistent level order
	tracks_list.sort_custom(func(a, b): return a["title"] < b["title"])

func _generate_fallback_amplitude_metadata(title: String, path: String) -> Dictionary:
	var h = hash(title) & 0x7FFFFFFF
	var stream = load(path)
	var stream_len = stream.get_length() if stream else 180.0
	var seed_val = (h ^ int(stream_len * 1000)) & 0x7FFFFFFF
	return {
		"title": title,
		"seed": seed_val,
		"rms_db": -16.0,
		"max_db": -0.5,
		"dynamic_range_db": 15.5,
		"normalized_energy": 0.5,
		"height_scale": 1.85,
		"voronoi_scale": 0.05,
		"palette_name": "Fallback Cyber",
		"primary_color": [0.0, 0.95, 1.0, 1.0],
		"secondary_color": [1.0, 0.08, 0.58, 1.0],
		"ambient_color": [0.03, 0.02, 0.08, 1.0],
	}

func is_track_unlocked(track_title: String) -> bool:
	return track_title in unlocked_tracks

func is_final_track(track_title: String) -> bool:
	if tracks_list.is_empty():
		return false
	return tracks_list.back()["title"] == track_title

func is_game_completed() -> bool:
	if tracks_list.is_empty():
		return false
	var final_title = tracks_list.back()["title"]
	var record = high_scores.get(final_title, {})
	return record is Dictionary and record.get("cleared", false) == true

func get_next_track(current_title: String) -> Dictionary:
	for i in range(tracks_list.size()):
		if tracks_list[i]["title"] == current_title:
			if i + 1 < tracks_list.size():
				return tracks_list[i + 1]
			else:
				return tracks_list[0]
	return tracks_list[0] if not tracks_list.is_empty() else {}

func record_run_result(track_title: String, survival_time: float, kills: int, cleared: bool) -> Dictionary:
	var had_record = high_scores.has(track_title)
	var current_best = high_scores.get(track_title, {"best_time": 0.0, "cleared": false, "kills": 0})
	var prev_kills = int(current_best.get("kills", 0))
	var prev_time = float(current_best.get("best_time", 0.0))
	var prev_cleared = bool(current_best.get("cleared", false))
	
	var is_first = not had_record
	var is_new_record = had_record and (kills > prev_kills)
	var is_tie = had_record and (kills == prev_kills)
	var diff = kills - prev_kills
	
	if cleared:
		if not track_title in unlocked_tracks:
			unlocked_tracks.append(track_title)
		
		# Unlock next track in sequence if not at the final track
		if not is_final_track(track_title):
			var next_track = get_next_track(track_title)
			if not next_track.is_empty() and not next_track["title"] in unlocked_tracks:
				unlocked_tracks.append(next_track["title"])
	
	high_scores[track_title] = {
		"best_time": max(prev_time, survival_time),
		"cleared": prev_cleared or cleared,
		"kills": max(prev_kills, kills)
	}
	
	save_game_data()
	
	if cleared:
		level_cleared.emit(track_title)
	
	return {
		"is_first_record": is_first,
		"is_new_record": is_new_record,
		"is_tie": is_tie,
		"diff": diff,
		"previous_kills": prev_kills,
		"current_kills": kills,
		"best_kills": high_scores[track_title]["kills"],
		"cleared": high_scores[track_title]["cleared"],
		"best_time": high_scores[track_title]["best_time"]
	}

func mark_level_cleared(track_title: String, survival_time: float, kills: int) -> Dictionary:
	return record_run_result(track_title, survival_time, kills, true)

func record_run_stats(survival_time: float, kills: int) -> Dictionary:
	var title = current_track_info.get("title", "")
	if title != "":
		return record_run_result(title, survival_time, kills, false)
	return {
		"is_first_record": false,
		"is_new_record": false,
		"is_tie": false,
		"diff": 0,
		"previous_kills": 0,
		"current_kills": kills,
		"best_kills": kills,
		"cleared": false,
		"best_time": survival_time
	}

func get_high_scores_sorted() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for title in high_scores.keys():
		var data = high_scores[title]
		if data is Dictionary:
			result.append({
				"title": str(title),
				"kills": int(data.get("kills", 0)),
				"best_time": float(data.get("best_time", 0.0)),
				"cleared": bool(data.get("cleared", false))
			})
	result.sort_custom(func(a, b):
		if a["kills"] != b["kills"]:
			return a["kills"] > b["kills"]
		return a["best_time"] > b["best_time"]
	)
	return result

func get_total_kills() -> int:
	var total: int = 0
	for title in high_scores.keys():
		var data = high_scores[title]
		if data is Dictionary:
			total += int(data.get("kills", 0))
	return total

func has_beaten_any_level() -> bool:
	for title in high_scores.keys():
		var data = high_scores[title]
		if data is Dictionary and data.get("cleared", false) == true:
			return true
	return false

func reset_game_data() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	high_scores.clear()
	unlocked_tracks.clear()
	if tracks_list.size() > 0:
		unlocked_tracks.append(tracks_list[0]["title"])
	player_kills = 0
	player_damage_dealt = 0.0
	run_elapsed_time = 0.0

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
		if tracks_list.size() > 0 and not tracks_list[0]["title"] in unlocked_tracks:
			unlocked_tracks.append(tracks_list[0]["title"])
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
