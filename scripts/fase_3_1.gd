extends Control

@onready var explicacao_inicial_container = $explicacao_inicial_container
@onready var explicacao_etapa_container = $explicacao_etapa_container
@onready var exercicio_container = $exercicio_container
@onready var seta_1 = $exercicio_container/seta_1
@onready var seta_2 = $exercicio_container/seta_2
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D
@onready var narracao = $Narracao  # <-- Áudio de narração
@onready var tipo_energia_img = $exercicio_container/tipo_energia_img

var etapa_atual = 0
const TOTAL_ETAPAS = 3
var selecionados = []

# Áudios da fase 3_1
var audio_explicacao_inicial = preload("res://audio/explicacao_3_1_audio.ogg")

var audios_explicacao_por_etapa = [
	preload("res://audio/explicacao_3_1_solar.ogg"),
	preload("res://audio/explicacao_3_1_eolica.ogg"),
	preload("res://audio/explicacao_3_1_hidro.ogg")
]

# --- IMAGENS EXPLICAÇÃO POR ETAPA ---
var imagens_explicacao = [
	preload("res://assets/explicacao_solar.png"),
	preload("res://assets/explicacao_eolica.png"),
	preload("res://assets/explicacao_hidreletrica.png")
]

# --- IMAGENS DAS ETAPAS ---
var imagens = [
	preload("res://assets/solar_sol.png"),
	preload("res://assets/solar_placa.png"),
	preload("res://assets/casa.png"),
	preload("res://assets/eolica_vento.png"),
	preload("res://assets/eolica_ventoinha.png"),
	preload("res://assets/casa.png"),
	preload("res://assets/hidreletrica_agua.png"),
	preload("res://assets/hidreletrica_usina.png"),
	preload("res://assets/casa.png")
]

# --- IMAGEM PRINCIPAL ---
var tipo_energia_imgs = [
	preload("res://assets/tipo_solar.png"),
	preload("res://assets/tipo_eolica.png"),
	preload("res://assets/tipo_hidreletrica.png")
]

# --- RESPOSTAS CORRETAS ---
var respostas_corretas = [
	["item_1", "item_2", "item_3"],
	["item_1", "item_2", "item_3"],
	["item_1", "item_2", "item_3"]
]

func _ready():
	_mostrar_explicacao_inicial()
	label_vitoria.visible = false
	selecionados.clear()

	# Botões principais
	explicacao_inicial_container.get_node("button_continuar").pressed.connect(_mostrar_explicacao_etapa)
	explicacao_etapa_container.get_node("button_iniciar").pressed.connect(_iniciar_exercicio)

	# Botões do exercício
	$exercicio_container/button_restart.pressed.connect(_reiniciar_etapa)
	$exercicio_container/button_continuar.pressed.connect(_finalizar_etapa)

	$exercicio_container/button_continuar.visible = false
	$exercicio_container/button_restart.visible = false
	$exercicio_container/feedback_label.visible = false

	for nome in ["item_1", "item_2", "item_3"]:
		var item = $exercicio_container/itens_container.get_node(nome)
		item.pressed.connect(Callable(self, "_on_item_pressed").bind(nome))


# ============================================================
# Áudio
# ============================================================
func _tocar_narracao(stream):
	if narracao:
		narracao.stop()
		narracao.stream = stream
		narracao.play()

func _play_click():
	if audio and audio.stream:
		audio.play()


# ============================================================
# EXPLICAÇÃO INICIAL
# ============================================================
func _mostrar_explicacao_inicial():
	explicacao_inicial_container.visible = true
	explicacao_etapa_container.visible = false
	exercicio_container.visible = false
	label_vitoria.visible = false

	_tocar_narracao(audio_explicacao_inicial)


# ============================================================
# EXPLICAÇÃO POR ETAPA
# ============================================================
func _mostrar_explicacao_etapa():
	explicacao_inicial_container.visible = false
	explicacao_etapa_container.visible = true
	exercicio_container.visible = false

	var imagem_explicacao = explicacao_etapa_container.get_node("imagem_etapa")
	if imagem_explicacao:
		imagem_explicacao.texture = imagens_explicacao[etapa_atual]

	# Toca o áudio de explicação da etapa
	_tocar_narracao(audios_explicacao_por_etapa[etapa_atual])


# ============================================================
# EXERCÍCIO
# ============================================================
func _iniciar_exercicio():
	explicacao_etapa_container.visible = false
	exercicio_container.visible = true

	seta_1.visible = false
	seta_2.visible = false
	selecionados.clear()

	# **ÁUDIO DESLIGADO AQUI (vazio), conforme você pediu**
	if narracao:
		narracao.stop()

	$exercicio_container/feedback_label.visible = false
	$exercicio_container/button_continuar.visible = false
	$exercicio_container/button_restart.visible = false

	tipo_energia_img.texture = tipo_energia_imgs[etapa_atual]

	var base_index = etapa_atual * 3
	for i in range(3):
		var item = $exercicio_container/itens_container.get_node("item_%d" % (i + 1))
		item.texture_normal = imagens[base_index + i]
		item.disabled = false


func _on_item_pressed(nome_item: String):
	if nome_item in selecionados:
		return

	selecionados.append(nome_item)
	_play_click()

	if selecionados.size() == 2:
		seta_1.visible = true
	elif selecionados.size() == 3:
		seta_2.visible = true

	if selecionados.size() == 3:
		_verificar_resposta()


func _verificar_resposta():
	var correta = respostas_corretas[etapa_atual]
	var feedback = $exercicio_container/feedback_label
	feedback.visible = true

	if selecionados == correta:
		feedback.text = "Correto! ⚡"
		feedback.add_theme_color_override("font_color", Color(0, 1, 0))
		$exercicio_container/button_continuar.visible = true
		$exercicio_container/button_restart.visible = false
	else:
		feedback.text = "Tente novamente!"
		feedback.add_theme_color_override("font_color", Color(1, 0, 0))
		$exercicio_container/button_restart.visible = true
		$exercicio_container/button_continuar.visible = false

	selecionados.clear()


func _reiniciar_etapa():
	_iniciar_exercicio()


func _finalizar_etapa():
	etapa_atual += 1
	if etapa_atual < TOTAL_ETAPAS:
		_mostrar_explicacao_etapa()
	else:
		_finalizar_fase()


func _finalizar_fase():
	exercicio_container.visible = false
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE!"

	_save_progress_and_return(2)


func _save_progress_and_return(next_stage:int):
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"

	var err = cfg.load(save_path)
	if err != OK:
		cfg.set_value("level3", "unlocked_stage", next_stage)
	else:
		var unlocked = cfg.get_value("level3", "unlocked_stage", 1)
		if next_stage > unlocked:
			cfg.set_value("level3", "unlocked_stage", next_stage)

	cfg.save(save_path)

	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/nivel_3_selecionafase.tscn")
