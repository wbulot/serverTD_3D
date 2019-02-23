extends KinematicBody

var playerId
var id

var life = 100
var team

var isGodMode = 0

var deadTimer

#func _ready():
#	rpc("remoteInitUnit",team)
	
func _process(delta):
#	rpc("updatePosition",playerId, global_transform.origin)
	$"..".serverRelay_updateObjectPosition("tower",id,transform)
	checkDeadTime(delta)
	checkBadPosition()

func checkBadPosition():
	if transform.origin.y < -50:
		if life > 0:
			hit(100)

func hit(damage):
	life -= damage
	rpc("updateLife",life)
	if life <= 0:
		die()

func die():
	if deadTimer == null:
		deadTimer = 0

func checkDeadTime(delta):
	if deadTimer != null:
		deadTimer += delta
		if deadTimer > 5:
			$"..".serverRelay_removeObject("tower",id)
	
remote func registerBullet(cPlayerId,objectId):
	var bullet = preload("res://bullet.tscn").instance()
	bullet.set_name("bullet"+str(objectId))
	get_parent().add_child(bullet)