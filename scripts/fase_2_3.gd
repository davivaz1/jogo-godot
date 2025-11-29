extends Control

@onready var explicacao_container = $explicacao_container
@onready var quiz_container = $quiz_container
@onready var audio = $AudioStreamPlayer2D
@onready var narracao = $Narracao  # Áudio da narração

@onready var pergunta_label = $quiz_container/TextureRect/pergunta_label
@onready var opcao_1 = $quiz_container/opcoes_container/opcao_1
@onready var opcao_2 = $quiz_container/opcoes_container/opcao_2
@onready var opcao_3 = $quiz_container/opcoes_container/opcao_3

@onready var feedback_label = $quiz_container/feedback_label
@onready var button_continuar = $quiz_container/button_continuar
@onready var button_restart = $quiz_container/button_restart

var botoes_opcoes: Array
var pergunta_atual = 0

# ---------------------------------------------------------
# ÁUDIOS DA FASE 2_3  (EXATAMENTE COMO PEDIU)
# ---------------------------------------------------------
var audio_explicacao = preload("res://audio/explicacao_2_3_audio.ogg")
var audio_pergunta_1 = preload("res://audio/fase_2_3_pergunta1.ogg")
var audio_pergunta_2 = preload("res://audio/fase_2_3_pergunta2.ogg")

# ---------------------------------------------------------
# PERGUNTAS ORIGINAIS (SUAS, SEM MUDAR NADA)
# ---------------------------------------------------------
const DADOS_QUIZ = [
	[
		"Qual dessas energias usa o petróleo como fonte de energia?",
		["Solar ☀️", "Petrólifica 🛢️", "Eólica 🌬️"],
		1
	],
	[
		"Qual fonte de energia utiliza o carvão?",
		["Carvão 🔥", "Gás Natural ⛽", "Geotérmica 🌋"],
		0
	]
]

# ---------------------------------------------------------
func _ready():
	botoes_opcoes = [opcao_1, opcao_2, opcao_3]
	_conectar_botoes()

	_mostrar_explicacao_inicial()
	_tocar_narracao(audio_explicacao)

# ---------------------------------------------------------
func _conectar_botoes():
	explicacao_container.get_node("button_continuar").pressed.connect(_iniciar_quiz)
	button_restart.pressed.connect(_reiniciar_quiz)
	button_continuar.pressed.connect(_avancar_quiz)

	for i in range(3):
		botoes_opcoes[i].pressed.connect(Callable(self, "_on_opcao_pressed").bind(i))

# ---------------------------------------------------------
func _tocar_narracao(stream):
	if narracao:
		narracao.stop()
		narracao.stream = stream
		narracao.play()

func _play_click():
	if audio and audio.stream:
		audio.play()

# ---------------------------------------------------------
func _mostrar_explicacao_inicial():
	quiz_container.visible = false
	explicacao_container.visible = true

# ---------------------------------------------------------
func _iniciar_quiz():
	explicacao_container.visible = false
	quiz_container.visible = true
	pergunta_atual = 0

	_tocar_narracao(audio_pergunta_1)
	_reiniciar_quiz()

# ---------------------------------------------------------
func _reiniciar_quiz():
	if pergunta_atual >= DADOS_QUIZ.size():
		return

	var pergunta = DADOS_QUIZ[pergunta_atual][0]
	var opcoes = DADOS_QUIZ[pergunta_atual][1]

	pergunta_label.text = pergunta

	for i in range(3):
		botoes_opcoes[i].get_node("label").text = opcoes[i]
		botoes_opcoes[i].disabled = false

	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false

# ---------------------------------------------------------
func _on_opcao_pressed(indice_clicado: int):
	for botao in botoes_opcoes:
		botao.disabled = true

	_play_click()

	var indice_correto = DADOS_QUIZ[pergunta_atual][2]

	feedback_label.visible = true

	if indice_clicado == indice_correto:
		feedback_label.text = "Correto! Avance."
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
		button_continuar.visible = true
		button_restart.visible = false
	else:
		feedback_label.text = "Ops! Tente Novamente."
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button_restart.visible = true
		button_continuar.visible = false

# ---------------------------------------------------------
func _avancar_quiz():
	pergunta_atual += 1

	if pergunta_atual == 1:
		_tocar_narracao(audio_pergunta_2)

	if pergunta_atual < DADOS_QUIZ.size():
		_reiniciar_quiz()
	else:
		_finalizar_fase()

# ---------------------------------------------------------
func _finalizar_fase():
	quiz_container.visible = false

	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/level_select_3.tscn")
