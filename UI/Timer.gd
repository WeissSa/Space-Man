extends Label

var time: float = 0
@export var timer_on: bool = false



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if timer_on:
		time += delta
	var seconds: String = str(time)
	text = seconds.substr(0, 3 + seconds.find('.'))
