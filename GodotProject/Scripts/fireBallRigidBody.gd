
extends RigidBody

# member variables here, example:
# var a=2
# var b="textvar"

const DEFAULT_LIFE_TIME = 5
var life_timeout = DEFAULT_LIFE_TIME
var life_timer

#*****************************************************************
func _ready():
	# Initialization here
	setEmmitTimer(life_timeout)
	pass

#*****************************************************************
func setEmmitTimer(time):
	life_timeout = time
	life_timer = get_node("emit_timer")
	life_timer.set_wait_time(life_timeout)
	life_timer.start()

#*****************************************************************
func setLifeTimer(time):
	life_timer = get_node("life_timer")
	life_timer.set_wait_time(time)
	life_timer.start()

#*****************************************************************
func turnOffParticlesRecursive(current):
	var children = current.get_children()
	for child in children:
		if(child == null):
			continue
		if(child.has_method("set_emitting")):
			child.set_emitting(false)
		
		turnOffParticlesRecursive(child)

#*****************************************************************
func _on_life_timer_timeout():
	print("Fire is dead")
	queue_free()
	
#*****************************************************************
func _on_emit_timer_timeout():
	turnOffParticlesRecursive(self)
	get_node("AnimationPlayer").play("off")
	setLifeTimer(1)

