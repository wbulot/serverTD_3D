extends Node

var gameState = {}

func existTeam(team):
	var exist = 0
	for id in gameState["player"]:
		print(gameState["player"][id])
		if gameState["player"][id]["team"] == team:
			exist = 1
	if exist == 1:
		return true
	else:
		return false