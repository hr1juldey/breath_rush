extends ParallaxLayer

@onready var sky_bad = $Sprite_SkyBad
@onready var sky_ok = $Sprite_SkyOk
@onready var sky_clear = $Sprite_SkyClear

var current_sky_type = "bad"
var transitioning = false
var transition_duration = 2.0

func _ready():
	# Initialize sky sprites
	if sky_bad:
		sky_bad.modulate.a = 1.0
	if sky_ok:
		sky_ok.modulate.a = 0.0
	if sky_clear:
		sky_clear.modulate.a = 0.0

func set_sky_type(target_sky: String) -> void:
	if target_sky == current_sky_type or transitioning:
		return

	transitioning = true

	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)

	# Fade out current sky
	match current_sky_type:
		"bad":
			tween.tween_property(sky_bad, "modulate:a", 0.0, transition_duration)
		"ok":
			tween.tween_property(sky_ok, "modulate:a", 0.0, transition_duration)
		"clear":
			tween.tween_property(sky_clear, "modulate:a", 0.0, transition_duration)

	# Fade in target sky
	match target_sky:
		"bad":
			tween.tween_property(sky_bad, "modulate:a", 1.0, transition_duration)
		"ok":
			tween.tween_property(sky_ok, "modulate:a", 1.0, transition_duration)
		"clear":
			tween.tween_property(sky_clear, "modulate:a", 1.0, transition_duration)

	await tween.finished
	current_sky_type = target_sky
	transitioning = false

func get_current_sky() -> String:
	return current_sky_type

func apply_smog_overlay(intensity: float) -> void:
	var target_alpha = clamp((intensity - 50.0) / 450.0, 0.0, 0.9)

	match current_sky_type:
		"bad":
			if sky_bad:
				sky_bad.modulate = Color(1.0, 0.8, 0.6, 1.0).lerp(Color(1.0, 1.0, 1.0, 1.0), 1.0 - target_alpha)
		"ok":
			if sky_ok:
				sky_ok.modulate = Color(1.0, 1.0, 1.0, 1.0)
		"clear":
			if sky_clear:
				sky_clear.modulate = Color(1.0, 1.0, 1.0, 1.0)
