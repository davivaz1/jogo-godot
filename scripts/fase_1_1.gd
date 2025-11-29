extends Control

@onready var explicacao_container = $explicacao_container
@onready var exercicio_container = $exercicio_container
@onready var label_vitoria = $label_vitoria

@onready var audio_click = $AudioStreamPlayer2D
@onready var narracao = $Narracao     # <--- Narrador que você deve criar na cena

@onready var button_restart = $exercicio_container/button_restart
@onready var feedback_label = $exercicio_container/feedback_label
@onready var voltar_button = $voltar_button

var selecionados = []
var corretos = ["item_computador", "item_celular"]

# ------- ÁUDIOS -------
var audio_explicacao = preload("res://audio/explicacao_1_1_audio.ogg")
var audio_fase = preload("res://audio/fase_1_1_audio.ogg")

func _ready():
	# Tela inicial
	explicacao_container.visible = true
	exercicio_container.visible = false
	label_vitoria.visible = false
	button_restart.visible = false

	# ▶️ Toca áudio da explicação
	_tocar_narracao(audio_explicacao)

	# Botão voltar
	if voltar_button:
		voltar_button.pressed.connect(_on_voltar_button_pressed)

	# Botão continuar da explicação
	explicacao_container.get_node("button_continuar").pressed.connect(func():
		_play_click()
		_iniciar_exercicio()
	)

	# Conectar cliques dos itens
	for nome in ["item_computador", "item_celular", "item_maca"]:
		var item = $exercicio_container/itens_container.get_node(nome)
		item.pressed.connect(func(): _on_item_pressed(nome))

	$exercicio_container/button_continuar.pressed.connect(func():
		_play_click()
		_finalizar_fase()
	)
	$exercicio_container/button_continuar.visible = false

	# Botão restart
	button_restart.pressed.connect(func():
		_play_click()
		_reiniciar_exercicio()
	)

# ------------------ ÁUDIO ------------------

func _play_click():
	if audio_click.stream:
		audio_click.play()

func _tocar_narracao(stream):
	if narracao:
		narracao.stop()
		narracao.stream = stream
		narracao.play()

# ------------------ EXERCÍCIO ------------------

func _iniciar_exercicio():
	explicacao_container.visible = false
	exercicio_container.visible = true

	feedback_label.visible = false
	button_restart.visible = false
	$exercicio_container/button_continuar.visible = false
	selecionados.clear()

	# ▶️ Toca áudio da fase
	_tocar_narracao(audio_fase)

func _on_item_pressed(nome_item):
	if nome_item in selecionados:
		return

	selecionados.append(nome_item)
	_play_click()

	if selecionados.size() == 2:
		_verificar_resposta()

func _verificar_resposta():
	var acertos = 0
	for item in selecionados:
		if item in corretos:
			acertos += 1

	feedback_label.visible = true

	if acertos == 2:
		feedback_label.text = "Correto! 💡"
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
		$exercicio_container/button_continuar.visible = true
		button_restart.visible = false
	else:
		feedback_label.text = "Tente novamente!"
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button_restart.visible = true
		$exercicio_container/button_continuar.visible = false
		selecionados.clear()

func _reiniciar_exercicio():
	feedback_label.visible = false
	button_restart.visible = false
	$exercicio_container/button_continuar.visible = false
	selecionados.clear()

	# Recomeça o áudio do exercício
	_tocar_narracao(audio_fase)

# ------------------ FINAL ------------------

func _finalizar_fase():
	exercicio_container.visible = false
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE!"

	await get_tree().create_timer(1.2).timeout
	_save_progress_and_return(2)

func _save_progress_and_return(next_stage):
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"

	var err = cfg.load(save_path)
	if err != OK:
		cfg.set_value("level1", "unlocked_stage", next_stage)
	else:
		var unlocked = cfg.get_value("level1", "unlocked_stage", 1)
		if next_stage > unlocked:
			cfg.set_value("level1", "unlocked_stage", next_stage)

	cfg.save(save_path)
	get_tree().change_scene_to_file("res://scenes/nivel_1_selecionafase.tscn")

# ------------------ VOLTAR ------------------

func _on_voltar_button_pressed():
	_play_click()
	get_tree().change_scene_to_file("res://scenes/nivel_1_selecionafase.tscn")
