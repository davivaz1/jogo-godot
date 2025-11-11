extends Control

@onready var explicacao_container = $explicacao_container
@onready var quiz_container = $quiz_container
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D

@onready var pergunta_label = $quiz_container/pergunta_label
@onready var opcao_1 = $quiz_container/opcoes_container/opcao_1
@onready var opcao_2 = $quiz_container/opcoes_container/opcao_2
@onready var opcao_3 = $quiz_container/opcoes_container/opcao_3

@onready var feedback_label = $quiz_container/feedback_label
@onready var button_continuar = $quiz_container/button_continuar
@onready var button_restart = $quiz_container/button_restart

var botoes_opcoes: Array

#Dados do quiz (sem parte de explicação)
const DADOS_QUIZ = [
	"Qual dessas energias usa a força da água para gerar eletricidade?", 
	["Eólica", "Hidrelétrica", "Carvão"], 
	1
]

func _ready():
	botoes_opcoes = [opcao_1, opcao_2, opcao_3]
	_conectar_botoes()
	_mostrar_explicacao_inicial()

#Conecta os botões
func _conectar_botoes():
	explicacao_container.get_node("button_continuar").pressed.connect(_iniciar_quiz)
	button_restart.pressed.connect(_reiniciar_quiz)
	button_continuar.pressed.connect(_finalizar_fase)

	for i in range(3):
		botoes_opcoes[i].pressed.connect(Callable(self, "_on_opcao_pressed").bind(i))

func _play_click():
	if audio and audio.stream:
		audio.play()

#Mostra apenas a explicação visual (via PNG)
func _mostrar_explicacao_inicial():
	quiz_container.visible = false
	label_vitoria.visible = false
	explicacao_container.visible = true
	# Nenhum texto definido aqui — você controla via imagem no editor

#Começa o quiz
func _iniciar_quiz():
	explicacao_container.visible = false
	quiz_container.visible = true
	_reiniciar_quiz()

# Reinicia o quiz
func _reiniciar_quiz():
	var pergunta = DADOS_QUIZ[0]
	var opcoes = DADOS_QUIZ[1]
	
	pergunta_label.text = pergunta
	
	for i in range(3):
		botoes_opcoes[i].get_node("label").text = opcoes[i]
		botoes_opcoes[i].disabled = false

	feedback_label.visible = false
	button_continuar.visible = false
	button_restart.visible = false

# Quando o jogador clica em uma opção
func _on_opcao_pressed(indice_clicado: int):
	for botao in botoes_opcoes:
		botao.disabled = true
		
	_play_click()

	var indice_correto = DADOS_QUIZ[2]
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

# Quando acerta e termina a fase
func _finalizar_fase():
	quiz_container.visible = false
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE 2-1!"
	
	var next_stage_to_unlock = 2
	_save_progress_and_return(next_stage_to_unlock)

# Salva o progresso e retorna
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

	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/nivel_2_selecionafase.tscn")
