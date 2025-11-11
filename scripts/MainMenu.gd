extends Control

# Referências automáticas aos botões e áudio
@onready var btn_jogar = $VBoxContainer/Button_Jogar
@onready var btn_creditos = $VBoxContainer/Button_Creditos
@onready var btn_sair = $VBoxContainer/Button_Sair
@onready var btn_config = $Button_Config
@onready var click_sound = $AudioStreamPlayer

func _ready():
	# Conectar os sinais de clique
	btn_jogar.pressed.connect(_on_jogar_pressed)
	btn_creditos.pressed.connect(_on_creditos_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)
	btn_config.pressed.connect(_on_config_pressed)
	# Garantir que o áudio não cause erro se estiver vazio
	if click_sound.stream == null:
		print("⚠️ Nenhum som de clique carregado — insira um .ogg em AudioStreamPlayer")

# --- Funções de cada botão ---

func _on_jogar_pressed():
	_play_click()
	# Troca para a tela de seleção de níveis
	if ResourceLoader.exists("res://scenes/level_select.tscn"):
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")
	else:
		_show_message("Tela de seleção de níveis ainda não criada.")

func _on_creditos_pressed():
	_play_click()
	_show_credits_popup()

func _show_credits_popup():
	var popup = Window.new()
	popup.title = ""
	popup.size = Vector2(600, 400)
	popup.transparent = true
	popup.borderless = true
	add_child(popup)

	# Centraliza o popup depois de adicionar à árvore
	await get_tree().process_frame
	popup.popup_centered()

	# Fundo
	var bg = TextureRect.new()
	bg.texture = load("res://assets/popup_creditos.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	popup.add_child(bg)

	# Container principal centralizado
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(center)

	# Caixa vertical com tamanho fixo dentro do centro
	var vbox = VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(500, 300)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	# Scroll container para o texto
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	# Texto dos créditos
	var label = Label.new()
	label.text = "Desenvolvido por:\n\nAdrian Cauã\nDavi Nogueira\nJoão Pedro Iank\nMatheus Eduardo\nPedro Perioto\nPedro Vargas\n\nEngenharia de Software 01"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(label)

	# Container do botão com label sobreposto
	var button_container = CenterContainer.new()
	button_container.custom_minimum_size = Vector2(180, 70)
	vbox.add_child(button_container)

	# Botão fechar (imagem PNG)
	var close_btn = TextureButton.new()
	close_btn.texture_normal = load("res://assets/btn.png")
	close_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_btn.custom_minimum_size = Vector2(180, 70)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button_container.add_child(close_btn)

	# Label "FECHAR" por cima do botão (filho do próprio botão)
	var label_fechar = Label.new()
	label_fechar.text = "FECHAR"
	label_fechar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_fechar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label_fechar.add_theme_font_size_override("font_size", 20)
	label_fechar.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	label_fechar.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Ignorar eventos do mouse para que o clique atinja o botão
	label_fechar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Ajuste fino: suba alguns pixels (experimente -6, -8, -12 até ficar perfeito)
	label_fechar.offset_top = -20
	# se precisar mover horizontalmente:
	# label_fechar.offset_left = 0
	# label_fechar.offset_right = 0

	# Agora ANEXE ao botão, não ao container
	close_btn.add_child(label_fechar)

	close_btn.pressed.connect(func(): popup.queue_free())

func _on_sair_pressed():
	_play_click()
	get_tree().quit()

func _on_config_pressed():
	_play_click()
	_show_volume_popup()

# --- Funções auxiliares ---

func _play_click():
	if click_sound.stream:
		click_sound.play()

func _show_message(texto: String):
	var popup = ConfirmationDialog.new()
	popup.title = "Informação"
	popup.dialog_text = texto
	add_child(popup)
	popup.popup_centered()

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

func _on_button_creditos_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
	
