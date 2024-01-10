extends Control

@onready var credits = $Credits
@onready var credits_label = $Credits/Credits

@onready var fov_label: Label = $Settings/FOV/Label2
@onready var sens_label: Label  = $Settings/Sensitivity/Label2
@onready var volume_label: Label  = $Settings/Volume/Label2
@onready var settings: Control = $Settings

# Called when the node enters the scene tree for the first time.
func _ready():
	var file = FileAccess.open("res://attributions.txt", FileAccess.READ)
	credits_label.text = file.get_as_text()
	fov_label.text = str(GlobalSettings.FOV)
	sens_label.text = str(GlobalSettings.SENSITIVITY)
	volume_label.text = str(GlobalSettings.VOLUME)

func _on_close_pressed():
	credits.visible = false


func _on_credits_pressed():
	credits.visible = true


func _on_play_pressed():
	get_tree().change_scene_to_file("res://level/level.tscn")


func _on_fov_slider_value_changed(value: float):
	if fov_label:
		fov_label.text = str(value)
		GlobalSettings.set_FOV(value)
		GlobalSettings.save_game()


func _on_sensitivity_slider_value_changed(value: float):
	if sens_label:
		sens_label.text = str(value)
		GlobalSettings.set_Sensitivity(value)
		GlobalSettings.save_game()


func _on_volume_slider_value_changed(value: float):
	if volume_label:
		volume_label.text = str(value)
		GlobalSettings.set_Volume(value)
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),
			0 - (1 - value) * 10);
		AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), value == 0)
		GlobalSettings.save_game()


func _on_button_pressed():
	settings.visible = false
	$Title.visible = true
	$Buttons.visible = true


func _on_settings_pressed():
	settings.visible = true
	$Title.visible = false
	$Buttons.visible = false


func _on_fov_slider_ready():
	$Settings/FOV/FOVSlider.value = GlobalSettings.FOV


func _on_sensitivity_slider_ready():
	$Settings/Sensitivity/SensitivitySlider.value = GlobalSettings.SENSITIVITY


func _on_volume_slider_ready():
	$Settings/Volume/VolumeSlider.value = GlobalSettings.VOLUME
