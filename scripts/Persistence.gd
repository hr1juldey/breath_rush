class_name Persistence

extends Node

const SAVE_PATH = "user://game_state.json"

func save_game_state(state: Dictionary) -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open file for writing: ", SAVE_PATH)
		return false

	var json_string = JSON.stringify(state)
	file.store_string(json_string)
	return true

func load_game_state() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return get_default_state()

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("Could not open file for reading: ", SAVE_PATH)
		return get_default_state()

	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)

	if error != OK:
		push_error("JSON parse error: ", json.get_error_message())
		return get_default_state()

	return json.data as Dictionary

func get_default_state() -> Dictionary:
	return {
		"trees": [],
		"coins_total": 0,
		"runs_played": 0,
		"best_score": 0,
		"map_aqi_modifiers": {
			"default": 0
		}
	}

func add_tree(tree_data: Dictionary) -> void:
	var state = load_game_state()
	state["trees"].append(tree_data)
	save_game_state(state)

func get_trees() -> Array:
	var state = load_game_state()
	return state.get("trees", [])

func update_coins(amount: int) -> void:
	var state = load_game_state()
	state["coins_total"] = state.get("coins_total", 0) + amount
	state["runs_played"] = state.get("runs_played", 0) + 1
	save_game_state(state)

func update_best_score(score: int) -> void:
	var state = load_game_state()
	if score > state.get("best_score", 0):
		state["best_score"] = score
	save_game_state(state)

func increment_tree_stage(tree_id: String) -> void:
	var state = load_game_state()
	var trees = state.get("trees", [])

	for tree in trees:
		if tree.get("id") == tree_id:
			tree["stage"] = min(tree.get("stage", 0) + 1, 5)
			break

	save_game_state(state)

func delete_tree(tree_id: String) -> void:
	var state = load_game_state()
	var trees = state.get("trees", [])

	trees = trees.filter(func(t): return t.get("id") != tree_id)
	state["trees"] = trees
	save_game_state(state)

func get_total_coins() -> int:
	var state = load_game_state()
	return state.get("coins_total", 0)

func get_runs_played() -> int:
	var state = load_game_state()
	return state.get("runs_played", 0)

func get_best_score() -> int:
	var state = load_game_state()
	return state.get("best_score", 0)
