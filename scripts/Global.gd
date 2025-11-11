extends Node

#Marca o tempo global do jogador
var tempo_inicio: float = 0.0
var tempo_final: float = 0.0

#Começa a contar o tempo
func iniciar_cronometro():
	tempo_inicio = Time.get_ticks_msec() / 1000.0

#Para o cronômetro e retorna o tempo total em segundos
func parar_cronometro() -> float:
	tempo_final = Time.get_ticks_msec() / 1000.0
	return tempo_final - tempo_inicio
