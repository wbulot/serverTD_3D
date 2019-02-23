extends RigidBody

remote func hit(unitId, bodyPart):
	#We need to check if the node exist before updating because if some cases, there 1 frame delay between client and server at deletion
	if has_node("../unit"+str(unitId)):
		if bodyPart == "other":
			get_node("../unit"+str(unitId)).hit(35)
			print("hit 35 "+str(unitId))
	else:
		print("Updating of non existing Unit "+str(unitId)+". Probably frame delay issue")

remote func removeBullet():
	queue_free()