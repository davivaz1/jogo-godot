extends Control

@onready var explicacao_container = $explicacao_container
@onready var exercicio_container = $exercicio_container
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D
@onready var feedback_label = $exercicio_container/feedback_label
@onready var button_restart = $exercicio_container/button_restart
@onready var button_continuar = $exercicio_container/button_continuar
@onready var area_renovavel = $exercicio_container/area_renovavel
@onready var area_nao_renovavel = $exercicio_container/area_nao_renovavel
@onready var voltar_button = $voltar_button   # <--- adiciona essa linha

var dragging_item = null
var original_pos = {}
var respostas = {}

# --- Gabarito ---
var corretos = {
	"item_solar": "renovavel",
	"item_hidreletrica": "renovavel",
	"item_eolica": "renovavel",
	"item_nuclear": "nao_renovavel",
	"item_termica": "nao_renovavel",
	"item_petroleo": "nao_renovavel"
}

func _ready():
	explicacao_container.visible = true
	exercicio_container.visible = false
	label_vitoria.visible = false
	button_restart.visible = false
	button_continuar.visible = false
	feedback_label.visible = false

	# --- Conecta o botão de voltar ---
	if voltar_button:
		voltar_button.pressed.connect(_on_voltar_button_pressed)

	explicacao_container.get_node("button_continuar").pressed.connect(func():
		_play_click()
		_iniciar_exercicio()
	)

	button_restart.pressed.connect(func():
		_play_click()
		_reiniciar_exercicio()
	)

	button_continuar.pressed.connect(func():
		_play_click()
		_finalizar_fase()
	)

	# Salva posições originais e conecta drag em cada item
	for nome in corretos.keys():
		var item = $exercicio_container/area_itens.get_node(nome)
		original_pos[nome] = item.position
		item.gui_input.connect(func(event): _on_item_gui_input(event, item))

func _play_click():
	if audio and audio.stream:
		audio.play()

func _iniciar_exercicio():
	explicacao_container.visible = false
	exercicio_container.visible = true
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false
	respostas.clear()

func _reiniciar_exercicio():
	for nome in corretos.keys():
		var item = $exercicio_container/area_itens.get_node(nome)
		item.position = original_pos[nome]
	respostas.clear()
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false

# --- Drag & Drop ---
func _on_item_gui_input(event: InputEvent, item):
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		item.position += event.relative
	elif event is InputEventScreenDrag:
		item.position += event.relative
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_soltar_item(item)
	elif event is InputEventScreenTouch and not event.pressed:
		_soltar_item(item)

func _soltar_item(item):
	var rect_item = item.get_global_rect()
	var rect_renov = area_renovavel.get_global_rect()
	var rect_naorenov = area_nao_renovavel.get_global_rect()

	if rect_item.intersects(rect_renov):
		respostas[item.name] = "renovavel"
	elif rect_item.intersects(rect_naorenov):
		respostas[item.name] = "nao_renovavel"
	else:
		item.position = original_pos[item.name]
		return

	if respostas.size() == corretos.size():
		_verificar_respostas()

func _verificar_respostas():
	var certos = 0
	for nome in corretos.keys():
		if respostas.get(nome, "") == corretos[nome]:
			certos += 1

	feedback_label.visible = true

	if certos == corretos.size():
		feedback_label.text = "Correto! 🌱"
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
		button_continuar.visible = true
		button_restart.visible = false
	else:
		feedback_label.text = "Tente novamente!"
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button_restart.visible = true
		button_continuar.visible = false

func _finalizar_fase():
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU A FASE!"
	await get_tree().create_timer(1.5).timeout
	_salvar_progresso_e_voltar()

func _salvar_progresso_e_voltar():
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"
	var err = cfg.load(save_path)
	if err != OK:
		cfg.set_value("level1", "unlocked_stage", 3)
	else:
		var unlocked = cfg.get_value("level1", "unlocked_stage", 1)
		if 3 > unlocked:
			cfg.set_value("level1", "unlocked_stage", 3)
	cfg.save(save_path)

	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/nivel_1_selecionafase.tscn")

# --- Botão de voltar ---
func _on_voltar_button_pressed():
	_play_click()
	get_tree().change_scene_to_file("res://scenes/nivel_1_selecionafase.tscn")
