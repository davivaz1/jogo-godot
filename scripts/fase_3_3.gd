extends Control

@onready var explicacao_inicial_container = $explicacao_inicial_container
@onready var explicacao_etapa_container = $explicacao_etapa_container
@onready var exercicio_container = $exercicio_container
@onready var feedback_label = $exercicio_container/feedback_label
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D
@onready var button_restart = $exercicio_container/button_restart
@onready var button_continuar = $exercicio_container/button_continuar

var item_selecionado = null
var corretos = ["item_1", "item_2", "item_3"]
var slot_destinos = []
var slot_ocupado = {}

# ----------------------------------------------------------
# 🔊 ÁUDIOS DA FASE
# ----------------------------------------------------------
var audios = [
	preload("res://audio/explicacao_3_3_audio.ogg"),   # explicação inicial
	preload("res://audio/explicacao_3_3_solar.ogg"),   # explicação da etapa
	null                                               # exercício (sem áudio)
]

# ----------------------------------------------------------
# 🔹 INICIALIZAÇÃO
# ----------------------------------------------------------
func _ready():
	explicacao_inicial_container.visible = true
	explicacao_etapa_container.visible = false
	exercicio_container.visible = false
	label_vitoria.visible = false
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false

	slot_destinos = [
		$exercicio_container/area_destino/slot_1,
		$exercicio_container/area_destino/slot_2,
		$exercicio_container/area_destino/slot_3
	]

	# --- Botões ---
	var b1 = explicacao_inicial_container.get_node_or_null("button_continuar")
	if b1:
		b1.pressed.connect(_mostrar_explicacao_etapa)

	var b2 = explicacao_etapa_container.get_node_or_null("button_continuar")
	if b2:
		b2.pressed.connect(_iniciar_exercicio)

	button_continuar.pressed.connect(_finalizar_fase)
	button_restart.pressed.connect(_reiniciar_exercicio)

	# --- Itens clicáveis ---
	for nome in ["item_1", "item_2", "item_3"]:
		var item = $exercicio_container/area_itens.get_node(nome)
		item.gui_input.connect(_on_item_gui_input.bind(item))

	# Tocar áudio inicial
	audio.stream = audios[0]
	if audio.stream:
		audio.play()

# ----------------------------------------------------------
# 🔹 TROCA DE TELAS
# ----------------------------------------------------------
func _mostrar_explicacao_etapa():
	explicacao_inicial_container.visible = false
	explicacao_etapa_container.visible = true

	audio.stream = audios[1]
	if audio.stream:
		audio.play()

func _iniciar_exercicio():
	explicacao_etapa_container.visible = false
	exercicio_container.visible = true
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false

	audio.stream = audios[2]  # vazio
	_reiniciar_exercicio()

# ----------------------------------------------------------
# 🔹 ARRASTAR E SOLTAR ITENS
# ----------------------------------------------------------
func _on_item_gui_input(event: InputEvent, item):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			item_selecionado = item
			if audio and audio.stream:
				audio.play()
		else:
			if item_selecionado:
				_verificar_colisao(item_selecionado)
			item_selecionado = null

	elif event is InputEventMouseMotion and item_selecionado == item and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		item.position += event.relative

# ----------------------------------------------------------
# 🔹 VERIFICA COLISÃO COM SLOTS
# ----------------------------------------------------------
func _verificar_colisao(item):
	for slot in slot_destinos:
		var slot_rect = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(item.global_position + item.size / 2):
			slot_ocupado[slot] = item.name
			item.position = slot.position
			_verificar_resposta()
			return

# ----------------------------------------------------------
# 🔹 VERIFICA RESPOSTA
# ----------------------------------------------------------
func _verificar_resposta():
	if slot_ocupado.size() < 3:
		return

	var acertos = 0
	for i in range(slot_destinos.size()):
		var slot = slot_destinos[i]
		if slot_ocupado.has(slot) and slot_ocupado[slot] == corretos[i]:
			acertos += 1

	feedback_label.visible = true

	if acertos == 3:
		feedback_label.text = "Correto! ⚡"
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
		button_continuar.visible = true
		button_restart.visible = false
	else:
		feedback_label.text = "Tente novamente!"
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button_restart.visible = true
		button_continuar.visible = false

# ----------------------------------------------------------
# 🔹 REINICIAR EXERCÍCIO
# ----------------------------------------------------------
func _reiniciar_exercicio():
	slot_ocupado.clear()
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false

	var area_itens = $exercicio_container/area_itens
	var base_pos = area_itens.position
	var desloc = 150

	for i in range(3):
		var item = area_itens.get_node("item_%d" % (i + 1))
		item.position = Vector2(base_pos.x + i * desloc, base_pos.y)


func _finalizar_fase():
	var tempo_total = Global.parar_cronometro()
	
	var caminho = OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP) + "/relatorio_energia.txt"
	var file = FileAccess.open(caminho, FileAccess.WRITE)

	var minutos = floor(tempo_total / 60.0)
	var segundos = fmod(tempo_total, 60.0)
	
	if file:
		file.store_line("RELATÓRIO - FASE 3_3")
		file.store_line("--------------------------")
		file.store_line("Tempo total: %02d minutos e %.2f segundos" % [minutos, segundos]) # Novo formato
		file.store_line("Data e hora: " + Time.get_datetime_string_from_system())
		file.close()
	else:
		push_error("❌ Não foi possível salvar o relatório!")

	var relatorio_cena = load("res://scenes/relatorio.tscn")
	var relatorio_instancia = relatorio_cena.instantiate()
	
	get_tree().root.add_child(relatorio_instancia)
	relatorio_instancia.configurar_relatorio(tempo_total)
	
	queue_free()
