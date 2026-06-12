extends Control
class_name HealthBar

func set_bar(health:int):
	for i in range(1,11):
		get_node("HealthSegment" + str(i)).visible = false
	if( health > 0 ):
		for i in range(1,health+1):
			get_node("HealthSegment" + str(i)).visible = true
		
