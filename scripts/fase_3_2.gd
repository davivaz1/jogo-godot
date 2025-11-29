extends Control

@onready var explicacao_inicial_container = $explicacao_inicial_container
@onready var explicacao_etapa_container = $explicacao_etapa_container
@onready var exercicio_container = $exercicio_container
@onready var seta_1 = $exercicio_container/seta_1
@onready var seta_2 = $exercicio_container/seta_2
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D
@onready var tipo_energia_img = $exercicio_container/tipo_energia_img

var etapa_atual = 0
const TOTAL_ETAPAS = 2
var selecionados = []

# ------ ÁUDIOS ------
var audios = [
	preload("res://audio/explicacao_3_2_audio.ogg"),
	preload("res://audio/explicacao_3_2_petroleo.ogg"),
	null, # parte do exercício
	preload("res://audio/explicacao_3_2_carvao.ogg"),
	null
]

# ------ IMAGENS DAS EXPLICAÇÕES ------
var explicacoes_imgs = [
	preload("res://assets/explicacao_petroleo.png"),
	preload("res://assets/explicacao_carvao.png")
]

# ------ IMAGENS DE CADA ETAPA ------
var imagens = [
	preload("res://assets/petroleo_maior.png"),
	preload("res://assets/usina_maior.png"),
	preload("res://assets/casa.png"),

	preload("res://assets/carvao_maior.png"),
	preload("res://assets/usina_maior.png"),
	preload("res://assets/casa.png")
]

# ------ ÍCONE PRINCIPAL DA ETAPA ------
var tipo_energia_imgs = [
	preload("res://assets/energia_petroleo.png"),
	preload("res://assets/energia_carvao.png")
]

# ------ TEXTOS DE EXPLICAÇÃO ------
var explicacoes = [
	"Nesta etapa, você verá como a energia proveniente do petróleo é gerada e chega até as casas.",
	"Agora observe como o carvão é utilizado para gerar energia elétrica."
]

# ------ RESPOSTAS CORRETAS ------
var respostas_corretas = [
	["item_1", "item_2", "item_3"], 
	["item_1", "item_2", "item_3"]
]

func _ready():
	_mostrar_explicacao_inicial()
	label_vitoria.visible = false
	selecionados.clear()

	# --- BOTÕES PRINCIPAIS ---
	explicacao_inicial_container.get_node("button_continuar").pressed.connect(_mostrar_explicacao_etapa)
	explicacao_etapa_container.get_node("button_iniciar").pressed.connect(_iniciar_exercicio)

	# --- BOTÕES DO EXERCÍCIO ---
	$exercicio_container/button_restart.pressed.connect(_reiniciar_etapa)
	$exercicio_container/button_continuar.pressed.connect(_finalizar_etapa)
	$exercicio_container/button_continuar.visible = false
	$exercicio_container/button_restart.visible = false
	$exercicio_container/feedback_label.visible = false

	# --- ITENS CLICÁVEIS ---
	for nome in ["item_1", "item_2", "item_3"]:
		var item = $exercicio_container/itens_container.get_node(nome)
		item.pressed.connect(Callable(self, "_on_item_pressed").bind(nome))

func _play_click():
	if audio and audio.stream:
		audio.play()

# --------------------- TELA 1 ------------------------
func _mostrar_explicacao_inicial():
	explicacao_inicial_container.visible = true
	explicacao_etapa_container.visible = false
	exercicio_container.visible = false
	label_vitoria.visible = false

	# Áudio da explicação inicial da fase
	audio.stream = audios[0]
	if audio.stream:
		audio.play()

# --------------------- TELA 2 ------------------------
func _mostrar_explicacao_etapa():
	explicacao_inicial_container.visible = false
	explicacao_etapa_container.visible = true
	exercicio_container.visible = false

	var img_node = explicacao_etapa_container.get_node("imagem_explicacao")
	img_node.texture = explicacoes_imgs[etapa_atual]

	# Tocar áudio correto da etapa
	audio.stream = audios[1 + etapa_atual * 2]
	if audio.stream:
		audio.play()

# --------------------- EXERCÍCIO ------------------------
func _iniciar_exercicio():
	explicacao_etapa_container.visible = false
	exercicio_container.visible = true

	$exercicio_container/feedback_label.visible = false
	$exercicio_container/button_continuar.visible = false
	$exercicio_container/button_restart.visible = false
	selecionados.clear()

	seta_1.visible = false
	seta_2.visible = false

	# Imagem principal
	tipo_energia_img.texture = tipo_energia_imgs[etapa_atual]

	# Tocar áudio vazio (não tocar nada)
	audio.stream = null

	# Carregar imagens da etapa
	var base = etapa_atual * 3
	for i in range(3):
		var item = $exercicio_container/itens_container.get_node("item_%d" % (i + 1))
		item.texture_normal = imagens[base + i]
		item.disabled = false

# ----------------- ITEM CLICADO ------------------------
func _on_item_pressed(nome_item: String):
	if nome_item in selecionados:
		return

	selecionados.append(nome_item)
	_play_click()

	if selecionados.size() == 2:
		seta_1.visible = true
	elif selecionados.size() == 3:
		seta_2.visible = true
		_verificar_resposta()

# ----------------- VERIFICAR RESPOSTA ------------------------
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

# ------------------ REINICIAR ------------------------
func _reiniciar_etapa():
	_iniciar_exercicio()

# ------------------ FINALIZAR ETAPA ------------------------
func _finalizar_etapa():
	etapa_atual += 1
	if etapa_atual < TOTAL_ETAPAS:
		_mostrar_explicacao_etapa()
	else:
		_finalizar_fase()

# ------------------ FINALIZAR FASE ------------------------
func _finalizar_fase():
	exercicio_container.visible = false
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE!"
	_save_progress_and_return(4)

# ------------------ SALVAR PROGRESSO ------------------------
func _save_progress_and_return(next_stage: int):
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
