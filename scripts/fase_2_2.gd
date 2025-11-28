extends Control

@onready var explicacao_container = $explicacao_container
@onready var quiz_container = $quiz_container
@onready var audio = $AudioStreamPlayer2D

@onready var pergunta_label = $quiz_container/TextureRectPergunta/pergunta_label
@onready var opcao_1 = $quiz_container/opcoes_container/opcao_1
@onready var opcao_2 = $quiz_container/opcoes_container/opcao_2
@onready var opcao_3 = $quiz_container/opcoes_container/opcao_3

@onready var feedback_label = $quiz_container/feedback_label
@onready var button_continuar = $quiz_container/button_continuar
@onready var button_restart = $quiz_container/button_restart

var botoes_opcoes: Array
var pergunta_atual = 0

# Dados do quiz (sem explicação por texto)
const DADOS_QUIZ = [
	# Pergunta 1: Índice [0]
	[
		"Qual fonte é responsável pela energia eólica?",
		["Vento 🌬️", "Solar ☀️", "Carvão 🔥"],
		0 # Resposta correta: Carvão (índice 2)
	],
	# Pergunta 2: Índice [1]
	[
		"Qual fonte é responsável pela energia solar?",
		["Solar ☀️", "Biomassa 🌱", "Gás Natural ⛽"],
		0 # Resposta correta: Biomassa (índice 1)
	],
	# Pergunta 3: Índice [2]
	[
		"Que energia utiliza a força da água?",
		["Nuclear ☢️", "Geotérmica 🌋", "Hidrelétrica 💧"],
		2 # Resposta correta: Hidrelétrica (índice 0)
	]
]

func _ready():
	botoes_opcoes = [opcao_1, opcao_2, opcao_3]
	_conectar_botoes()
	_mostrar_explicacao_inicial()

# Conecta os botões e sinais
func _conectar_botoes():
	explicacao_container.get_node("button_continuar").pressed.connect(_iniciar_quiz)
	button_restart.pressed.connect(_reiniciar_quiz)
	button_continuar.pressed.connect(_avancar_quiz)

	for i in range(3):
		botoes_opcoes[i].pressed.connect(Callable(self, "_on_opcao_pressed").bind(i))

func _play_click():
	if audio and audio.stream:
		audio.play()

# Mostra a explicação visual (com PNG no editor)
func _mostrar_explicacao_inicial():
	quiz_container.visible = false
	explicacao_container.visible = true
	# Nenhum texto é configurado — a explicação é feita com imagens no editor

# Inicia o quiz
func _iniciar_quiz():
	explicacao_container.visible = false
	quiz_container.visible = true
	_reiniciar_quiz()

# Reinicia o quiz
func _reiniciar_quiz():
	print("EXECUTANDO REINICIAR QUIZ PARA PERGUNTA:", pergunta_atual)
	
	if not quiz_container.visible:
		pergunta_atual = 0
	
	if pergunta_atual >= DADOS_QUIZ.size():
		print("Erro: Tentativa de carregar pergunta inexistente.")
		return
	
	var pergunta_str = DADOS_QUIZ[pergunta_atual][0]
	var opcoes_array = DADOS_QUIZ[pergunta_atual][1]
	
	pergunta_label.text = pergunta_str

	for i in range(3):
		var botao_opcao = botoes_opcoes[i]
		
		var label_opcao = botao_opcao.get_node("label")
		
		if is_instance_valid(label_opcao):
			# Se o nó Label existe, preenche o texto
			label_opcao.text = opcoes_array[i]
		else:
			print("ERRO CRÍTICO: Não foi possível encontrar o Label no nó:", botao_opcao.name)
			return
			
		botao_opcao.disabled = false
		
		botoes_opcoes[i].get_node("label").text = opcoes_array[i]
		botoes_opcoes[i].disabled = false

	feedback_label.visible = false
	button_continuar.visible = false
	button_restart.visible = false

# Quando o jogador clica em uma opção
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

# Quando acerta e finaliza a fase
func _finalizar_fase():
	quiz_container.visible = false

	var next_stage_to_unlock = 3
	_save_progress_and_return(next_stage_to_unlock)

# Salva progresso e retorna para seleção de fases
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
	
func _avancar_quiz():
	pergunta_atual += 1 # Vai para a próxima pergunta
	
	if pergunta_atual < DADOS_QUIZ.size():
		# Se ainda houver perguntas, carrega a próxima
		_reiniciar_quiz()
	else:
		# Se todas as perguntas foram respondidas, finaliza a fase
		_finalizar_fase()
