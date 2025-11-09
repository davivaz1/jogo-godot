extends Control

@onready var explicacao_container = $explicacao_container
@onready var exercicio_container = $exercicio_container
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D

var selecionados = []
var corretos = ["item_computador", "item_celular"]

func _ready():
	# Configuração inicial
	explicacao_container.visible = true
	exercicio_container.visible = false
	label_vitoria.visible = false

	# Conectar botões
	explicacao_container.get_node("button_continuar").pressed.connect(_iniciar_exercicio)

	for nome in ["item_computador", "item_celular", "item_maca"]:
		var item = $exercicio_container/itens_container.get_node(nome)
		item.pressed.connect(func(): _on_item_pressed(nome))

	$exercicio_container/button_continuar.pressed.connect(_finalizar_fase)
	$exercicio_container/button_continuar.visible = false

func _iniciar_exercicio():
	explicacao_container.visible = false
	exercicio_container.visible = true
	$exercicio_container/feedback_label.visible = false
	selecionados.clear()

# --- Quando o jogador clica em um item ---
func _on_item_pressed(nome_item: String):
	if nome_item in selecionados:
		return # evita clicar duas vezes no mesmo

	selecionados.append(nome_item)

	if audio and audio.stream:
		audio.play()

	# Quando 2 itens forem escolhidos, verifica
	if selecionados.size() == 2:
		_verificar_resposta()

# --- Verifica se o jogador escolheu certo ---
func _verificar_resposta():
	var acertos = 0
	for item in selecionados:
		if item in corretos:
			acertos += 1

	var feedback = $exercicio_container/feedback_label
	feedback.visible = true

	if acertos == 2:
		feedback.text = "Correto! 💡"
		feedback.add_theme_color_override("font_color", Color(0, 1, 0)) # verde
		$exercicio_container/button_continuar.visible = true
	else:
		feedback.text = "Tente novamente!"
		feedback.add_theme_color_override("font_color", Color(1, 0, 0)) # vermelho
		selecionados.clear()

# --- Quando acerta e clica em “Continuar” ---
func _finalizar_fase():
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE!"
	_save_progress_and_return(2)

# --- Salva o progresso e retorna à seleção de fases ---
func _save_progress_and_return(next_stage: int):
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

	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://scenes/Level1_StageSelect.tscn")
