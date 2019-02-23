extends Spatial

#Setup for 2V2 only for now
#Team 1 need to go -Z
#Team 2 need to go +Z

func _ready():
	var server = NetworkedMultiplayerENet.new()
	server.create_server(8888,2)
	get_tree().set_network_peer(server)
	print("Server created")
	
	server.connect("peer_connected", self, "_peer_connected")
	server.connect("peer_disconnected", self, "_peer_disconnected")

func _peer_connected(id):
	if !GLOBAL.gameState.has("player"):
		GLOBAL.gameState["player"] = {}
		
	GLOBAL.gameState["player"][id] = {}
	GLOBAL.gameState["player"][id]["team"] = 0
	for i in range(10):
		if GLOBAL.existTeam(i):
			print("Team "+str(i)+" exist. We continue")
			pass
		else:
			print("Team "+str(i)+" free. We assign")
			GLOBAL.gameState["player"][id]["team"] = i
			break
	
	#We send the game state to the new player
	var jsonGameState = JSON.print(GLOBAL.gameState)
	rpc_id(id,"server_InitPlayer",GLOBAL.gameState["player"][id]["team"])
	rpc_id(id,"server_SyncGameState",GLOBAL.gameState)
	

func _peer_disconnected(id):
	print("player Disconnected")
	GLOBAL.gameState["player"].erase(id)

func _process(delta):
	if GLOBAL.gameState.has("player"):
		$"../serverUi/playersCount".text = str(GLOBAL.gameState["player"].size()) + " PLAYERS"
		$"../serverUi/playersList".clear()
		for player in GLOBAL.gameState["player"]:
			$"../serverUi/playersList".add_item(str(player))
	if GLOBAL.gameState.has("unit"):
		$"../serverUi/unitsCount".text = str(GLOBAL.gameState["unit"].size()) + " UNITS"
		$"../serverUi/unitsList".clear()
		for object in GLOBAL.gameState["unit"]:
			$"../serverUi/unitsList".add_item(str(object)+" - Team "+str(GLOBAL.gameState["unit"][object]["team"]))
	if GLOBAL.gameState.has("tower"):
		$"../serverUi/towersCount".text = str(GLOBAL.gameState["tower"].size()) + " TOWERS"
		$"../serverUi/towersList".clear()
		for object in GLOBAL.gameState["tower"]:
			$"../serverUi/towersList".add_item(str(object)+" - Team "+str(GLOBAL.gameState["tower"][object]["team"]))
	

#Functions called localy by server
func serverRelay_removeObject(type,objectId):
	rpc("server_removeObject",type,objectId)
	GLOBAL.gameState[type].erase(objectId)
	get_node(type+str(objectId)).queue_free()

func serverRelay_updateObjectPosition(type,objectId,position):
	rpc("server_updateObjectPosition",type,objectId,get_node(type+str(objectId)).transform)

#Functions called remotely by clients
remote func client_AddObject(playerId,objectId,objectType,objectPositionOrigin, rayCastDirangle):
	var object = load("res://"+objectType+".tscn").instance()
	object.playerId = playerId
	object.id = objectId
	object.set_name(objectType+str(objectId))
	object.team = GLOBAL.gameState["player"][playerId]["team"]
	object.transform.origin = objectPositionOrigin
	object.rotation.y = rayCastDirangle
	add_child(object)
	
	rpc("server_AddObject",object.playerId,object.id,objectType,object.transform,object.team)
	
	if !GLOBAL.gameState.has(objectType):
		GLOBAL.gameState[objectType] = {}
		
	GLOBAL.gameState[objectType][objectId] = {}
	GLOBAL.gameState[objectType][objectId]["team"] = object.team
	GLOBAL.gameState[objectType][objectId]["position"] = object.transform	

remote func client_updateObjectPosition(objectType,objectId,position):
	#We need to check if the node exist before updating because if some cases, there 1 frame delay between client and server at deletion
	if has_node(objectType+str(objectId)) && GLOBAL.gameState[objectType].has(objectId):
		GLOBAL.gameState[objectType][objectId]["position"] = position
		get_node(objectType+str(objectId)).transform = position
	else:
		print("Updating of non existing Object "+str(objectId)+". Probably frame delay issue")

remote func client_UnitEnterTerritory(unitId,area):
	print("Unit "+str(unitId)+" entered "+str(area))
	#Maybe check some condition before accepting client request
	serverRelay_removeObject("unit",unitId)
	#On change les points ici