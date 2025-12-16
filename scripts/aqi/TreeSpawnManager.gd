class_name TreeSpawnManager
extends Node

"""
Manages tree spawn probabilities based on saplings collected
Increases tree spawn chance as player collects saplings
"""

signal sapling_collected(total: int)
signal spawn_probability_changed(probs: Dictionary)

var saplings_collected: int = 0

# Base probabilities (per spawn attempt in FrontLayerSpawner)
@export var base_tree1_chance: float = 0.15  # 15% tree_1
@export var base_tree2_chance: float = 0.08  # 8% tree_2
@export var base_tree3_chance: float = 0.04  # 4% tree_3

# Boost per sapling collected
@export var sapling_boost: float = 0.03  # +3% per sapling

func _ready():
	add_to_group("tree_spawn_manager")

func collect_sapling():
	saplings_collected += 1
	sapling_collected.emit(saplings_collected)
	spawn_probability_changed.emit(get_spawn_probabilities())
	print("[TreeSpawnManager] Sapling collected! Total: %d" % saplings_collected)

func get_spawn_probabilities() -> Dictionary:
	var boost = saplings_collected * sapling_boost
	return {
		"tree_1": min(base_tree1_chance + boost, 0.50),
		"tree_2": min(base_tree2_chance + boost * 0.75, 0.35),
		"tree_3": min(base_tree3_chance + boost * 0.5, 0.25)
	}

func should_spawn_tree_type() -> String:
	"""Called by FrontLayerSpawner to determine what to spawn"""
	var probs = get_spawn_probabilities()
	var roll = randf()

	var cumulative = 0.0
	for tree_type in ["tree_3", "tree_2", "tree_1"]:  # Best first
		cumulative += probs[tree_type]
		if roll < cumulative:
			return tree_type

	return ""  # No tree (spawn other element)

func get_saplings_collected() -> int:
	return saplings_collected
