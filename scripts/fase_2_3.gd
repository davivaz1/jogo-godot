extends Control

@onready var explicacao_container = $explicacao_container
@onready var quiz_container = $quiz_container
@onready var audio = $AudioStreamPlayer2D

@onready var pergunta_label = $quiz_container/TextureRect/pergunta_label
@onready var opcao_1 = $quiz_container/opcoes_container/opcao_1
@onready var opcao_2 = $quiz_container/opcoes_container/opcao_2
@onready var opcao_3 = $quiz_container/opcoes_container/opcao_3

@onready var feedback_label = $quiz_container/feedback_label
@onready var button_continuar = $quiz_container/button_continuar
@onready var button_restart = $quiz_container/button_restart

var botoes_opcoes: Array
var pergunta_atual = 0

# Dados do quiz
const DADOS_QUIZ = [
	# Pergunta 1/2: Índice [0]
	[
		"Qual dessas energias usa o petróleo como fonte de energia?",
		["Solar ☀️", "Petrólifica 🛢️", "Eólica 🌬️"],
		1 # Resposta correta: Eólica (índice 2)
	],
	# Pergunta 2/2: Índice [1]
	[
		"Qual fonte de energia utiliza o carvão?",
		["Carvão 🔥", "Gás Natural ⛽", "Geotérmica 🌋"],
		0 # Resposta correta: Solar (índice 1)
		]
]

func _ready():
	botoes_opcoes = [opcao_1, opcao_2, opcao_3]
	_conectar_botoes()
	_mostrar_explicacao_inicial()

# ---------------------------------------------------------
# Conexões de botões
# ---------------------------------------------------------
func _conectar_botoes():
	explicacao_container.get_node("button_continuar").pressed.connect(_iniciar_quiz)
	button_restart.pressed.connect(_reiniciar_quiz)
	button_continuar.pressed.connect(_avancar_quiz)
	for i in range(3):
		botoes_opcoes[i].pressed.connect(Callable(self, "_on_opcao_pressed").bind(i))

# ---------------------------------------------------------
# Som de clique
# ---------------------------------------------------------
func _play_click():
	if audio and audio.stream:
		audio.play()

# ---------------------------------------------------------
# Exibição inicial (explicação por PNG no editor)
# ---------------------------------------------------------
func _mostrar_explicacao_inicial():
	quiz_container.visible = false
	explicacao_container.visible = true
	# Nenhum texto definido aqui — apenas sua imagem no editor

# ---------------------------------------------------------
# Início do quiz
# ---------------------------------------------------------
func _iniciar_quiz():
	explicacao_container.visible = false
	quiz_container.visible = true
	_reiniciar_quiz()

# ---------------------------------------------------------
# Reinicia o quiz
# ---------------------------------------------------------
func _reiniciar_quiz():
	if pergunta_atual >= DADOS_QUIZ.size():
		print("Erro: Tentativa de carregar pergunta inexistente.")
		return
	
	var pergunta = DADOS_QUIZ[pergunta_atual][0]
	var opcoes = DADOS_QUIZ[pergunta_atual][1]
	pergunta_label.text = pergunta

	for i in range(3):
		botoes_opcoes[i].get_node("label").text = opcoes[i]
		botoes_opcoes[i].disabled = false

	feedback_label.visible = false
	button_continuar.visible = false
	button_restart.visible = false

# ---------------------------------------------------------
# Quando o jogador escolhe uma opção
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

func _avancar_quiz():
	pergunta_atual += 1 # Vai para a próxima pergunta
	
	if pergunta_atual < DADOS_QUIZ.size():
		# Se ainda houver perguntas (2 no total), carrega a próxima
		_reiniciar_quiz()
	else:
		# Se todas as perguntas foram respondidas, finaliza a fase
		_finalizar_fase()

# ---------------------------------------------------------
# Finaliza a fase e avança
# ---------------------------------------------------------
func _finalizar_fase():
	quiz_container.visible = false

	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/level_select_3.tscn")
