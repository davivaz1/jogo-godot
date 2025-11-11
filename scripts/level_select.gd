extends Control

@onready var click_sound = $AudioStreamPlayer2D
@onready var nivel1_btn = $HBoxContainer/Nivel1_Button
@onready var nivel2_btn = $HBoxContainer/Nivel2_Button2
@onready var nivel3_btn = $HBoxContainer/Nivel3_Button3

var save_path = "user://save_data.cfg"
var unlocked_levels = 1 # padrão: apenas o nível 1 está liberado

func _ready() -> void:
	# Carrega progresso salvo
	_load_progress()
	_update_level_buttons()

	if click_sound.playing:
		click_sound.stop()

# --- Botão Voltar ---
func _on_voltar_button_pressed() -> void:
	_play_click()
	if ResourceLoader.exists("res://scenes/main_menu.tscn"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		_show_message("Menu principal não encontrado!")

# --- Botão Nível 1 ---
func _on_nivel_1_button_pressed() -> void:
	_play_click()
	_load_level(1)
	
func _on_nivel_2_button_2_pressed() -> void:
	_play_click()
	if unlocked_levels >= 2:
		_load_level(2)
	else:
		_show_message("Complete o Nível 1 para desbloquear!")

func _on_nivel_3_button_3_pressed() -> void:
	_play_click()
	if unlocked_levels >= 3:
		_load_level(3)
	else:
		_show_message("Complete o Nível 2 para desbloquear!")

# --- Abrir Configurações ---
func _on_button_config_pressed():
	_play_click()
	_show_volume_popup()

# --- Utilidades ---
func _load_level(num):
	var path = "res://scenes/nivel_%d_selecionafase.tscn" % num
	get_tree().change_scene_to_file(path)

func _play_click():
	if click_sound and click_sound.stream:
		click_sound.play()

func _show_message(texto: String):
	var popup = ConfirmationDialog.new()
	popup.title = "Informação"
	popup.dialog_text = texto
	add_child(popup)
	popup.popup_centered()

# --- Sistema de progresso ---
func _save_progress(level_completed: int):
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "unlocked_levels", level_completed)
	cfg.save(save_path)
	unlocked_levels = level_completed
	_update_level_buttons()

func _load_progress():
	var cfg = ConfigFile.new()
	var err = cfg.load(save_path)
	if err == OK:
		unlocked_levels = cfg.get_value("progress", "unlocked_levels", 1)

# --- Atualiza visual (trancado/desbloqueado) ---
func _update_level_buttons():
	# Nível 1 sempre ativo
	nivel1_btn.modulate = Color.WHITE

	# Nível 2
	if unlocked_levels >= 2:
		nivel2_btn.modulate = Color.WHITE
		nivel2_btn.get_node("trancado").visible = false
	else:
		nivel2_btn.modulate = Color(0.5, 0.5, 0.5)
		nivel2_btn.get_node("trancado").visible = true

	# Nível 3
	if unlocked_levels >= 3:
		nivel3_btn.modulate = Color.WHITE
		nivel3_btn.get_node("trancado2").visible = false
	else:
		nivel3_btn.modulate = Color(0.5, 0.5, 0.5)
		nivel3_btn.get_node("trancado2").visible = true

func _show_volume_popup():
	# Cria um popup simples com um controle de volume
	var popup = Window.new()
	popup.title = "Configurações de Volume"
	popup.size = Vector2(400, 120)
	add_child(popup)
	popup.popup_centered()

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(vbox)

	var label = Label.new()
	label.text = "Ajuste o volume geral:"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = db_to_linear(AudioServer.get_bus_volume_db(0))
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(slider)

	var close_btn = Button.new()
	close_btn.text = "Fechar"
	vbox.add_child(close_btn)

	slider.connect("value_changed", Callable(self, "_on_volume_changed"))
	close_btn.connect("pressed", Callable(popup, "queue_free"))

func _on_volume_changed(value):
	# Converter valor linear para decibéis
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(0, db)
