extends Control

@onready var explicacao_inicial_container = $explicacao_inicial_container
@onready var explicacao_etapa_container = $explicacao_etapa_container
@onready var exercicio_container = $exercicio_container
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D
@onready var tipo_energia_img = $exercicio_container/tipo_energia_img

var etapa_atual = 0
const TOTAL_ETAPAS = 2
var selecionados = []

var explicacoes_imgs = [
	preload("res://assets/explicacao_petroleo.png"),
	preload("res://assets/explicacao_gas.png")
]

# --- IMAGENS DAS ETAPAS ---
var imagens = [
	preload("res://assets/petroleo_maior.png"),
	preload("res://assets/usina_maior.png"),
	preload("res://assets/casa.png"),
	preload("res://assets/carvao_maior.png"),
	preload("res://assets/usina_maior.png"),
	preload("res://assets/casa.png")
]

# --- IMAGEM PRINCIPAL DE CADA ETAPA ---
var tipo_energia_imgs = [
	preload("res://assets/energia_petroleo.png"),
	preload("res://assets/energia_carvao.png")
]

# --- EXPLICAÇÕES DE CADA ETAPA ---
var explicacoes = [
	"Nesta etapa, você verá como a energia proveniente do petróleo é gerada e chega até as casas.",
	"Agora observe como o gás natural é utilizado para gerar energia elétrica e abastecer as residências."
]

# --- RESPOSTAS CORRETAS (usando nomes dos nós item_1..item_3) ---
var respostas_corretas = [
	["item_1", "item_2", "item_3"], # petróleo
	["item_1", "item_2", "item_3"]  # gás natural
]

func _ready():
	_mostrar_explicacao_inicial()
	label_vitoria.visible = false
	selecionados.clear()

	# Conectar botões principais
	explicacao_inicial_container.get_node("button_continuar").pressed.connect(_mostrar_explicacao_etapa)
	explicacao_etapa_container.get_node("button_iniciar").pressed.connect(_iniciar_exercicio)

	# Conectar botões do exercício
	$exercicio_container/button_restart.pressed.connect(_reiniciar_etapa)
	$exercicio_container/button_continuar.pressed.connect(_finalizar_etapa)
	$exercicio_container/button_continuar.visible = false
	$exercicio_container/button_restart.visible = false
	$exercicio_container/feedback_label.visible = false

	# Conectar cliques dos itens corretamente
	for nome in ["item_1", "item_2", "item_3"]:
		var item = $exercicio_container/itens_container.get_node(nome)
		item.pressed.connect(Callable(self, "_on_item_pressed").bind(nome))

func _play_click():
	if audio and audio.stream:
		audio.play()

# --- EXPLICAÇÃO INICIAL ---
func _mostrar_explicacao_inicial():
	explicacao_inicial_container.visible = true
	explicacao_etapa_container.visible = false
	exercicio_container.visible = false
	label_vitoria.visible = false

# --- EXPLICAÇÃO DA ETAPA ---
func _mostrar_explicacao_etapa():
	explicacao_inicial_container.visible = false
	explicacao_etapa_container.visible = true
	exercicio_container.visible = false
	label_vitoria.visible = false

	# Atualiza a imagem da explicação
	var img_node = explicacao_etapa_container.get_node("imagem_explicacao")
	img_node.texture = explicacoes_imgs[etapa_atual]

# --- INICIAR O EXERCÍCIO ---
func _iniciar_exercicio():
	explicacao_etapa_container.visible = false
	exercicio_container.visible = true
	$exercicio_container/feedback_label.visible = false
	$exercicio_container/button_continuar.visible = false
	$exercicio_container/button_restart.visible = false
	selecionados.clear()

	# Atualiza a imagem principal (tipo de energia)
	tipo_energia_img.texture = tipo_energia_imgs[etapa_atual]

	# Atualiza as imagens dos botões: slice do array 'imagens'
	var base_index = etapa_atual * 3
	for i in range(3):
		var item = $exercicio_container/itens_container.get_node("item_%d" % (i + 1))
		item.texture_normal = imagens[base_index + i]
		item.disabled = false

# --- QUANDO CLICA EM UM ITEM ---
func _on_item_pressed(nome_item: String):
	if nome_item in selecionados:
		return

	selecionados.append(nome_item)
	_play_click()

	if selecionados.size() == 3:
		_verificar_resposta()

# --- VERIFICA SE ACERTOU ---
func _verificar_resposta():
	var correta = respostas_corretas[etapa_atual]
	var feedback = $exercicio_container/feedback_label
	feedback.visible = true

	if selecionados == correta:
		feedback.text = "Correto! ⚡"
		feedback.add_theme_color_override("font_color", Color(0, 1, 0))
		$exercicio_container/button_continuar.visible = true
		$exercicio_container/button_restart.visible = false
		for n in selecionados:
			$exercicio_container/itens_container.get_node(n).disabled = true
	else:
		feedback.text = "Tente novamente!"
		feedback.add_theme_color_override("font_color", Color(1, 0, 0))
		$exercicio_container/button_restart.visible = true
		$exercicio_container/button_continuar.visible = false

	selecionados.clear()

# --- REINICIAR ETAPA ---
func _reiniciar_etapa():
	_iniciar_exercicio()

# --- FINALIZAR ETAPA ---
func _finalizar_etapa():
	etapa_atual += 1
	if etapa_atual < TOTAL_ETAPAS:
		_mostrar_explicacao_etapa()
	else:
		_finalizar_fase()

# --- FINALIZAR FASE ---
func _finalizar_fase():
	exercicio_container.visible = false
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE!"
	_save_progress_and_return(3)

# --- SALVAR PROGRESSO ---
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
