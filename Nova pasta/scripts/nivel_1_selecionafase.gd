extends Control

@onready var click_sound = $AudioStreamPlayer2D
@onready var voltar_button = $voltar_button
@onready var fase1_button = $Fase1_Button
@onready var fase2_button = $Fase2_Button
@onready var fase3_button = $Fase3_Button

var unlocked_stage = 1  # padrão (salvo será lido no _ready)

func _ready():
	_load_progress()
	_update_stage_buttons()

	# Conectar sinais
	fase1_button.pressed.connect(_on_fase1_pressed)
	fase2_button.pressed.connect(_on_fase2_pressed)
	fase3_button.pressed.connect(_on_fase3_pressed)

func _play_click():
	if click_sound and click_sound.stream:
		click_sound.play()

# --- Lógica de progresso ---
func _load_progress():
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"
	if cfg.load(save_path) == OK:
		unlocked_stage = cfg.get_value("level1", "unlocked_stage", 1)
	else:
		unlocked_stage = 1

func _save_progress(next_stage: int):
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"
	var err = cfg.load(save_path)
	if err != OK:
		cfg.set_value("level1", "unlocked_stage", next_stage)
	else:
		var current = cfg.get_value("level1", "unlocked_stage", 1)
		if next_stage > current:
			cfg.set_value("level1", "unlocked_stage", next_stage)
	cfg.save(save_path)

# --- Atualizar aparência dos botões ---
func _update_stage_buttons():
	fase1_button.disabled = false
	fase2_button.disabled = unlocked_stage < 2
	fase3_button.disabled = unlocked_stage < 3

func _on_fase1_pressed():
	_play_click()
	get_tree().change_scene_to_file("res://scenes/fase_1_1.tscn")

func _on_fase2_pressed():
	if unlocked_stage >= 2:
		_play_click()
		get_tree().change_scene_to_file("res://scenes/fase_1_2.tscn")

func _on_fase3_pressed():
	if unlocked_stage >= 3:
		_play_click()
		get_tree().change_scene_to_file("res://scenes/fase_1_3.tscn")

func _on_voltar_button_pressed():
	_play_click()
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")
