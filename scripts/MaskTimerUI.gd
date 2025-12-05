extends Node
"""
Mask Timer UI Manager

Manages mask timer display:
- Updates countdown text (number only - asset has "sec remaining.." text)
- Shows/hides timer container based on mask status
- Pulsing effect when time is critical (preserves original colors)
"""

# References
var mask_timer_container: Control
var mask_timer_label: Label
var player_ref: Node

# Pulsing constants
const CRITICAL_THRESHOLD = 10.0      # Pulsing starts below this
const PULSE_PERIOD = 1.5             # Pulsing period (seconds)
const PULSE_MIN_ALPHA = 0.6          # Minimum alpha during pulse

func _ready():
	print("[MaskTimerUI] Initializing...")

	# Find references
	var parent = get_parent()
	if parent:
		mask_timer_container = parent.find_child("MaskTimer")
		if mask_timer_container:
			mask_timer_label = mask_timer_container.find_child("TimerLabel")
			print("[MaskTimerUI] MaskTimer container found")
			print("[MaskTimerUI] Label found: ", mask_timer_label != null)

	print("[MaskTimerUI] Initialization complete (preserving original asset colors)")

func setup_player_reference(player: Node) -> void:
	"""Setup player reference for mask timer updates"""
	print("[MaskTimerUI] setup_player_reference called with: ", player)
	player_ref = player

func _process(delta):
	if player_ref and mask_timer_label:
		update_mask_timer_display()

func update_mask_timer_display() -> void:
	"""Update mask timer text - only show the number (asset has 'sec remaining..' text)"""
	# Get mask time from component
	var mask_time = 0.0
	if player_ref and player_ref.mask_component:
		mask_time = player_ref.mask_component.get_mask_time()

	if mask_time > 0:
		var seconds = int(ceil(mask_time))
		# Only show number - background image has "sec remaining.." text
		mask_timer_label.text = "%02d" % seconds

		if mask_timer_container and not mask_timer_container.visible:
			mask_timer_container.show()
	else:
		if mask_timer_container and mask_timer_container.visible:
			mask_timer_container.hide()

func _physics_process(delta):
	"""Handle pulsing animation when time is critical"""
	if player_ref and mask_timer_container:
		# Get mask time from component
		var time_remaining = 0.0
		if player_ref.mask_component:
			time_remaining = player_ref.mask_component.get_mask_time()

		if time_remaining > 0 and time_remaining <= CRITICAL_THRESHOLD:
			# Pulse when critical (fade in/out effect)
			var time = Time.get_ticks_msec() / 1000.0
			var pulse = (sin(time * 2.0 * PI / PULSE_PERIOD) + 1.0) / 2.0
			# Map from 0-1 to PULSE_MIN_ALPHA-1.0
			var alpha = PULSE_MIN_ALPHA + pulse * (1.0 - PULSE_MIN_ALPHA)
			mask_timer_container.modulate.a = alpha
		else:
			# Normal alpha when not critical
			mask_timer_container.modulate.a = 1.0
