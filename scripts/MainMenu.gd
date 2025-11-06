extends Control

@onready var btn_jogar = $VBoxContainer/Button_Jogar
@onready var btn_creditos = $VBoxContainer/Button_Creditos
@onready var btn_sair = $VBoxContainer/Button_Sair
@onready var click_sound = $AudioStreamPlayer

func _ready():
	btn_jogar.pressed.connect(_on_jogar_pressed)
	btn_creditos.pressed.connect(_on_creditos_pressed)
	btn_sair.pressed.connect(_on_sair_pressed)

func _on_jogar_pressed():
	click_sound.play()
	# Troca de cena para seleção de fases (ou Fase 1 diretamente)
	get_tree().change_scene_to_file("res://scenes/LevelSelect.tscn")

func _on_creditos_pressed():
	click_sound.play()
	var popup = ConfirmationDialog.new()
	popup.title = "Créditos"
	popup.dialog_text = "Desenvolvido por:\nAdrian, Davi, João, Matheus, Pedro e Pedro\n\nEngenharia de Software 01"
	add_child(popup)
	popup.popup_centered()

func _on_sair_pressed():
	click_sound.play()
	get_tree().quit()
