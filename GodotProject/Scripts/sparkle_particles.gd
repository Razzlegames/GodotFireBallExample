
extends Particles

# member variables here, example:
# var a=2
# var b="textvar"

#*****************************************************************
func set_emitting(val):
	if(val):
		print("enabling lighting!")
		
	#get_node("light").set_enabled(val)
	get_node("big_particles").set_emitting(val)
	.set_emitting(val)
	
#*****************************************************************
func _ready():
	# Initialization here
	get_node("light").set_enabled(false)
	set_emitting(false)
	print("AABB: "+ str(get_visibility_aabb()))
	pass


