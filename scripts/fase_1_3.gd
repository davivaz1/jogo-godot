extends Control

@onready var explicacao_container = $explicacao_container
@onready var exercicio_container = $exercicio_container
@onready var label_vitoria = $label_vitoria
@onready var audio = $AudioStreamPlayer2D
@onready var feedback_label = $exercicio_container/feedback_label
@onready var button_restart = $exercicio_container/button_restart
@onready var button_continuar = $exercicio_container/button_continuar

var primeira_selecao = null
var pares_corretos = {
	"fonte_sol": "energia_solar",
	"fonte_agua": "energia_hidreletrica",
	"fonte_vento": "energia_eolica"
}
var pares_feitos = {}

func _ready():
	explicacao_container.visible = true
	exercicio_container.visible = false
	label_vitoria.visible = false
	button_restart.visible = false
	button_continuar.visible = false
	feedback_label.visible = false

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

	# Conecta cliques nas fontes e nas energias
	for nome in pares_corretos.keys():
		var fonte = $exercicio_container/area_fontes.get_node(nome)
		fonte.pressed.connect(func(): _on_item_clicado(nome))

	for nome in pares_corretos.values():
		var energia = $exercicio_container/area_energias.get_node(nome)
		energia.pressed.connect(func(): _on_item_clicado(nome))

func _play_click():
	if audio and audio.stream:
		audio.play()

func _iniciar_exercicio():
	explicacao_container.visible = false
	exercicio_container.visible = true
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false
	pares_feitos.clear()
	primeira_selecao = null

func _reiniciar_exercicio():
	feedback_label.visible = false
	button_restart.visible = false
	button_continuar.visible = false
	pares_feitos.clear()
	primeira_selecao = null

func _on_item_clicado(nome_item: String):
	if primeira_selecao == null:
		primeira_selecao = nome_item
		feedback_label.text = "Selecione o par correspondente..."
		feedback_label.add_theme_color_override("font_color", Color(1, 1, 1))
		feedback_label.visible = true
	else:
		_verificar_par(primeira_selecao, nome_item)
		primeira_selecao = null

func _verificar_par(item1: String, item2: String):
	var correto = false

	# Verifica nas duas direções (fonte → energia ou energia → fonte)
	if pares_corretos.has(item1) and pares_corretos[item1] == item2:
		correto = true
	elif pares_corretos.has(item2) and pares_corretos[item2] == item1:
		correto = true

	if correto:
		pares_feitos[item1] = true
		pares_feitos[item2] = true
		feedback_label.text = "Correto! 🌞"
		feedback_label.add_theme_color_override("font_color", Color(0, 1, 0))
		_play_click()

		# Desativa os botões já usados
		if $exercicio_container.has_node("area_fontes/" + item1):
			$exercicio_container/area_fontes.get_node(item1).disabled = true
		if $exercicio_container.has_node("area_energias/" + item2):
			$exercicio_container/area_energias.get_node(item2).disabled = true

		if pares_feitos.size() == pares_corretos.size() * 2:
			_feedback_vitoria()
	else:
		feedback_label.text = "Tente novamente!"
		feedback_label.add_theme_color_override("font_color", Color(1, 0, 0))
		button_restart.visible = true

func _feedback_vitoria():
	feedback_label.text = "Você acertou todos! 🌟"
	button_continuar.visible = true
	button_restart.visible = false

func _finalizar_fase():
	label_vitoria.visible = true
	label_vitoria.text = "VOCÊ CONCLUIU O NÍVEL 1!"
	await get_tree().create_timer(1.5).timeout
	_salvar_progresso_e_voltar()

func _salvar_progresso_e_voltar():
	var cfg = ConfigFile.new()
	var save_path = "user://save_data.cfg"
	var err = cfg.load(save_path)
	if err != OK:
		cfg.set_value("level1", "completed", true)
	else:
		cfg.set_value("level1", "completed", true)
	cfg.save(save_path)

	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://scenes/nivel_1_selecionafase.tscn")
