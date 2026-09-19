extends Control


@export_category("Recording")
@export var recording: bool = true


@export_category("Timer")
@export var start_time_seconds: float = 0.0


@onready var rec_label: Label = $RECLabel
@onready var time_label: Label = $TimeLabel


var elapsed_time: float = 0.0
var blink_timer: float = 0.0
var rec_visible: bool = true


func _ready() -> void:
	elapsed_time = start_time_seconds

	rec_label.text = "● REC"

	time_label.text = format_time(
		elapsed_time
	)


func _process(delta: float) -> void:
	if not recording:
		return

	elapsed_time += delta

	time_label.text = format_time(
		elapsed_time
	)

	update_rec_indicator(delta)


func format_time(seconds: float) -> String:
	var total_seconds: int = int(seconds)

	var hours: int = total_seconds / 3600

	var minutes: int = (
		total_seconds % 3600
	) / 60

	var secs: int = (
		total_seconds % 60
	)

	return "%02d:%02d:%02d" % [
		hours,
		minutes,
		secs
	]


func update_rec_indicator(delta: float) -> void:
	blink_timer += delta

	if blink_timer >= 0.6:
		blink_timer = 0.0

		rec_visible = not rec_visible

		if rec_visible:
			rec_label.text = "● REC"
		else:
			rec_label.text = "  REC"
