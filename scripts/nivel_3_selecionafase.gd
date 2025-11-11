extends Control

@onready var audio = $AudioStreamPlayer2D
@onready var feedback_label = $feedback_label

var unlocked_stage = 1  # por padrão só a primeira fase está liberada

func _ready():
	_load_progress()

	# Conecta os botões
	$button_fase_1.pressed.connect(func():
		_play_click()
		_abrir_fase(1)
	)
	$button_fase_2.pressed.connect(func():
		_play_click()
		_abrir_fase(2)
	)
	$button_fase_3.pressed.connect(func():
		_play_click()
		_abrir_fase(3)
	)
	$button_voltar.pressed.connect(func():
		_play_click()
		_voltar_menu_niveis()
	)

func _play_click():
	if audio and audio.stream:
		audio.play()

func _abrir_fase(numero: int):
	if numero <= unlocked_stage:
		match numero:
			1:
				get_tree().change_scene_to_file("res://scenes/fase_3_1.tscn")
			2:
				get_tree().change_scene_to_file("res://scenes/fase_3_2.tscn")
			3:
				get_tree().change_scene_to_file("res://scenes/fase_3_3.tscn")
	else:
		feedback_label.text = "Esta fase ainda não foi desbloqueada!"
		feedback_label.visible = true
		await get_tree().create_timer(1.5).timeout
		feedback_label.visible = false

func _voltar_menu_niveis():
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _load_progress():
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"
	var err = cfg.load(save_path)
	if err == OK:
		unlocked_stage = cfg.get_value("level3", "unlocked_stage", 1)
