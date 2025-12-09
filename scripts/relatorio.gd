extends Control

@onready var tempo_label = $CenterContainer/TextureRect/tempo_label
@onready var voltar_menu_button = $TextureButton

func _ready():
	voltar_menu_button.pressed.connect(_on_voltar_menu_button_pressed)


func configurar_relatorio(tempo_total_segundos: float):

	var minutos = floor(tempo_total_segundos / 60.0)
	var segundos = fmod(tempo_total_segundos, 60.0)
	
	tempo_label.text = "Tempo total: %02d minutos e %.2f segundos" % [minutos, segundos]


func _on_voltar_menu_button_pressed():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
