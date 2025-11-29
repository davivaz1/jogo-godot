extends Control

@onready var explicacao_container = $explicacao_container
@onready var quiz_container = $quiz_container
@onready var audio = $AudioStreamPlayer2D       # Som de clique
@onready var narracao = $Narracao               # Narração das telas

@onready var pergunta_label = $quiz_container/TextureRect/pergunta_label
@onready var opcao_1 = $quiz_container/opcoes_container/opcao_1
@onready var opcao_2 = $quiz_container/opcoes_container/opcao_2
@onready var opcao_3 = $quiz_container/opcoes_container/opcao_3

@onready var feedback_label = $quiz_container/feedback_label
@onready var button_continuar = $quiz_container/button_continuar
@onready var button_restart = $quiz_container/button_restart

var botoes_opcoes: Array

# --- ARQUIVOS DE ÁUDIO DA FASE 2_1 ---
var audio_explicacao = preload("res://audio/explicacao_2_1_audio.ogg")
var audio_pergunta_1 = preload("res://audio/fase_2_1_pergunta1.ogg")
var audio_pergunta_2 = preload("res://audio/fase_2_1_pergunta2.ogg")

#Dados do quiz (sem parte de explicação)
const DADOS_QUIZ = [
	[
		"Qual dessas energias não é renovável?",
		["Eólica 🌬️", "Carvão 🔥", "Solar ☀️"],
		1  
	],
	[
		"Qual dessas energias é renovável?",
		["Solar ☀️", "Carvão 🔥", "Petróleo 🛢️"],
		0  
	]
]

var pergunta_atual = 0

func _ready():
	botoes_opcoes = [opcao_1, opcao_2, opcao_3]
	_conectar_botoes()
	_mostrar_explicacao_inicial()

	# --- TOCAR NARRAÇÃO DA EXPLICAÇÃO ---
	_tocar_narracao(audio_explicacao)


# ----------------------------- CONEXÕES -----------------------------
func _conectar_botoes():
	explicacao_container.get_node("button_continuar").pressed.connect(_iniciar_quiz)
	button_restart.pressed.connect(_reiniciar_quiz)
	button_continuar.pressed.connect(_avancar_quiz)

	for i in range(3):
		botoes_opcoes[i].pressed.connect(Callable(self, "_on_opcao_pressed").bind(i))


# ----------------------------- ÁUDIO -----------------------------
func _play_click():
	if audio and audio.stream:
		audio.play()

func _tocar_narracao(stream):
	if narracao:
		narracao.stop()
		narracao.stream = stream
		narracao.play()


# ----------------------------- EXPLICAÇÃO -----------------------------
func _mostrar_explicacao_inicial():
	quiz_container.visible = false
	explicacao_container.visible = true


# ----------------------------- INÍCIO DO QUIZ -----------------------------
func _iniciar_quiz():
	explicacao_container.visible = false
	quiz_container.visible = true
	pergunta_atual = 0
	_reiniciar_quiz()

	# --- tocar áudio da primeira pergunta ---
	_tocar_narracao(audio_pergunta_1)


# ----------------------------- REINICIAR PERGUNTA -----------------------------
func _reiniciar_quiz():
	var pergunta = DADOS_QUIZ[pergunta_atual][0]
	var opcoes = DADOS_QUIZ[pergunta_atual][1]

	pergunta_label.text = pergunta
	
	for i in range(3):
		botoes_opcoes[i].get_node("label").text = opcoes[i]
		botoes_opcoes[i].disabled = false

	feedback_label.visible = false
	button_continuar.visible = false
	button_restart.visible = false


# ----------------------------- LÓGICA DE RESPOSTA -----------------------------
func _on_opcao_pressed(indice_clicado: int):
	for botao in botoes_opcoes:
		botao.disabled = true

	_play_click()

	var indice_correto = DADOS_QUIZ[pergunta_atual][2]
	feedback_label.visible = true

	if indice_clicado == indice_correto:
		feedback_label.text = "Correto!"
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
		button_continuar.visible = true
		button_restart.visible = false
	else:
		feedback_label.text = "Ops! Tente Novamente."
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button_restart.visible = true
		button_continuar.visible = false


# ----------------------------- AVANÇAR PARA A PRÓXIMA -----------------------------
func _avancar_quiz():
	pergunta_atual += 1

	if pergunta_atual < DADOS_QUIZ.size():
		_reiniciar_quiz()

		# --- tocar áudio da pergunta correspondente ---
		if pergunta_atual == 1:
			_tocar_narracao(audio_pergunta_2)
	else:
		_finalizar_fase()


# ----------------------------- FIM DA FASE -----------------------------
func _finalizar_fase():
	quiz_container.visible = false
	
	var next_stage_to_unlock = 2
	_save_progress_and_return(next_stage_to_unlock)


func _save_progress_and_return(next_stage: int):
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"
	var err = cfg.load(save_path)

	if err != OK:
		cfg.set_value("level2", "unlocked_stage", next_stage)
	else:
		var unlocked = cfg.get_value("level2", "unlocked_stage", 1)
		if next_stage > unlocked:
			cfg.set_value("level2", "unlocked_stage", next_stage)
	cfg.save(save_path)

	await get_tree().create_timer(0.1).timeout
	get_tree().change_scene_to_file("res://scenes/nivel_2_selecionafase.tscn")
