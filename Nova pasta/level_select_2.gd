extends Control

@onready var click_sound = $AudioStreamPlayer2D
@onready var nivel1_btn = $HBoxContainer/Nivel1_Button
@onready var nivel2_btn = $HBoxContainer/Nivel2_Button2
@onready var nivel3_btn = $HBoxContainer/Nivel3_Button3

var save_path = "user://save_data.cfg"
var unlocked_levels = 2  # 🔓 padrão: níveis 1 e 2 estão liberados

func _ready() -> void:
	# Carrega progresso salvo
	_load_progress()
	_update_level_buttons()
	
	if click_sound and click_sound.playing:
		click_sound.stop()
	
	# 🔗 Conecta os sinais dos botões (igual ao main_menu.gd)
	nivel2_btn.pressed.connect(_on_nivel_2_button_pressed)
	nivel3_btn.pressed.connect(_on_nivel_3_button_pressed)

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
	_show_message("O nível 1 está bloqueado!")

# --- Botão Nível 2 ---
func _on_nivel_2_button_pressed() -> void:
	print("🔵 Clicou no Nível 2!")
	_play_click()
	
	# Tenta carregar a cena de seleção de fases do nível 2
	var caminhos_possiveis = [
		"res://scenes/nivel_2_selecionafase.tscn",
		"res://scenes/nivel2_selecionafase.tscn",
		"res://nivel_2_selecionafase.tscn",
		"res://nivel2_selecionafase.tscn"
	]
	
	var encontrou = false
	for path in caminhos_possiveis:
		if ResourceLoader.exists(path):
			print("✅ Encontrou: ", path)
			get_tree().change_scene_to_file(path)
			encontrou = true
			break
	
	if not encontrou:
		print("❌ Nenhuma cena encontrada! Crie: res://scenes/nivel_2_selecionafase.tscn")
		_show_message("A seleção de fases do Nível 2 ainda não foi criada!")

# --- Botão Nível 3 ---
func _on_nivel_3_button_pressed() -> void:
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
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)
	else:
		_show_message("Essa fase ainda não foi criada!")

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
		unlocked_levels = cfg.get_value("progress", "unlocked_levels", 2)  # 🔓 padrão: 2

# --- Atualiza visual (trancado/desbloqueado) ---
func _update_level_buttons():
	# 🔒 Nível 1 bloqueado
	nivel1_btn.modulate = Color(0.5, 0.5, 0.5)
	if nivel1_btn.has_node("trancado"):
		nivel1_btn.get_node("trancado").visible = true
	
	# 🔓 Nível 2 sempre ativo (igual ao que era o nível 1)
	nivel2_btn.modulate = Color.WHITE
	if nivel2_btn.has_node("trancado"):
		nivel2_btn.get_node("trancado").visible = false
	
	# 🔓/🔒 Nível 3 condicional
	if unlocked_levels >= 3:
		nivel3_btn.modulate = Color.WHITE
		if nivel3_btn.has_node("trancado2"):
			nivel3_btn.get_node("trancado2").visible = false
	else:
		nivel3_btn.modulate = Color(0.5, 0.5, 0.5)
		if nivel3_btn.has_node("trancado2"):
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


func _on_nivel_2_button_2_pressed() -> void:
	pass # Replace with function body.
